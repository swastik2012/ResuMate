import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as google_ai;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiClient {
  static const _prefsKey = 'user_gemini_api_key';
  
  // Default built-in Gemini API key (or pass via --dart-define=GEMINI_API_KEY=your_key)
  static const String _defaultAppKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  
  String? _userApiKey;

  GeminiClient() {
    _loadKey();
  }

  Future<void> _loadKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_prefsKey);
      if (savedKey != null && savedKey.trim().isNotEmpty) {
        _userApiKey = savedKey.trim();
      }
    } catch (_) {}
  }

  Future<void> setApiKey(String key) async {
    _userApiKey = key.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _userApiKey!);
    } catch (_) {}
  }

  String? get userApiKey => _userApiKey;

  String? get apiKey => _userApiKey ?? (_defaultAppKey.isNotEmpty ? _defaultAppKey : null);

  bool get hasValidKey => (apiKey != null && apiKey!.trim().isNotEmpty) || FirebaseAuth.instance.currentUser != null;

  bool get isConfigured => hasValidKey;

  void updateApiKey(String key) {
    setApiKey(key);
  }

  /// Generate text using Firebase Vertex AI (Firebase AI Logic), standard Gemini SDK, or Bearer OAuth fallback.
  Future<String> generateText({
    required String prompt,
    double temperature = 0.2,
    String? googleAccessToken,
  }) async {
    Object? vertexError;

    // 1. Try Firebase Vertex AI / Firebase AI Logic if user is signed in with Firebase (Google Login)
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      for (final modelName in ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-flash-latest']) {
        try {
          final googleAI = FirebaseAI.googleAI(auth: FirebaseAuth.instance);
          final vertexModel = googleAI.generativeModel(
            model: modelName,
            generationConfig: GenerationConfig(temperature: temperature),
          );
          final response = await vertexModel.generateContent([
            Content.text(prompt),
          ]);
          if (response.text != null && response.text!.isNotEmpty) {
            return response.text!;
          }
        } catch (e) {
          vertexError = e;
          debugPrint('Firebase Vertex AI generation with $modelName failed: $e.');
        }
      }
    }

    // 2. Generate text using configured API Key (Custom User Key or App Default Key)
    final activeKey = apiKey;
    if (activeKey != null && activeKey.trim().isNotEmpty) {
      for (final modelName in ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-flash-latest']) {
        try {
          final model = google_ai.GenerativeModel(
            model: modelName,
            apiKey: activeKey.trim(),
          );
          final content = [google_ai.Content.text(prompt)];
          final response = await model.generateContent(
            content,
            generationConfig: google_ai.GenerationConfig(temperature: temperature),
          );
          if (response.text != null && response.text!.isNotEmpty) {
            return response.text!;
          }
        } catch (e) {
          debugPrint('Gemini SDK generation with $modelName failed: $e');
        }
      }
    }

    // 3. Fallback: Google Access Token if provided
    if (googleAccessToken != null && googleAccessToken.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
        );
        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $googleAccessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {'temperature': temperature}
          }),
        );
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final candidates = json['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              return parts[0]['text'] as String;
            }
          }
        }
      } catch (e) {
        debugPrint('Gemini via Bearer token failed: $e');
      }
    }

    if (vertexError != null) {
      throw Exception(
        'AI Error: $vertexError\n\nPlease ensure Vertex AI is enabled in Firebase Console (https://console.firebase.google.com/), or enter an API key in AI Assistant settings.',
      );
    }

    throw Exception(
      'Gemini API key is required. Please sign in with Google or enter your free API key in AI Assistant settings.',
    );
  }

  /// Generate text from a multimodal PDF input.
  Future<String> generateFromPdf({
    required String prompt,
    required Uint8List pdfBytes,
    double temperature = 0.2,
  }) async {
    Object? vertexError;

    // 1. Try Firebase Vertex AI / Firebase AI Logic
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      for (final modelName in ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-flash-latest']) {
        try {
          final googleAI = FirebaseAI.googleAI(auth: FirebaseAuth.instance);
          final vertexModel = googleAI.generativeModel(
            model: modelName,
            generationConfig: GenerationConfig(temperature: temperature),
          );
          final response = await vertexModel.generateContent([
            Content.multi([
              TextPart(prompt),
              InlineDataPart('application/pdf', pdfBytes),
            ]),
          ]);
          if (response.text != null && response.text!.isNotEmpty) {
            return response.text!;
          }
        } catch (e) {
          vertexError = e;
          debugPrint('Firebase Vertex AI PDF generation with $modelName failed: $e.');
        }
      }
    }

    // 2. Try Standard Gemini API (Developer API) using an API key if provided
    final activeKey = apiKey;
    if (activeKey != null && activeKey.trim().isNotEmpty) {
      for (final modelName in ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-flash-latest']) {
        try {
          final model = google_ai.GenerativeModel(
            model: modelName,
            apiKey: activeKey.trim(),
            generationConfig: google_ai.GenerationConfig(temperature: temperature),
          );
          final response = await model.generateContent([
            google_ai.Content.multi([
              google_ai.TextPart(prompt),
              google_ai.DataPart('application/pdf', pdfBytes),
            ]),
          ]);
          if (response.text != null && response.text!.isNotEmpty) {
            return response.text!;
          }
        } catch (e) {
          debugPrint('Gemini SDK PDF generation with $modelName failed: $e');
        }
      }
    }

    if (vertexError != null) {
      throw Exception('AI Error: $vertexError');
    }

    throw Exception('Gemini API key or authenticated user is required for PDF parsing.');
  }
}

final geminiClientProvider = Provider<GeminiClient>((ref) {
  return GeminiClient();
});
