import 'dart:convert';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sync_pdf;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:resumate/core/network/gemini_client.dart';
import 'package:resumate/core/utils/pdf_generator.dart';
import 'package:resumate/features/home/presentation/resume_list_provider.dart';
import 'package:resumate/features/resume/domain/resume_model.dart';
import 'package:flutter/foundation.dart';
import 'package:resumate/features/resume/presentation/workspace_screen.dart';

class TemplateSelectionScreen extends ConsumerStatefulWidget {
  final bool startWithImport;

  const TemplateSelectionScreen({super.key, this.startWithImport = false});

  @override
  ConsumerState<TemplateSelectionScreen> createState() =>
      _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState
    extends ConsumerState<TemplateSelectionScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.startWithImport) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAiImportDialog(context);
      });
    }
  }

  static const _templates = [
    _TemplateInfo(
      id: 'modern_indigo',
      name: 'Modern Indigo',
      description: 'Clean modern layout with indigo accent dividers',
      icon: Icons.palette_outlined,
      color: Color(0xFF1A237E),
      tags: ['Modern', 'ATS-Friendly'],
    ),
    _TemplateInfo(
      id: 'minimalist_executive',
      name: 'Minimalist',
      description: 'Ultra-clean minimal design with tight spacing',
      icon: Icons.business_center_outlined,
      color: Color(0xFF424242),
      tags: ['Minimal', 'Professional'],
    ),
    _TemplateInfo(
      id: 'tech_professional',
      name: 'Tech Monospace',
      description: 'Side-by-side headers with monospace Courier font',
      icon: Icons.code_rounded,
      color: Color(0xFF006064),
      tags: ['Tech', 'Monospace'],
    ),
    _TemplateInfo(
      id: 'classic_elegance',
      name: 'Classic Serif',
      description: 'Centered Times Roman layout with traditional elegance',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF3E2723),
      tags: ['Classic', 'Serif'],
    ),
    _TemplateInfo(
      id: 'two_column_sidebar',
      name: 'Two-Column Sidebar',
      description: 'Dark sidebar for contact & skills, content on right',
      icon: Icons.view_sidebar_rounded,
      color: Color(0xFF1B5E20),
      tags: ['Creative', '2-Column'],
    ),
    _TemplateInfo(
      id: 'creative_bold',
      name: 'Creative Bold',
      description: 'Large accent header block with bold typography',
      icon: Icons.format_bold_rounded,
      color: Color(0xFFBF360C),
      tags: ['Creative', 'Bold'],
    ),
    _TemplateInfo(
      id: 'ats_clean',
      name: 'ATS Clean',
      description: 'Maximum ATS compatibility with generous whitespace',
      icon: Icons.check_circle_outline_rounded,
      color: Color(0xFF0D47A1),
      tags: ['ATS-Optimized', 'Clean'],
    ),
    _TemplateInfo(
      id: 'executive_formal',
      name: 'Executive Formal',
      description: 'Navy & gold accents with traditional serif layout',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFF0D47A1),
      tags: ['Executive', 'Formal'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Template'),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Select a resume template to get started. You can always switch templates later from the preview.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tpl = _templates[index];
                  return _TemplateCard(
                    info: tpl,
                    onTap: () => _showTemplatePreviewDialog(context, tpl),
                  );
                },
                childCount: _templates.length,
              ),
            ),
          ),
          // Import with AI Card
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: InkWell(
                  onTap: () => _showAiImportDialog(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.purple.shade400,
                              Colors.deepPurple.shade600,
                            ]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Import Your Own Resume',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Paste text from your existing resume and let AI extract & structure it',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  void _selectTemplate(String templateId, {String? name}) {
    final id = ref
        .read(resumeListProvider.notifier)
        .createResume(templateId: templateId, name: name);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WorkspaceScreen(resumeId: id),
      ),
    );
  }

  void _showTemplatePreviewDialog(BuildContext context, _TemplateInfo tpl) {
    final nameController = TextEditingController(text: '${tpl.name} Resume');
    final sampleData = ResumeData.demo().copyWith(templateId: tpl.id);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 700,
          height: 680,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tpl.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(tpl.icon, color: tpl.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tpl.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          tpl.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Live PDF Preview Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: PdfPreview(
                    build: (format) => compute(PdfGenerator.generate, sampleData),
                    useActions: false,
                    allowPrinting: false,
                    allowSharing: false,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Custom Resume Name Input & Selection Action
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Resume Name',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      final chosenName = nameController.text.trim();
                      Navigator.pop(ctx);
                      _selectTemplate(tpl.id, name: chosenName.isNotEmpty ? chosenName : null);
                    },
                    icon: const Icon(Icons.check_rounded, color: Colors.white),
                    label: const Text(
                      'Use This Template',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.primary
                          : tpl.color,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAiImportDialog(BuildContext context) {
    final client = ref.read(geminiClientProvider);
    final textController = TextEditingController();
    final apiKeyController = TextEditingController(text: client.userApiKey ?? '');
    bool isLoading = false;
    String? statusMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.purple),
                SizedBox(width: 8),
                Text('AI Resume Parser'),
              ],
            ),
            content: SizedBox(
              width: 550,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Paste the raw text of your existing resume below. AI will extract and structure your information automatically.',
                      style: TextStyle(fontSize: 12, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: apiKeyController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Gemini API Key (Optional)',
                        hintText: 'Leave blank to use built-in AI key',
                        prefixIcon: const Icon(Icons.key_rounded, size: 18),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          onPressed: () {
                            if (apiKeyController.text.trim().isNotEmpty) {
                              client.setApiKey(apiKeyController.text.trim());
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('API Key saved!')),
                              );
                            }
                          },
                        ),
                      ),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (val) {
                        if (val.trim().isNotEmpty) {
                          client.setApiKey(val.trim());
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (statusMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          statusMessage!,
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text('Extracting and structuring resume...',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                              controller: textController,
                              maxLines: 6,
                              decoration: const InputDecoration(
                                labelText: 'Paste raw resume text here',
                                alignLabelWithHint: true,
                                hintText: 'John Doe\njohn.doe@email.com...',
                              ),
                            ),
                          const SizedBox(height: 16),
                          const Center(
                            child: Text('OR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonalIcon(
                                  onPressed: () async {
                                    final result = await FilePicker.platform.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: ['pdf'],
                                      withData: true,
                                    );
                                    if (result != null && result.files.single.bytes != null) {
                                      final bytes = result.files.single.bytes!;
                                      
                                      if (apiKeyController.text.trim().isNotEmpty) {
                                        await client.setApiKey(apiKeyController.text.trim());
                                      }

                                      setState(() {
                                        isLoading = true;
                                        statusMessage = 'Extracting from PDF...';
                                      });

                                      ResumeData parsedData;
                                      try {
                                        // On-device text extraction
                                        final document = sync_pdf.PdfDocument(inputBytes: bytes);
                                        final extractedText = sync_pdf.PdfTextExtractor(document).extractText();
                                        document.dispose();

                                        final prompt = _buildParsePrompt(extractedText);
                                        final response = await client.generateText(prompt: prompt);
                                        var clean = response.trim();
                                        if (clean.startsWith('```json')) clean = clean.substring(7);
                                        if (clean.startsWith('```')) clean = clean.substring(3);
                                        if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
                                        clean = clean.trim();
                                        parsedData = ResumeData.fromJson(jsonDecode(clean));
                                      } catch (e) {
                                        // Fallback to offline parsing if API fails or parsing fails
                                        try {
                                          final document = sync_pdf.PdfDocument(inputBytes: bytes);
                                          final extractedText = sync_pdf.PdfTextExtractor(document).extractText();
                                          document.dispose();
                                          parsedData = _parseResumeTextHeuristically(extractedText);
                                        } catch (fallbackError) {
                                          setState(() {
                                            isLoading = false;
                                            statusMessage = 'PDF parsing failed: $e\nFallback failed: $fallbackError';
                                          });
                                          return;
                                        }
                                      }

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        final id = ref.read(resumeListProvider.notifier).createResume(
                                          templateId: 'modern_indigo',
                                          initialData: parsedData,
                                        );
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(builder: (_) => WorkspaceScreen(resumeId: id)),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.picture_as_pdf_rounded),
                                  label: const Text('Upload PDF'),
                                ),
                          const SizedBox(height: 12),
                          const Text(
                            'Note: AI extraction may not be 100% accurate. Please review and verify the extracted information in your workspace.',
                            style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                        final text = textController.text.trim();
                        if (text.isEmpty) {
                          setState(() => statusMessage = 'Please paste some resume text first.');
                          return;
                        }

                        // Save API key if typed
                        if (apiKeyController.text.trim().isNotEmpty) {
                          await client.setApiKey(apiKeyController.text.trim());
                        }

                        setState(() {
                          isLoading = true;
                          statusMessage = 'Parsing resume...';
                        });

                        ResumeData parsedData;
                        try {
                          final prompt = _buildParsePrompt(text);
                          final response = await client.generateText(prompt: prompt);
                          var clean = response.trim();
                          if (clean.startsWith('```json')) clean = clean.substring(7);
                          if (clean.startsWith('```')) clean = clean.substring(3);
                          if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
                          clean = clean.trim();
                          parsedData = ResumeData.fromJson(jsonDecode(clean));
                        } catch (e) {
                          // Fallback to intelligent heuristic text parser on API error/missing key
                          parsedData = _parseResumeTextHeuristically(text);
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                          final id = ref
                              .read(resumeListProvider.notifier)
                              .createResume(templateId: 'modern_indigo', initialData: parsedData);
                          if (mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => WorkspaceScreen(resumeId: id),
                              ),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Extract & Create Resume'),
              ),
            ],
          );
        },
      ),
    );
  }

  static ResumeData _parseResumeTextHeuristically(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    String fullName = '';
    String email = '';
    String phone = '';
    String summary = '';

    final emailMatch = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}').firstMatch(text);
    if (emailMatch != null) email = emailMatch.group(0)!;

    final phoneMatch = RegExp(r'(\+?\d[\d\s\-\(\)]{8,}\d)').firstMatch(text);
    if (phoneMatch != null) phone = phoneMatch.group(0)!;

    for (final line in lines) {
      if (!line.contains('@') && !RegExp(r'\d{6,}').hasMatch(line) && line.length < 40) {
        fullName = line;
        break;
      }
    }

    final skills = <Skill>[];
    final knownSkills = [
      'Flutter', 'Dart', 'Java', 'Python', 'JavaScript', 'TypeScript', 'React',
      'Node.js', 'SQL', 'HTML', 'CSS', 'Git', 'AWS', 'Docker', 'Firebase',
      'C++', 'Kotlin', 'Swift', 'REST API', 'Figma'
    ];
    for (final s in knownSkills) {
      if (text.toLowerCase().contains(s.toLowerCase())) {
        skills.add(Skill(name: s, proficiency: 'Experienced'));
      }
    }

    if (lines.length > 2) {
      summary = lines.take(4).join(' ');
    }

    return ResumeData(
      personalInfo: PersonalInfo(
        fullName: fullName.isNotEmpty ? fullName : 'My Resume',
        email: email,
        phoneNumber: phone,
        summary: summary,
      ),
      skills: skills,
    );
  }

  String _buildParsePrompt(String text) {
    return '''
You are an expert resume parsing system. Extract all information from the provided raw resume text and return a structured JSON.

Return ONLY a valid JSON object. No markdown code blocks. The JSON structure:
{
  "personalInfo": {"fullName":"","email":"","phoneNumber":"","website":"","location":"","summary":"","github":""},
  "workExperience": [{"company":"","position":"","startDate":"","endDate":"","description":""}],
  "education": [{"institution":"","degree":"","startDate":"","endDate":"","gpa":""}],
  "skills": [{"name":"","proficiency":""}],
  "projects": [{"name":"","description":"","link":""}],
  "customSections": [{"id":"","title":"","content":""}]
}

Rules:
1. Return ONLY valid JSON. No markdown.
2. Empty fields = empty strings. Empty arrays = [].
3. For custom sections, create entries for Certifications, Languages, Awards etc. Use lowercase IDs.
4. DO NOT invent or hallucinate information. If the text is empty, return empty fields.

Resume text:
$text
''';
  }
}

// -------------------------------------------------------
// Template Info Model
// -------------------------------------------------------
class _TemplateInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> tags;

  const _TemplateInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.tags,
  });
}

// -------------------------------------------------------
// Template Card Widget
// -------------------------------------------------------
class _TemplateCard extends StatelessWidget {
  final _TemplateInfo info;
  final VoidCallback onTap;

  const _TemplateCard({required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shadowColor: info.color.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Real Template Document Preview Area
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: IgnorePointer(
                  child: PdfPreview(
                    build: (format) => compute(PdfGenerator.generate, ResumeData.demo().copyWith(templateId: info.id)),
                    useActions: false,
                    allowPrinting: false,
                    allowSharing: false,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    padding: EdgeInsets.zero,
                    loadingWidget: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: info.color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Info Footer
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            children: info.tags.map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: info.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: info.color,
                                ),
                              ),
                            )).toList(),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? theme.colorScheme.primary
                                : info.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_rounded, size: 10, color: Colors.white),
                              SizedBox(width: 3),
                              Text(
                                'Preview',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
