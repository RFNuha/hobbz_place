import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hobbz_place/firebase_options.dart';
import 'package:hobbz_place/models/models.dart';
import 'package:hobbz_place/services/database_service.dart';

class CloudSyncService extends ChangeNotifier {
  CloudSyncService._();
  static final CloudSyncService instance = CloudSyncService._();

  static const int _overlapMs = 5 * 60 * 1000;
  static const String _lastSyncKey = 'lastSyncMs';
  static const String _lastSyncUidKey = 'lastSyncUid';

  bool _available = false; 
  String _status = 'Not signed in';
  DateTime? _lastSynced;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _itemsSub;
  StreamSubscription<User?>? _authSub;
  VoidCallback? onRemoteChanged;
  bool get available => _available;
  bool get isSignedIn =>
      _available && FirebaseAuth.instance.currentUser != null;
  String? get userEmail =>
      _available ? FirebaseAuth.instance.currentUser?.email : null;
  String get status => _status;
  DateTime? get lastSynced => _lastSynced;

  String? get _uid =>
      _available ? FirebaseAuth.instance.currentUser?.uid : null;

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('items');

  void _setStatus(String s) {
    _status = s;
    notifyListeners();
  }


  @override
  void dispose() {
    _authSub?.cancel();   
    _itemsSub?.cancel();  
    super.dispose();      
  }

  Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _available = true;

      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user == null) {
          _itemsSub?.cancel();
          _itemsSub = null;
          _setStatus('Not signed in');
        } else {
          _startListening();
        }
      });
    } catch (e) {
      _available = false;
      _setStatus('Cloud sync unavailable on this device: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> register(String email, String password) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> syncNow() => _startListening(fullResync: true);

  Map<String, dynamic> _toRemote(MediaItem item) => {
        ...item.toMap(),
        'deleted': false,
        'lastUpdatedMs': item.lastUpdated.millisecondsSinceEpoch,
      };

  Future<void> pushItem(MediaItem item) async {
    final uid = _uid;
    if (uid == null) return; 
    try {
      await _items(uid).doc(item.id).set(_toRemote(item));
    } catch (e) {
      debugPrint('pushItem failed: $e');
    }
  }

  Future<void> pushDelete(String id, int deletedAtMs) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _items(uid).doc(id).set({
        'id': id,
        'deleted': true,
        'lastUpdatedMs': deletedAtMs,
      });
    } catch (e) {
      debugPrint('pushDelete failed: $e');
    }
  }

  Future<void> _startListening({bool fullResync = false}) async {
    await _itemsSub?.cancel();
    _itemsSub = null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = DatabaseService.instance;
    final sameUser = db.getSetting(_lastSyncUidKey) == user.uid;
    final saved = (fullResync || !sameUser)
        ? 0
        : (db.getSetting(_lastSyncKey, defaultValue: 0) as int);
    final from = saved == 0 ? 0 : saved - _overlapMs;

    final seen = <String, int>{};
    var handshakeDone = false;

    _setStatus('Syncing…');

    _itemsSub = _items(user.uid)
        .where('lastUpdatedMs', isGreaterThan: from)
        .snapshots()
        .listen(
      (snap) async {
        final changed = await _applyRemote(snap, seen);

        if (!snap.metadata.isFromCache && !handshakeDone) {
          handshakeDone = true;
          try {
            await _pushPending(user.uid, from, seen);
            await db.putSetting(
                _lastSyncKey, DateTime.now().millisecondsSinceEpoch);
            await db.putSetting(_lastSyncUidKey, user.uid);
            _lastSynced = DateTime.now();
            _setStatus('Synced');
          } catch (e) {
            _setStatus('Upload problem: $e');
          }
        } else if (handshakeDone) {
          _lastSynced = DateTime.now();
          _setStatus('Synced');
        }

        if (changed) onRemoteChanged?.call();
      },
      onError: (e) => _setStatus('Sync error: $e'),
    );
  }

  Future<bool> _applyRemote(
    QuerySnapshot<Map<String, dynamic>> snap,
    Map<String, int> seen,
  ) async {
    final db = DatabaseService.instance;
    var changed = false;

    for (final change in snap.docChanges) {
      if (change.type == DocumentChangeType.removed) continue;
      final data = change.doc.data();
      if (data == null) continue;

      try {
        final id = change.doc.id;
        final remoteMs = (data['lastUpdatedMs'] as num).toInt();
        seen[id] = remoteMs;

        final local = db.getItem(id);
        final localMs = local?.lastUpdated.millisecondsSinceEpoch ?? 0;
        final tombMs = db.tombstoneMs(id) ?? 0;

        if (data['deleted'] == true) {
          if (local != null && localMs <= remoteMs) {
            await db.removeFromSync(id);
            changed = true;
          }
        } else if (remoteMs > localMs && remoteMs > tombMs) {
          final item = MediaItem.fromMap(data);
          item.lastUpdated = DateTime.fromMillisecondsSinceEpoch(remoteMs);
          await db.saveFromSync(item);
          changed = true;
        }
      } catch (e) {
        debugPrint('Skipping bad cloud doc ${change.doc.id}: $e');
      }
    }
    return changed;
  }

  Future<void> _pushPending(
      String uid, int from, Map<String, int> seen) async {
    final db = DatabaseService.instance;
    final writes = <MapEntry<String, Map<String, dynamic>>>[];

    for (final item in db.getAllItems()) {
      final ms = item.lastUpdated.millisecondsSinceEpoch;
      if (ms > from && ms > (seen[item.id] ?? 0)) {
        writes.add(MapEntry(item.id, _toRemote(item)));
      }
    }

    db.tombstones.forEach((id, ms) {
      if (ms > from && ms > (seen[id] ?? 0)) {
        writes.add(MapEntry(id, {
          'id': id,
          'deleted': true,
          'lastUpdatedMs': ms,
        }));
      }
    });

    final col = _items(uid);
    for (var i = 0; i < writes.length; i += 400) {
      final batch = FirebaseFirestore.instance.batch();
      for (final w in writes.skip(i).take(400)) {
        batch.set(col.doc(w.key), w.value);
      }
      await batch.commit();
    }
  }
}