import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:resume_builder/firebase_options.dart';
import 'package:resume_builder/core/theme/app_theme.dart';
import 'package:resume_builder/core/theme/theme_provider.dart';
import 'package:resume_builder/features/auth/presentation/auth_provider.dart';
import 'package:resume_builder/features/auth/presentation/login_screen.dart';
import 'package:resume_builder/features/home/presentation/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool isInitialized = false;
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options.apiKey.isNotEmpty && options.apiKey != 'YOUR_API_KEY_HERE') {
      await Firebase.initializeApp(
        options: options,
      );
      isInitialized = true;
      print('Firebase initialized successfully.');
    }
  } catch (e) {
    print('Static Firebase initialization failed: $e');
  }

  if (!isInitialized) {
    try {
      await Firebase.initializeApp();
      print('Firebase initialized successfully.');
    } catch (e) {
      print('Firebase initialization bypassed: $e. Running application in hybrid-offline mode.');
    }
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'ResuMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode.toThemeMode,
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          }
          return const HomeScreen();
        },
        loading: () => const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Signing In...'),
              ],
            ),
          ),
        ),
        error: (err, stack) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Initialization Error: $err\nStacktrace: $stack',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
