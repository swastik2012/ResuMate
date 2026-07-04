import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resumate/firebase_options.dart';

class AuthUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool isMock;

  AuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.isMock = false,
  });
}

abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  Future<AuthUser> signInWithGoogle({bool forceMock = false});
  Future<void> signOut();
  AuthUser? get currentUser;
  Future<Map<String, String>?> getAuthHeaders();
}

class HybridAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;
  bool _useMock = false;

  GoogleSignIn? _googleSignInInstance;
  GoogleSignInAccount? _googleSignInAccount;

  Future<GoogleSignIn> _ensureGoogleSignIn() async {
    _googleSignInInstance ??= GoogleSignIn(
      serverClientId: DefaultFirebaseOptions.googleClientId,
      scopes: [
        'email',
        'https://www.googleapis.com/auth/drive.file',
      ],
    );
    return _googleSignInInstance!;
  }

  HybridAuthRepository() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isSavedLoggedIn = prefs.getBool('auth_is_logged_in') ?? false;
    final savedIsMock = prefs.getBool('auth_is_mock') ?? false;
    final savedUid = prefs.getString('auth_uid');
    final savedEmail = prefs.getString('auth_email');
    final savedName = prefs.getString('auth_name');

    // 1. Immediately restore cached session from SharedPreferences for instant startup
    if (isSavedLoggedIn && savedUid != null) {
      _useMock = savedIsMock;
      _currentUser = AuthUser(
        uid: savedUid,
        email: savedEmail ?? '',
        displayName: savedName ?? 'User',
        isMock: savedIsMock,
      );
      _controller.add(_currentUser);
    }

    try {
      if (Firebase.apps.isNotEmpty) {
        final existingFirebaseUser = FirebaseAuth.instance.currentUser;
        if (existingFirebaseUser != null && !_useMock) {
          _currentUser = AuthUser(
            uid: existingFirebaseUser.uid,
            email: existingFirebaseUser.email ?? '',
            displayName: existingFirebaseUser.displayName ?? 'Google User',
            photoUrl: existingFirebaseUser.photoURL,
          );
          _saveSession(_currentUser!);
          _controller.add(_currentUser);
        }

        FirebaseAuth.instance.authStateChanges().listen((user) {
          if (!_useMock) {
            if (user == null) {
              _currentUser = null;
              _clearSession();
              _controller.add(null);
            } else {
              _currentUser = AuthUser(
                uid: user.uid,
                email: user.email ?? '',
                displayName: user.displayName ?? 'Google User',
                photoUrl: user.photoURL,
              );
              _saveSession(_currentUser!);
              _controller.add(_currentUser);
            }
          }
        });

        // Silently restore Google account session
        try {
          final googleSignIn = await _ensureGoogleSignIn();
          _googleSignInAccount = await googleSignIn.signInSilently();
        } catch (_) {}
      } else if (!isSavedLoggedIn) {
        _useMock = true;
        _currentUser = null;
        _controller.add(null);
      }
    } catch (e) {
      debugPrint('Firebase Auth init listener note: $e.');
    }
  }

  Future<void> _saveSession(AuthUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_is_logged_in', true);
      await prefs.setBool('auth_is_mock', user.isMock);
      await prefs.setString('auth_uid', user.uid);
      await prefs.setString('auth_email', user.email);
      await prefs.setString('auth_name', user.displayName);
    } catch (_) {}
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_is_logged_in');
      await prefs.remove('auth_is_mock');
      await prefs.remove('auth_uid');
      await prefs.remove('auth_email');
      await prefs.remove('auth_name');
    } catch (_) {}
  }

  @override
  Stream<AuthUser?> get authStateChanges async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<Map<String, String>?> getAuthHeaders() async {
    if (_useMock) return null;
    try {
      final googleSignIn = await _ensureGoogleSignIn();
      _googleSignInAccount ??= await googleSignIn.signInSilently();
      if (_googleSignInAccount == null) {
        return null;
      }
      return await _googleSignInAccount!.authHeaders;
    } catch (e) {
      debugPrint('Error getting auth headers: $e');
      return null;
    }
  }

  @override
  Future<AuthUser> signInWithGoogle({bool forceMock = false}) async {
    if (forceMock) {
      return _mockSignIn();
    }

    try {
      if (Firebase.apps.isEmpty) {
        try {
          final options = DefaultFirebaseOptions.currentPlatform;
          await Firebase.initializeApp(options: options);
        } catch (_) {
          await Firebase.initializeApp();
        }
      }

      final googleSignIn = await _ensureGoogleSignIn();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In cancelled by user.');
      }
      _googleSignInAccount = googleUser;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user!;
      
      _useMock = false;
      _currentUser = AuthUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Google User',
        photoUrl: user.photoURL,
      );
      await _saveSession(_currentUser!);
      _controller.add(_currentUser);
      return _currentUser!;
    } catch (e) {
      debugPrint('Firebase Sign-In failed or unconfigured: $e.');
      rethrow;
    }
  }

  Future<AuthUser> _mockSignIn() async {
    _useMock = true;
    _currentUser = AuthUser(
      uid: 'mock_user_123',
      email: 'jane.doe@example.com',
      displayName: 'Jane Doe',
      photoUrl: null,
      isMock: true,
    );
    await _saveSession(_currentUser!);
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await _clearSession();
    if (!_useMock) {
      try {
        final googleSignIn = await _ensureGoogleSignIn();
        await googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    _googleSignInAccount = null;
    _currentUser = null;
    _controller.add(null);
  }
}
