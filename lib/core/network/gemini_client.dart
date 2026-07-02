import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class GeminiClient {
  static const _prefsKey = 'user_gemini_api_key';
  String? _userApiKey;

  GeminiClient() {
    _loadKey();
  }

  Future<void> _loadKey() async {
    try {
      const envKey = String.fromEnvironment('GEMINI_API_KEY');
      if (envKey.isNotEmpty) {
        _userApiKey = envKey;
        return;
      }
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

  String? get apiKey => _userApiKey;

  bool get hasValidKey => _userApiKey != null && _userApiKey!.trim().isNotEmpty;

  bool get isConfigured => hasValidKey;

  void updateApiKey(String key) {
    setApiKey(key);
  }

  /// Generate text using Gemini API or throws an exception on failure
  Future<String> generateText({
    required String prompt,
    double temperature = 0.2,
    String? googleAccessToken,
  }) async {
    // 1. Try user API key if configured
    if (hasValidKey) {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: _userApiKey!.trim(),
        );
        final content = [Content.text(prompt)];
        final response = await model.generateContent(
          content,
          generationConfig: GenerationConfig(temperature: temperature),
        );
        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!;
        }
      } catch (e) {
        print('Gemini SDK with API key failed: $e');
      }
    }

    // 2. Try Google OAuth Access Token if user signed in with Google
    if (googleAccessToken != null && googleAccessToken.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
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
        print('Gemini via OAuth Bearer token failed: $e');
      }
    }

    throw Exception(
      'Gemini API key is required for AI features. Please add your free Google AI Studio API key.',
    );
  }
}

final geminiClientProvider = Provider<GeminiClient>((ref) {
  return GeminiClient();
});
