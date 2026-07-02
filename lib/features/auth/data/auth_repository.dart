import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:resume_builder/firebase_options.dart';

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
    if (_googleSignInInstance == null) {
      final clientId = (DefaultFirebaseOptions.googleClientId.isNotEmpty && 
                        DefaultFirebaseOptions.googleClientId != 'YOUR_GOOGLE_CLIENT_ID_HERE')
          ? DefaultFirebaseOptions.googleClientId
          : null;
      _googleSignInInstance = GoogleSignIn(
        clientId: clientId,
        scopes: [
          'email',
          'https://www.googleapis.com/auth/drive.file',
        ],
      );
    }
    return _googleSignInInstance!;
  }

  HybridAuthRepository() {
    _init();
  }

  void _init() {
    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseAuth.instance.authStateChanges().listen((user) {
          if (!_useMock) {
            if (user == null) {
              _currentUser = null;
              _controller.add(null);
            } else {
              _currentUser = AuthUser(
                uid: user.uid,
                email: user.email ?? '',
                displayName: user.displayName ?? 'Google User',
                photoUrl: user.photoURL,
              );
              _controller.add(_currentUser);
            }
          }
        });
      } else {
        _useMock = true;
        _currentUser = null;
        _controller.add(null);
      }
    } catch (e) {
      print('Failed to initialize Firebase Auth listener: $e. Defaulting to mock authentication mode.');
      _useMock = true;
      _currentUser = null;
      _controller.add(null);
    }
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
      print('Error getting auth headers: $e');
      return null;
    }
  }

  @override
  Future<AuthUser> signInWithGoogle({bool forceMock = false}) async {
    if (forceMock || _useMock || Firebase.apps.isEmpty) {
      return _mockSignIn();
    }

    try {
      final googleSignIn = await _ensureGoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In aborted by user.');
      }
      _googleSignInAccount = googleUser;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user!;
      
      _currentUser = AuthUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Google User',
        photoUrl: user.photoURL,
      );
      _controller.add(_currentUser);
      return _currentUser!;
    } catch (e) {
      print('Firebase Sign-In failed or unconfigured: $e.');
      rethrow;
    }
  }

  AuthUser _mockSignIn() {
    _useMock = true;
    _currentUser = AuthUser(
      uid: 'mock_user_123',
      email: 'jane.doe@example.com',
      displayName: 'Jane Doe',
      photoUrl: null,
      isMock: true,
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    if (_useMock) {
      _currentUser = null;
      _controller.add(null);
      return;
    }
    try {
      final googleSignIn = await _ensureGoogleSignIn();
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Silently handle if firebase is not running
    }
    _googleSignInAccount = null;
    _currentUser = null;
    _controller.add(null);
  }
}
