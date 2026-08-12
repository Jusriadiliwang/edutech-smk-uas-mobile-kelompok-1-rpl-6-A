// Firebase configuration — Production (edutech-smk-app-71383)
// Generated from Firebase Console

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBcj_KPcqvcdHGsD28PmWrzna94pAkfN1Y',
    appId: '1:495341464287:web:1e373facf5bc2e3c19976a',
    messagingSenderId: '495341464287',
    projectId: 'edutech-smk-app-71383',
    authDomain: 'edutech-smk-app-71383.firebaseapp.com',
    storageBucket: 'edutech-smk-app-71383.firebasestorage.app',
    measurementId: 'G-SVZKM33633',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBcj_KPcqvcdHGsD28PmWrzna94pAkfN1Y',
    appId: '1:495341464287:android:edutech_android',
    messagingSenderId: '495341464287',
    projectId: 'edutech-smk-app-71383',
    storageBucket: 'edutech-smk-app-71383.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBcj_KPcqvcdHGsD28PmWrzna94pAkfN1Y',
    appId: '1:495341464287:ios:edutech_ios',
    messagingSenderId: '495341464287',
    projectId: 'edutech-smk-app-71383',
    storageBucket: 'edutech-smk-app-71383.firebasestorage.app',
    iosBundleId: 'com.example.edutechSmk',
  );
}
