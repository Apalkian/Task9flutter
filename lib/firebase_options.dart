
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
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyD-Apz4dHNJjaI6h1q0i51hSpF1m56MW8E',
    appId: '1:400778187363:web:b6ba097620922836fb1e56',
    messagingSenderId: '400778187363',
    projectId: 'notes-2f3e7',
    authDomain: 'notes-2f3e7.firebaseapp.com',
    storageBucket: 'notes-2f3e7.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCzVUaUz9wvmz-P-0CsyR_ngbatuFnd-Ns',
    appId: '1:400778187363:android:fd0c9a68a52f666dfb1e56',
    messagingSenderId: '400778187363',
    projectId: 'notes-2f3e7',
    storageBucket: 'notes-2f3e7.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDUr0Wx7JJk84ZqgDYXEW1kVcoeQOIxRkQ',
    appId: '1:400778187363:ios:2eb24b60257900b3fb1e56',
    messagingSenderId: '400778187363',
    projectId: 'notes-2f3e7',
    storageBucket: 'notes-2f3e7.firebasestorage.app',
    iosBundleId: 'com.example.firebaseAuthapal',
  );
}
