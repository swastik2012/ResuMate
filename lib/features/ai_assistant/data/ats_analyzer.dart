import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resume_builder/core/network/gemini_client.dart';
import 'package:resume_builder/features/resume/domain/resume_model.dart';

class AtsResult {
  final int score;
  final List<String> missingKeywords;
  final List<String> formattingRisks;
  final String actionPlan;

  AtsResult({
    required this.score,
    required this.missingKeywords,
    required this.formattingRisks,
    required this.actionPlan,
  });

  factory AtsResult.empty() => AtsResult(
        score: 0,
        missingKeywords: [],
        formattingRisks: [],
        actionPlan: 'Paste a target job description in the form below to run the ATS compliance scan.',
      );
}

class AtsAnalyzer {
  final GeminiClient _geminiClient;

  AtsAnalyzer(this._geminiClient);

  Future<AtsResult> analyze(ResumeData resumeData) async {
    final jd = resumeData.targetJobDescription.trim();
    if (jd.isEmpty) {
      return AtsResult.empty();
    }

    if (!_geminiClient.isConfigured) {
      return _runHeuristicAnalysis(resumeData, jd);
    }

    try {
      final resumeJson = _serializeResume(resumeData);
      final prompt = '''
You are an expert ATS (Applicant Tracking System) scanner. Analyze the following candidate resume data against the target job description.
Return a valid JSON object ONLY. Do not wrap it in markdown code blocks. The JSON must contain exactly these fields:
- "score": integer between 0 and 100 representing job description match compliance.
- "missingKeywords": array of strings (top critical keywords lacking in the resume).
- "formattingRisks": array of strings (formatting issues, passive voice warnings, etc.).
- "actionPlan": a brief 2-3 sentence recommendation for optimization.

Candidate Resume Data:
$resumeJson

Target Job Description:
$jd
''';

      final responseText = await _geminiClient.generateText(prompt: prompt);
      
      // Clean up markdown block wraps if Gemini outputs them
      var cleanJson = responseText.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.substring(7);
      }
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.substring(3);
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }
      cleanJson = cleanJson.trim();

      final data = json.decode(cleanJson);
      return AtsResult(
        score: (data['score'] as num?)?.toInt() ?? 50,
        missingKeywords: List<String>.from(data['missingKeywords'] ?? []),
        formattingRisks: List<String>.from(data['formattingRisks'] ?? []),
        actionPlan: data['actionPlan'] ?? 'Optimize your keywords to match the target description.',
      );
    } catch (e) {
      print('AI ATS analysis failed: $e. Defaulting to local heuristic search.');
      return _runHeuristicAnalysis(resumeData, jd);
    }
  }

  String _serializeResume(ResumeData data) {
    return json.encode({
      'name': data.personalInfo.fullName,
      'summary': data.personalInfo.summary,
      'experiences': data.workExperience.map((e) => {
            'role': e.position,
            'company': e.company,
            'description': e.description,
          }).toList(),
      'education': data.education.map((e) => {
            'degree': e.degree,
            'school': e.institution,
          }).toList(),
      'skills': data.skills.map((s) => s.name).toList(),
    });
  }

  AtsResult _runHeuristicAnalysis(ResumeData resume, String jd) {
    final jdWords = jd
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 4)
        .toSet();

    final resumeText = _serializeResume(resume).toLowerCase();
    
    final matchedWords = <String>[];
    final missingWords = <String>[];

    for (final word in jdWords) {
      if (const {'experience', 'skills', 'responsibilities', 'qualifications', 'requirements', 'working', 'ability'}.contains(word)) {
        continue;
      }
      if (resumeText.contains(word)) {
        matchedWords.add(word);
      } else {
        missingWords.add(word);
      }
    }

    final totalTarget = jdWords.length.clamp(5, 50);
    final matchScore = ((matchedWords.length / totalTarget) * 100).round().clamp(15, 95);

    final missingKeywords = missingWords.take(5).map((w) => w[0].toUpperCase() + w.substring(1)).toList();

    return AtsResult(
      score: matchScore,
      missingKeywords: missingKeywords.isNotEmpty ? missingKeywords : ['No major missing keywords found.'],
      formattingRisks: [
        'Running on Local Heuristics (Gemini API Key is not configured)',
        if (resume.personalInfo.summary.split(' ').length < 20) 'Profile summary is too short',
        if (resume.workExperience.isEmpty) 'No work experience sections defined',
      ],
      actionPlan: 'Set your Gemini API Key in the AI Assistant Panel to scan utilizing semantic terminology checks.',
    );
  }
}

final atsAnalyzerProvider = Provider<AtsAnalyzer>((ref) {
  final gemini = ref.watch(geminiClientProvider);
  return AtsAnalyzer(gemini);
});
