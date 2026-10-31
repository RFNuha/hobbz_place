import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hobbz_place/providers/media_provider.dart';
import 'package:hobbz_place/widgets/collection_card.dart';
import 'package:hobbz_place/screens/collection_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const SizedBox(height: 8),
              Text(
                'My Library',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${provider.totalCount} items total',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // 2x2 Grid of Collection Cards
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 16.0;
                    const minCardHeight = 250.0;

                    final fitHeight = (constraints.maxHeight - spacing) / 2;

                    final cardHeight =
                        fitHeight < minCardHeight ? minCardHeight : fitHeight;

                    return GridView(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                        mainAxisExtent: cardHeight,
                      ),
                      children: [
                        // Card 1 - Graphical
                        CollectionCard(
                          title: 'Graphical',
                          icon: Icons.auto_stories, // A book icon
                          items: provider.getItemsByCollectionGroup('Graphical'),
                          subtitle: 'Manga · Manhwa · Manhua · Comics',
                          onTap: () => _openCollection(context, 'Graphical'),
                        ),

                        // Card 2 - Anime
                        CollectionCard(
                          title: 'Anime',
                          icon: Icons.animation,
                          items: provider.getItemsByCollectionGroup('Anime'),
                          subtitle: 'Anime series · Anime movies',
                          onTap: () => _openCollection(context, 'Anime'),
                        ),

                        // Card 3 - Books
                        CollectionCard(
                          title: 'Books',
                          icon: Icons.menu_book_rounded,
                          items: provider.getItemsByCollectionGroup('Books'),
                          subtitle: 'Books · Light Novels · Web Novels',
                          onTap: () => _openCollection(context, 'Books'),
                        ),

                        // Card 4 - Movies and Show
                        CollectionCard(
                          title: 'Movies & Shows',
                          icon: Icons.movie_outlined,
                          items: provider.getItemsByCollectionGroup('Movies & Shows'),
                          subtitle: 'Movies · TV Shows · Dramas',
                          onTap: () => _openCollection(context, 'Movies & Shows'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Navigate to the Collection screen for a specific group.
  void _openCollection(BuildContext context, String group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionScreen(collectionGroup: group),
      ),
    );
  }
}