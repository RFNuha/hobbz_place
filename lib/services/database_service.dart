import 'package:hive_flutter/hive_flutter.dart';
import 'package:hobbz_place/models/models.dart';
import 'package:hobbz_place/enums/enums.dart';

const String mediaBoxName = 'media_items';
const String settingsBoxName = 'settings';
const String tombstoneBoxName = 'deleted_items';

class DatabaseService {

  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  late Box _mediaBox;
  late Box _settingsBox;
  late Box _tombstoneBox;

  Future<void> init() async {
    await Hive.initFlutter();

    _mediaBox = await Hive.openBox(mediaBoxName);  
    _settingsBox = await Hive.openBox(settingsBoxName); 
    _tombstoneBox = await Hive.openBox(tombstoneBoxName);
  }

  // Settings

  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> putSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  // CRUD

  // Create
  Future<void> addItem(MediaItem item) async {
    await _mediaBox.put(item.id, item.toMap());
  }

  MediaItem? getItem(String id) {
    final raw = _mediaBox.get(id);

    if (raw == null) return null;

    return MediaItem.fromMap(Map<String, dynamic>.from(raw));
  }

  // Read All
  List<MediaItem> getAllItems() {
    return _mediaBox.values.map((raw) {
      return MediaItem.fromMap(Map<String, dynamic>.from(raw));
    }).toList();
  }

  // Update
  Future<void> updateItem(MediaItem item) async {
    item.touch();  // Update the lastUpdated timestamp
    await _mediaBox.put(item.id, item.toMap());
  }

  // Delete
  Future<int> deleteItem(String id) async {
    await _mediaBox.delete(id);
    final ms = DateTime.now().millisecondsSinceEpoch;
    await _tombstoneBox.put(id, ms);
    return ms;
  }



  int? tombstoneMs(String id) => _tombstoneBox.get(id) as int?;

  Map<String, int> get tombstones => {
        for (final k in _tombstoneBox.keys) k as String: _tombstoneBox.get(k) as int,
      };

  // Save
  Future<void> saveFromSync(MediaItem item) async {
    await _mediaBox.put(item.id, item.toMap());
    await _tombstoneBox.delete(item.id);
  }

  Future<void> removeFromSync(String id) async {
    await _mediaBox.delete(id);
  }



  // Query Helpers

  List<MediaItem> getItemsByStatus(MediaStatus status) {
    return getAllItems().where((item) => item.status == status).toList();
  }

  List<MediaItem> getItemsByCategory(MediaCategory category) {
    return getAllItems().where((item) => item.category == category).toList();
  }

  List<MediaItem> getItemsByCollectionGroup(String group) {
    return getAllItems()
        .where((item) => item.category.collectionGroup == group)
        .toList();
  }

  int get count => _mediaBox.length;
  bool get isEmpty => _mediaBox.isEmpty;
}