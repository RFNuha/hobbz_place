import 'package:flutter/material.dart';
import 'package:hobbz_place/screens/library_screen.dart';
import 'package:hobbz_place/screens/stats_screen.dart';
import 'package:hobbz_place/screens/settings_screen.dart';
import 'package:hobbz_place/screens/add_edit_screen.dart';
import 'package:hobbz_place/screens/api_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // The three tab screens.
  final List<Widget> _screens = const [
    LibraryScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        tooltip: 'Add media',
        child: const Icon(Icons.add),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  // Show Add options
  void _showAddOptions(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Add to Library',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Option 1 - Manual Add
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.edit, color: theme.colorScheme.primary),
                  ),
                  title: const Text('Add Manually'),
                  subtitle: const Text('Enter details yourself'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddEditScreen(),
                      ),
                    );
                  },
                ),

                const Divider(indent: 16, endIndent: 16),

                // Option 2 - Search APIs
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    child: Icon(Icons.travel_explore, color: theme.colorScheme.secondary),
                  ),
                  title: const Text('Search Online'),
                  subtitle: const Text('Find from AniList, TMDB, or Google Books'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ApiSearchScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}