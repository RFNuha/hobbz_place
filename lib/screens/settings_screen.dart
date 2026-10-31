import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hobbz_place/providers/media_provider.dart';
import 'package:hobbz_place/services/backup_service.dart';
import 'package:hobbz_place/widgets/cloud_sync_card.dart';
import 'package:hobbz_place/services/tmdb_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<MediaProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Settings',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Section 1 - APPEARANCE
              _buildSectionTitle(theme, 'Appearance', Icons.palette),
              const SizedBox(height: 8),

              Card(
                child: SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: Text(
                    provider.themeMode == ThemeMode.dark
                        ? 'Currently using dark theme'
                        : 'Currently using light theme',
                    style: theme.textTheme.bodySmall,
                  ),
                  value: provider.themeMode == ThemeMode.dark,
                  onChanged: (_) => provider.toggleTheme(),
                  secondary: Icon(
                    provider.themeMode == ThemeMode.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _buildSectionTitle(theme, 'Cloud Sync', Icons.cloud),
              const SizedBox(height: 8),
              const CloudSyncCard(),
              const SizedBox(height: 24),

              // Section 2 - Data management
              _buildSectionTitle(theme, 'Data Management', Icons.storage),
              const SizedBox(height: 8),

              // Export Button
              Card(
                child: ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('Export Library'),
                  subtitle: const Text('Save all items as a JSON backup file'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportData(context, provider),
                ),
              ),

              const SizedBox(height: 4),

              // Import Button
              Card(
                child: ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Import Library'),
                  subtitle: const Text('Load items from a JSON backup file'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showImportDialog(context, provider),
                ),
              ),

              const SizedBox(height: 24),


              // Section 3 - API SETTINGS
              _buildSectionTitle(theme, 'API Settings', Icons.api),
              const SizedBox(height: 8),

              // TMDB API Key
              Card(
                child: ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('TMDB API Key'),
                  subtitle: Text(
                    TMDBService.hasApiKey
                        ? 'Key is set ✓'
                        : 'Not set — needed for movie/TV search',
                    style: TextStyle(
                      color: TMDBService.hasApiKey ? Colors.green : Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showApiKeyDialog(context),
                ),
              ),

              const SizedBox(height: 4),

              // Sync All Button
              Card(
                child: ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Sync All Items'),
                  subtitle: const Text('Update chapter/episode counts from APIs'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _syncAllItems(context, provider),
                ),
              ),

              const SizedBox(height: 24),

              // SECTION 4 - LIBRARY INFO
              _buildSectionTitle(theme, 'Library Info', Icons.info_outline),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        theme,
                        'Total Items',
                        '${provider.items.length}',
                        Icons.library_books,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        theme,
                        'Reading Items',
                        '${provider.items.where((i) => i.isReading).length}',
                        Icons.menu_book,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        theme,
                        'Watching Items',
                        '${provider.items.where((i) => i.isWatching).length}',
                        Icons.tv,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        theme,
                        'Rated Items',
                        '${provider.items.where((i) => i.rating != null).length}',
                        Icons.star,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Section 4 - ABOUT
              _buildSectionTitle(theme, 'About', Icons.favorite),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // App icon placeholder
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.collections_bookmark,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Hobbz Place',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version 1.0.0',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'A personal media tracker for manhwa, manga, books, movies, shows & more.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Made with ♥ by Nuha',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // Section Title
  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Info row - icon + label + value
  Widget _buildInfoRow(ThemeData theme, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // TMDI API Key — lets user enter their TMDB API key
  void _showApiKeyDialog(BuildContext context) {
    final keyController = TextEditingController(
      text: TMDBService.hasApiKey ? '••••••••' : '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('TMDB API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get a free API key from:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            SelectableText(
              'https://www.themoviedb.org/settings/api',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                hintText: 'Paste your API key here',
                prefixIcon: Icon(Icons.key),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
            final key = keyController.text.trim();
            if (key.isNotEmpty && key != '••••••••') {
              await TMDBService.setApiKey(key);
            }
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
            (context as Element).markNeedsBuild();
          },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Syncs all items with external APIs
  Future<void> _syncAllItems(BuildContext context, MediaProvider provider) async {
    final syncableCount = provider.items
        .where((i) => i.apiSource != null && i.apiSource!.isNotEmpty)
        .length;

    if (syncableCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items to sync — add items from API search first!'),
        ),
      );
      return;
    }

    // Show loading dialog.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text('Syncing $syncableCount items...'),
          ],
        ),
      ),
    );

    // Perform the sync.
    final results = await provider.syncAllItems();

    // Close loading.
    if (context.mounted) Navigator.pop(context);

    // Count results.
    final updatedCount = results.where((r) => r.updated).length;
    final failedCount = results.where((r) => !r.success).length;

    // Show result dialog.
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Icon(
                updatedCount > 0 ? Icons.check_circle : Icons.info,
                color: updatedCount > 0 ? Colors.green : Colors.blue,
              ),
              const SizedBox(width: 8),
              const Text('Sync Complete'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✓ ${results.length - failedCount} synced successfully'),
              if (updatedCount > 0) Text('📥 $updatedCount items updated'),
              if (failedCount > 0)
                Text(
                  '✗ $failedCount failed',
                  style: const TextStyle(color: Colors.red),
                ),
              // Show details of updates.
              if (updatedCount > 0) ...[
                const SizedBox(height: 12),
                const Text(
                  'Updates:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                ...results
                    .where((r) => r.updated)
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${r.title}: ${r.message}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        )),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }


  // Export
  Future<void> _exportData(BuildContext context, MediaProvider provider) async {
    try {
      // Show a loading indicator.
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Do the export.
      final filePath = await BackupService.exportToJson(provider.items);

      // Close the loading indicator.
      if (context.mounted) Navigator.pop(context);

      // Show success dialog with the file path.
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Export Successful'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${provider.items.length} items exported!'),
                const SizedBox(height: 12),
                Text(
                  'Saved to:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  filePath,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Something went wrong — close loading and show error.
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Import Dialog — asks the user for a file path to import

  void _showImportDialog(BuildContext context, MediaProvider provider) {
    final pathController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import Library'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste the full path to your backup JSON file:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pathController,
              decoration: const InputDecoration(
                hintText: 'e.g., C:\\Users\\User\\Documents\\hobbz_backup.json',
                prefixIcon: Icon(Icons.folder),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),
            Text(
              '⚠ This will ADD the imported items to your existing library. '
              'It will not replace or delete your current items.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _importData(context, provider, pathController.text.trim());
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  // Import - Add items to the lib
  Future<void> _importData(
    BuildContext context,
    MediaProvider provider,
    String filePath,
  ) async {
    if (filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a file path')),
      );
      return;
    }

    try {
      // Show loading.
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Import the items.
      final importedItems = await BackupService.importFromJson(filePath);

      // Add each imported item to the library.
      int addedCount = 0;
      for (final item in importedItems) {
        final wasAdded = await provider.addItem(item);
        if (wasAdded) addedCount++;
      }

      // Close loading.
      if (context.mounted) Navigator.pop(context);

      // Show success.
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Import Successful'),
              ],
            ),
            content: Text('$addedCount items imported successfully!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}