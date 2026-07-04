import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resumate/core/network/gemini_client.dart';
import 'package:resumate/features/auth/presentation/auth_provider.dart';
import 'package:resumate/features/resume/presentation/resume_provider.dart';
import 'package:resumate/features/ai_assistant/data/ats_analyzer.dart';

// Auto-triggering FutureProvider that computes the ATS compliance result
final atsResultProvider = FutureProvider<AtsResult>((ref) async {
  final resume = ref.watch(resumeProvider);
  final analyzer = ref.watch(atsAnalyzerProvider);
  return analyzer.analyze(resume);
});

class AiChatSheet extends ConsumerStatefulWidget {
  final bool isMobile;

  const AiChatSheet({
    super.key,
    required this.isMobile,
  });

  @override
  ConsumerState<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends ConsumerState<AiChatSheet> {
  late TextEditingController _apiKeyController;
  bool _isLoadingAssistant = false;
  String _assistantStatusText = '';

  @override
  void initState() {
    super.initState();
    final client = ref.read(geminiClientProvider);
    _apiKeyController = TextEditingController(text: client.userApiKey ?? '');
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _saveApiKey() {
    final client = ref.read(geminiClientProvider);
    client.updateApiKey(_apiKeyController.text);
    ref.invalidate(atsResultProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(client.isConfigured 
            ? 'API Key saved successfully. Running AI scan...' 
            : 'API Key cleared. Running local scan...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() {});
  }

  // AI execution method
  Future<void> _runOptimization(String promptTemplate, String taskName, Function(String) onAccept) async {
    final client = ref.read(geminiClientProvider);
    if (!client.isConfigured) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('API Key Required'),
          content: const Text('Please configure your Gemini API Key in the assistant panel to use this AI enhancement.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isLoadingAssistant = true;
      _assistantStatusText = 'Running $taskName...';
    });

    try {
      final optimizedText = await client.generateText(prompt: promptTemplate);
      
      if (!mounted) return;
      setState(() {
        _isLoadingAssistant = false;
      });

      // Show comparison review dialog
      _showReviewDialog(taskName, optimizedText, onAccept);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAssistant = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI Optimization failed: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showReviewDialog(String taskName, String optimizedText, Function(String) onAccept) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text('Review AI: $taskName'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Gemini generated optimization preview:',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: SelectableText(
                      optimizedText.trim(),
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Discard',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            FilledButton(
              onPressed: () {
                onAccept(optimizedText.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$taskName successfully applied to your form!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Apply Changes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resume = ref.watch(resumeProvider);
    final atsResult = ref.watch(atsResultProvider);
    final authUser = ref.watch(authProvider).value;
    final isDemo = authUser == null || authUser.isMock;

    final widgetBody = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gemini AI Copilot',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (widget.isMobile)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
          const Divider(height: 24),

          if (isDemo) ...[
            Card(
              color: theme.colorScheme.errorContainer,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, color: theme.colorScheme.onErrorContainer, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Demo Mode Locked',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in with Google to unlock Gemini AI assistant optimizations, keyword scanning, and professional resume tailoring.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.onErrorContainer,
                        foregroundColor: theme.colorScheme.errorContainer,
                      ),
                      onPressed: () async {
                        try {
                          await ref.read(authProvider.notifier).signInWithGoogle();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Sign in failed: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Sign In with Google'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          Opacity(
            opacity: isDemo ? 0.35 : 1.0,
            child: IgnorePointer(
              ignoring: isDemo,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // API Key configuration field
                  Text(
                    'Google AI Studio API Key',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _apiKeyController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'AIZA...',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: _saveApiKey,
                        icon: const Icon(Icons.save_rounded),
                        tooltip: 'Save API Key',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ATS Scoring visual section
                  Text(
                    'ATS Compliance Score',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  atsResult.when(
                    data: (res) {
                      Color scoreColor = theme.colorScheme.error;
                      if (res.score >= 70) {
                        scoreColor = Colors.green;
                      } else if (res.score >= 40) {
                        scoreColor = Colors.orange;
                      }

                      return Card(
                        color: theme.colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 56,
                                        height: 56,
                                        child: CircularProgressIndicator(
                                          value: res.score / 100,
                                          strokeWidth: 6,
                                          backgroundColor: scoreColor.withValues(alpha: 0.15),
                                          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                                        ),
                                      ),
                                      Text(
                                        '${res.score}%',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: scoreColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          res.score >= 70 
                                              ? 'Good Match Compliance!' 
                                              : 'Improvement Recommended',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          res.actionPlan,
                                          style: TextStyle(
                                            fontSize: 11,
                                            height: 1.3,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (res.missingKeywords.isNotEmpty && resume.targetJobDescription.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Missing Target Keywords:',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: res.missingKeywords.map((w) {
                                    return Chip(
                                      label: Text(w, style: const TextStyle(fontSize: 10)),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      backgroundColor: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                                      side: BorderSide.none,
                                    );
                                  }).toList(),
                                ),
                              ],
                              if (res.formattingRisks.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Formatting / Styling Advice:',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...res.formattingRisks.map((risk) => Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.warning_amber_rounded, 
                                            size: 14, 
                                            color: theme.colorScheme.error),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            risk,
                                            style: TextStyle(
                                              fontSize: 11,
                                              height: 1.4,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: LinearProgressIndicator(),
                    ),
                    error: (err, stack) => Text('Error loading ATS score: $err'),
                  ),
                  const SizedBox(height: 20),

                  // Suggestion Prompt Chips
                  Text(
                    'Quick Assistant Optimization Actions',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoadingAssistant) ...[
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(_assistantStatusText, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ] else ...[
                    SuggestionChipItem(
                      label: 'Optimize Work Bullet Points',
                      subtitle: 'Rewrites work descriptions using action-verbs',
                      icon: Icons.flash_on_rounded,
                      onTap: () {
                        if (resume.workExperience.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please add at least one work experience entry.')),
                          );
                          return;
                        }
                        
                        // Optimize first entry as target
                        final originalDesc = resume.workExperience.first.description;
                        final prompt = '''
You are a career development expert. Rewrite the following work experience bullet points to be highly professional and impactful.
Format them as standard bullet points.
Start every action description with a strong executive action verb.
Original description:
$originalDesc
''';
                        _runOptimization(prompt, 'Work Experience Optimization', (optimized) {
                          ref.read(resumeProvider.notifier).updateWorkExperience(
                                0,
                                resume.workExperience.first.copyWith(description: optimized),
                              );
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SuggestionChipItem(
                      label: 'Tailor Profile Summary',
                      subtitle: 'Aligns profile summary with Target Job Description',
                      icon: Icons.track_changes_rounded,
                      onTap: () {
                        if (resume.targetJobDescription.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a Target Job Description in the form first.')),
                          );
                          return;
                        }
                        
                        final originalSummary = resume.personalInfo.summary;
                        final jd = resume.targetJobDescription;
                        final prompt = '''
You are an expert recruiter. Tailor the following candidate profile summary to align with the target job description while maintaining factual accuracy.
Keep it between 3-4 professional, impactful sentences. Do not mention any credentials not indicated in the original text.

Original Summary:
$originalSummary

Target Job Description:
$jd
''';
                        _runOptimization(prompt, 'Summary Tailoring', (optimized) {
                          ref.read(resumeProvider.notifier).updatePersonalInfo(
                                resume.personalInfo.copyWith(summary: optimized),
                              );
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SuggestionChipItem(
                      label: 'Fix Passive Voice',
                      subtitle: 'Converts passive profiles to active professional voice',
                      icon: Icons.spellcheck_rounded,
                      onTap: () {
                        final originalSummary = resume.personalInfo.summary;
                        final prompt = '''
Identify and convert any passive voice formulations into active professional voice in the following profile summary. 
Maintain all original facts and details.

Summary Text:
$originalSummary
''';
                        _runOptimization(prompt, 'Passive Voice Correction', (optimized) {
                          ref.read(resumeProvider.notifier).updatePersonalInfo(
                                resume.personalInfo.copyWith(summary: optimized),
                              );
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.isMobile) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: widgetBody,
        ),
      );
    } else {
      return SingleChildScrollView(
        child: widgetBody,
      );
    }
  }
}

class SuggestionChipItem extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const SuggestionChipItem({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
