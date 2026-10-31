// widget_test.dart
// --------------------------------------------------------------------------
// Automated tests — run them with:   flutter test
//
// These check that a MediaItem survives being turned into a Map and back.
// That's exactly what happens every time Hive saves/loads an item (and when
// you export/import a backup), so if this breaks, your data would break too.
// --------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
// ↑ Gives us test(), expect(), group() and matchers like equals().
import 'package:hobbz_place/enums/enums.dart';
import 'package:hobbz_place/models/models.dart';

void main() {
  // group() just bundles related tests under one name in the output.
  group('MediaItem', () {
    test('toMap → fromMap keeps every important field', () {
      // 1. ARRANGE — build an item with lots of fields filled in.
      final original = MediaItem(
        title: 'Solo Leveling',
        altTitles: ['Na Honjaman Level Up'],
        category: MediaCategory.manhwa,
        genres: [Genre.action, Genre.fantasy],
        author: 'Chugong',
        status: MediaStatus.completed,
        currentProgress: 179,
        totalProgress: 179,
        rating: 4.5,
        apiSource: 'anilist',
        externalApiId: '105398',
      );

      // 2. ACT — convert to a Map (what Hive stores) and back again.
      final restored = MediaItem.fromMap(original.toMap());

      // 3. ASSERT — check everything came back the same.
      expect(restored.id, original.id);
      expect(restored.title, 'Solo Leveling');
      expect(restored.altTitles, ['Na Honjaman Level Up']);
      expect(restored.category, MediaCategory.manhwa);
      expect(restored.genres, [Genre.action, Genre.fantasy]);
      expect(restored.author, 'Chugong');
      expect(restored.status, MediaStatus.completed);
      expect(restored.currentProgress, 179);
      expect(restored.totalProgress, 179);
      expect(restored.rating, 4.5);
      expect(restored.apiSource, 'anilist');
      expect(restored.externalApiId, '105398');
    });

    test('drama categories land in the Shows & Drama collection', () {
      expect(MediaCategory.kdrama.collectionGroup, 'Shows & Drama');
      expect(MediaCategory.cdrama.collectionGroup, 'Shows & Drama');
      expect(MediaCategory.manhwa.collectionGroup, 'Graphical');
      expect(MediaCategory.lightNovel.collectionGroup, 'Books');
    });
  });
}
