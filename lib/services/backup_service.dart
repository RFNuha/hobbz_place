import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:hobbz_place/models/models.dart';
import 'package:intl/intl.dart';

class BackupService {

  static Future<String> exportToJson(List<MediaItem> items) async {
    final List<Map<String, dynamic>> itemMaps = items.map(
      (item) => item.toMap(),
    ).toList();

    final backupData = {
      'app': 'Hobbz Place',
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'itemCount': items.length,
      'items': itemMaps,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
    final directory = await getApplicationDocumentsDirectory();
    final dateStr = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final filePath = '${directory.path}/hobbz_backup_$dateStr.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    return filePath;
  }

  static Future<List<MediaItem>> importFromJson(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final jsonString = await file.readAsString();
    final dynamic decoded = jsonDecode(jsonString);
    List<dynamic> itemsList;

    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('items') && decoded['items'] is List) {
        itemsList = decoded['items'] as List<dynamic>;
      } else {
        throw const FormatException(
          'Invalid backup format: expected an "items" array in the JSON object.',
        );
      }
    } else if (decoded is List) {
      itemsList = decoded;
    } else {
      throw const FormatException(
        'Invalid JSON format: expected an object or array.',
      );
    }

    final items = itemsList
        .whereType<Map<String, dynamic>>()
        .map((map) => MediaItem.fromMap(map))
        .toList();

    return items;
  }

  static Future<String> getBackupDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<List<FileSystemEntity>> listBackups() async {
    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory(directory.path);

    if (!await dir.exists()) return [];

    final files = dir.listSync()
        .where((entity) =>
            entity is File &&
            entity.path.contains('hobbz_backup') &&
            entity.path.endsWith('.json'))
        .toList();

    files.sort((a, b) {
      final aTime = (a as File).lastModifiedSync();
      final bTime = (b as File).lastModifiedSync();
      return bTime.compareTo(aTime);
    });

    return files;
  }
}