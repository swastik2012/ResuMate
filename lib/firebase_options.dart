import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  // Google Client ID for Web / Android Google Sign-In
  static const String googleClientId = '716044738686-t3deac0d5lvg29ukjim8ivs4jlvk88lq.apps.googleusercontent.com';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCekMBYvvZ3p9t0c7v-fjzfASIKABx34Oo',
    appId: '1:716044738686:web:36ba0f1287291f981b782f',
    messagingSenderId: '716044738686',
    projectId: 'resumebuilder-01',
    authDomain: 'resumebuilder-01.firebaseapp.com',
    storageBucket: 'resumebuilder-01.firebasestorage.app',
    measurementId: 'G-FHHM686468',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBEaT5wLrfq-VUHDBXHVUlqFj2DZsqhhKQ',
    appId: '1:716044738686:android:8e6c4f37e960edcc1b782f',
    messagingSenderId: '716044738686',
    projectId: 'resumebuilder-01',
    storageBucket: 'resumebuilder-01.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB7XzZWoQZqUAyka4oEtIZ3Ek6YaS2Q30s',
    appId: '1:716044738686:ios:3c448721511d23671b782f',
    messagingSenderId: '716044738686',
    projectId: 'resumebuilder-01',
    storageBucket: 'resumebuilder-01.firebasestorage.app',
    iosClientId: '716044738686-crtlnvfvpbqllmseunq2fqes0jjbddnb.apps.googleusercontent.com',
    iosBundleId: 'com.resumate.app',
  );
}
