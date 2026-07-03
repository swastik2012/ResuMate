import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resumate/firebase_options.dart';
import 'package:resumate/core/theme/app_theme.dart';
import 'package:resumate/core/theme/theme_provider.dart';
import 'package:resumate/features/auth/presentation/auth_provider.dart';
import 'package:resumate/features/auth/presentation/login_screen.dart';
import 'package:resumate/features/home/presentation/home_screen.dart';
import 'package:resumate/features/splash/presentation/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Launch the app immediately with the splash screen — no blocking async work.
  runApp(
    const ProviderScope(
      child: ResuMateApp(),
    ),
  );
}

/// Root app widget. Shows SplashScreen first, then reactively transitions to
/// HomeScreen or LoginScreen based on authentication state changes.
class ResuMateApp extends ConsumerStatefulWidget {
  const ResuMateApp({super.key});

  @override
  ConsumerState<ResuMateApp> createState() => _ResuMateAppState();
}

class _ResuMateAppState extends ConsumerState<ResuMateApp> {
  bool _splashCompleted = false;

  /// Runs all initialization work in parallel with tight timeouts.
  Future<bool> _performInitialization() async {
    // 1. Pre-warm SharedPreferences (disk I/O, independent of Firebase)
    // 2. Initialize Firebase (network, may timeout)
    await Future.wait([
      _initFirebase(),
      SharedPreferences.getInstance(), // pre-warm cache
    ]);

    // 3. Wait for the auth provider to resolve from loading → data/error
    final isSignedIn = await _waitForAuth();
    return isSignedIn;
  }

  /// Single-attempt Firebase init with a 3-second timeout.
  Future<void> _initFirebase() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      if (options.apiKey.isNotEmpty && options.apiKey != 'YOUR_API_KEY_HERE') {
        await Firebase.initializeApp(options: options)
            .timeout(const Duration(seconds: 3));
        debugPrint('Firebase initialized successfully.');
        return;
      }
    } catch (e) {
      debugPrint('Firebase init with options failed: $e');
    }

    // Fallback: try default init (for google-services.json auto-config)
    try {
      await Firebase.initializeApp()
          .timeout(const Duration(seconds: 3));
      debugPrint('Firebase initialized with defaults.');
    } catch (e) {
      debugPrint('Firebase initialization bypassed: $e. Running in offline mode.');
    }
  }

  /// Waits up to 4 seconds for the auth stream to emit a data/error value.
  Future<bool> _waitForAuth() async {
    const maxWait = Duration(seconds: 4);
    final deadline = DateTime.now().add(maxWait);

    while (DateTime.now().isBefore(deadline)) {
      final state = ref.read(authProvider);
      if (state is AsyncData<dynamic>) {
        return state.value != null;
      }
      if (state is AsyncError<dynamic>) {
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 80));
    }

    // Timed out — treat as not signed in
    return false;
  }

  void _onSplashComplete(bool isSignedIn) {
    if (!mounted || _splashCompleted) return;
    setState(() {
      _splashCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);

    Widget screen;
    if (!_splashCompleted) {
      screen = SplashScreen(
        onInitialize: _performInitialization,
        onComplete: _onSplashComplete,
      );
    } else {
      screen = authState.maybeWhen(
        data: (user) => user != null ? const HomeScreen() : const LoginScreen(),
        orElse: () => const LoginScreen(),
      );
    }

    return MaterialApp(
      title: 'ResuMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode.toThemeMode,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey(screen.runtimeType),
          child: screen,
        ),
      ),
    );
  }
}
