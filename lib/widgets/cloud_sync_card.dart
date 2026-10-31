import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hobbz_place/services/cloud_sync_service.dart';

class CloudSyncCard extends StatefulWidget {
  const CloudSyncCard({super.key});

  @override
  State<CloudSyncCard> createState() => _CloudSyncCardState();
}

class _CloudSyncCardState extends State<CloudSyncCard> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      _error = '${e.code}: ${e.message}';
      debugPrint('FIREBASE AUTH ERROR → code: ${e.code}, message: ${e.message}');
    } catch (e) {
      _error = e.toString();
      debugPrint('OTHER ERROR → $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CloudSyncService.instance,
      builder: (context, _) {
        final sync = CloudSyncService.instance;

        if (!sync.available) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_off),
              title: const Text('Cloud sync unavailable'),
              subtitle: Text(sync.status),
            ),
          );
        }

        if (sync.isSignedIn) {
          final last = sync.lastSynced;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_done),
                    title: Text(sync.userEmail ?? 'Signed in'),
                    subtitle: Text(
                      last == null
                          ? sync.status
                          : '${sync.status} • last ${TimeOfDay.fromDateTime(last).format(context)}',
                    ),
                  ),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _busy ? null : () => _run(sync.syncNow),
                        icon: const Icon(Icons.sync),
                        label: const Text('Sync now'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _busy ? null : () => _run(sync.signOut),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                  if (_error != null) _errorText(context),
                ],
              ),
            ),
          );
        }

        // Signed out
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sign in to sync across Android, Windows and web.'),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password (min 6 characters)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() =>
                              sync.signIn(_emailCtrl.text, _passCtrl.text)),
                      child: const Text('Sign in'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() =>
                              sync.register(_emailCtrl.text, _passCtrl.text)),
                      child: const Text('Create account'),
                    ),
                    if (_busy) ...[
                      const SizedBox(width: 12),
                      const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ],
                ),
                if (_error != null) _errorText(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _errorText(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
}