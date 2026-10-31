import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA41SV91BCZhnHVorAgDRhr6f_azvxMJJI',
    appId: '1:588666892429:web:90af85f18677b151d1b2c4',
    messagingSenderId: '588666892429',
    projectId: 'hobbz-place-fc630',
    authDomain: 'hobbz-place-fc630.firebaseapp.com',
    storageBucket: 'hobbz-place-fc630.firebasestorage.app',
    measurementId: 'G-NTX8B2GWSP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDAE1z1qLCxtuSW51Sh1lGYQhiTcuFMh2U',
    appId: '1:588666892429:android:9f8e854258c1d564d1b2c4',
    messagingSenderId: '588666892429',
    projectId: 'hobbz-place-fc630',
    storageBucket: 'hobbz-place-fc630.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA41SV91BCZhnHVorAgDRhr6f_azvxMJJI',
    appId: '1:588666892429:web:5b0d627fc8c5c4d7d1b2c4',
    messagingSenderId: '588666892429',
    projectId: 'hobbz-place-fc630',
    authDomain: 'hobbz-place-fc630.firebaseapp.com',
    storageBucket: 'hobbz-place-fc630.firebasestorage.app',
    measurementId: 'G-1MSMKGFZPW',
  );
}
