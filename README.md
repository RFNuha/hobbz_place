# Hobbz Place

A personal tracker for everything you read and watch, all in one app.
Think Goodreads, but for manhwa, manga, manhua, comics, books, light novels,
web novels, anime, movies, TV shows and dramas.

Built with Flutter. Works on Android and Windows.

## What it can do

- Save entries with a cover, author, genres, alternative titles, notes and favourite quotes
- Track your status: Planning, Ongoing, Completed, On Hold, Dropped
- Track your progress (chapter or episode) and give a rating out of 5
- Search online and add in one tap:
  - **AniList** for manga, manhwa, manhua, anime and novels
  - **TMDB** for movies, TV shows and dramas
  - **Google Books** (with Open Library as a backup) for books
- Sync chapter and episode counts with one button
- Stops you from adding the same thing twice
- Four collections: Graphical, Anime, Books, Movies & Shows
- Stats screen with totals by status, category and genre
- Dark and light theme
- Backup and restore your library as a JSON file
- Sign in and sync between your phone and laptop (Firebase)

## Tech used

| Part | What it is used for |
| --- | --- |
| Flutter / Dart | The app itself |
| Provider | Sharing data between screens |
| Hive | Saving your library on the device |
| Firebase Auth + Cloud Firestore | Login and syncing between devices |

## How to run it

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (Dart SDK 3.11 or newer).
2. Download the project:

   ```
   git clone https://github.com/RFNuha/hobbz_place.git
   cd hobbz_place
   flutter pub get
   ```

3. Run it:

   ```
   flutter run
   ```

   Pick a device when asked (Android phone, emulator or Windows).

## TMDB key (for movies and shows)

The app does not have a TMDB key inside it. Each person adds their own:

1. Make a free account at [themoviedb.org](https://www.themoviedb.org/) and request an API key
   (Settings, then API).
2. Open the app, go to **Settings**, and paste the key in.

AniList and Open Library need no key.

## Build a release version

```
flutter build apk --release
flutter build windows --release
```

## Notes

- Your library is stored on your device first. If you sign in, it is also synced to the cloud.
- Use **Settings, then Export** now and then to keep a backup file.

## Credits

- Anime, manga and novel data from [AniList](https://anilist.co)
- Book data from [Google Books](https://books.google.com) and [Open Library](https://openlibrary.org)
- This product uses the TMDB API but is not endorsed or certified by [TMDB](https://www.themoviedb.org)

## Status

Personal project, still being improved.