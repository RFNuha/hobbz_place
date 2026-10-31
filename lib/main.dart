import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hobbz_place/services/database_service.dart';
import 'package:hobbz_place/services/tmdb_service.dart';
import 'package:hobbz_place/providers/media_provider.dart';
import 'package:hobbz_place/theme/app_theme.dart';
import 'package:hobbz_place/screens/home_screen.dart';
import 'package:hobbz_place/services/cloud_sync_service.dart';  


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.init();
  TMDBService.loadSavedApiKey();

  CloudSyncService.instance.init(); 

  runApp(
    ChangeNotifierProvider(
      create: (_) {
        final provider = MediaProvider()..loadItems();
        CloudSyncService.instance.onRemoteChanged = provider.loadItems;
        return provider;
      },
      child: const HobbzPlaceApp(),
    ),
  );
}

class HobbzPlaceApp extends StatelessWidget {
  const HobbzPlaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, provider, child) {

        return MaterialApp(
          title: 'Hobbz Place',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: provider.themeMode,

          home: const HomeScreen(),
        );
      },
    );
  }
}