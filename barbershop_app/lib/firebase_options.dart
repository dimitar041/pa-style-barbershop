import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('Firebase options не са конфигурирани за тази платформа.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDrJePBgcA_iB7fNCcYIt8ZXqyvKRdzWGQ',
    authDomain: 'pa-style-barbershop.firebaseapp.com',
    projectId: 'pa-style-barbershop',
    storageBucket: 'pa-style-barbershop.firebasestorage.app',
    messagingSenderId: '963446096890',
    appId: '1:963446096890:web:d4041781f8f95ad51c1a43',
  );
}

