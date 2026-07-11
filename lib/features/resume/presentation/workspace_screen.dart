import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sync_pdf;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:resumate/core/theme/theme_provider.dart';
import 'package:resumate/core/utils/pdf_generator.dart';
import 'package:resumate/core/utils/file_helper.dart';
import 'package:resumate/core/utils/docx_generator.dart';
import 'package:resumate/features/auth/presentation/auth_provider.dart';
import 'package:resumate/features/resume/domain/resume_model.dart';
import 'package:resumate/features/resume/presentation/resume_provider.dart';
import 'package:resumate/features/resume/data/summary_suggestions.dart';
import 'package:resumate/features/ai_assistant/presentation/ai_chat_sheet.dart';
import 'package:resumate/features/home/presentation/resume_list_provider.dart';
import 'package:resumate/core/network/gemini_client.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  final String? resumeId;
  const WorkspaceScreen({super.key, this.resumeId});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isTransitioning = true;

  Future<void> _exportDocx(BuildContext context) async {
    final resumeData = ref.read(resumeProvider);
    final name = resumeData.personalInfo.fullName.trim().isNotEmpty
        ? resumeData.personalInfo.fullName.trim().replaceAll(' ', '_')
        : 'Resume';
    final fileName = '${name}_Document.docx';

    final docxBytes = DocxGenerator.generate(resumeData);
    await Printing.sharePdf(
      bytes: docxBytes,
      filename: fileName,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported Word document ($fileName)!')),
      );
    }
  }
  // Mobile View Toggle: 0 for Form Edit, 1 for PDF Preview
  int _mobileSelectedIndex = 0;
  int _previewTemplateIndex = 0;

  static const _allTemplateIds = [
    'modern_indigo',
    'minimalist_executive',
    'tech_professional',
    'classic_elegance',
    'two_column_sidebar',
    'creative_bold',
    'ats_clean',
    'executive_formal',
  ];

  static const _allTemplateNames = [
    'Modern Indigo',
    'Minimalist',
    'Tech Monospace',
    'Classic Serif',
    'Two-Column Sidebar',
    'Creative Bold',
    'ATS Clean',
    'Executive Formal',
  ];

  @override
  void initState() {
    super.initState();
    // Load the resume from the list into the working provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.resumeId != null) {
        final saved = ref.read(resumeListProvider.notifier).getResume(widget.resumeId!);
        if (saved != null) {
          ref.read(resumeProvider.notifier).loadResumeData(saved.data);
          _previewTemplateIndex = _allTemplateIds.indexOf(saved.templateId).clamp(0, _allTemplateIds.length - 1);
        }
      }
    });
    // Set up a listener to sync resume changes back to the list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(resumeProvider, (prev, next) {
        if (widget.resumeId != null) {
          ref.read(resumeListProvider.notifier).updateResume(widget.resumeId!, next);
        }
      });
    });
    
    // Defer rendering of heavy widgets until page transition completes
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() => _isTransitioning = false);
      }
    });
  }

  void _showDemoModeSignInDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign in with Google'),
        content: const Text(
          'Storing your resume on Google Drive is only available when signed in with a Google Account. Would you like to sign in now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
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
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadToGoogleDrive(BuildContext context, Uint8List pdfBytes, String fileName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final headers = await authRepo.getAuthHeaders();
      if (headers == null || !headers.containsKey('Authorization')) {
        throw Exception('Failed to retrieve authentication headers. Please try logging in again.');
      }

      final uri = Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart');
      final boundary = 'resume_builder_boundary_${DateTime.now().millisecondsSinceEpoch}';
      
      final metadata = jsonEncode({
        'name': fileName,
        'mimeType': 'application/pdf',
      });
      
      final List<int> body = [];
      body.addAll(utf8.encode('--$boundary\r\n'));
      body.addAll(utf8.encode('Content-Type: application/json; charset=UTF-8\r\n\r\n'));
      body.addAll(utf8.encode('$metadata\r\n'));
      body.addAll(utf8.encode('--$boundary\r\n'));
      body.addAll(utf8.encode('Content-Type: application/pdf\r\n\r\n'));
      body.addAll(pdfBytes);
      body.addAll(utf8.encode('\r\n--$boundary--\r\n'));

      final response = await http.post(
        uri,
        headers: {
          ...headers,
          'Content-Type': 'multipart/related; boundary=$boundary',
          'Content-Length': body.length.toString(),
        },
        body: body,
      );

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Dismiss loading

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resume uploaded to Google Drive successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Server returned status code ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Upload Failed'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showRenameCurrentResumeDialog(BuildContext context, SavedResume savedResume) {
    final controller = TextEditingController(text: savedResume.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Resume'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Resume Name',
            hintText: 'e.g. Senior Software Engineer Resume',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && widget.resumeId != null) {
                ref.read(resumeListProvider.notifier).renameResume(widget.resumeId!, newName);
              }
              controller.dispose();
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReorderSectionsDialog(BuildContext context) {
    final resume = ref.read(resumeProvider);
    final order = List<String>.from(resume.sectionOrder);

    final sectionNames = {
      'personal_info': 'Contact Information & Summary',
      'experience': 'Work Experience',
      'education': 'Education',
      'skills': 'Professional Skills',
      'projects': 'Projects',
      'custom_sections': 'Custom Sections',
    };

    String getSectionName(String id) {
      if (sectionNames.containsKey(id)) {
        return sectionNames[id]!;
      }
      if (id.startsWith('custom_')) {
        final cs = resume.customSections.firstWhere(
          (s) => s.id == id,
          orElse: () => CustomSection(id: id, title: 'Untitled Section', content: ''),
        );
        return 'Custom: ${cs.title.isNotEmpty ? cs.title : 'Untitled Section'}';
      }
      return id;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Reorder Sections'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Change the vertical layout order of your resume by using the arrows below.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: order.length,
                    itemBuilder: (context, index) {
                      final sec = order[index];
                      return ListTile(
                        dense: true,
                        title: Text(getSectionName(sec), style: const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                              onPressed: index > 0
                                  ? () {
                                      setState(() {
                                        final temp = order[index];
                                        order[index] = order[index - 1];
                                        order[index - 1] = temp;
                                      });
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                              onPressed: index < order.length - 1
                                  ? () {
                                      setState(() {
                                        final temp = order[index];
                                        order[index] = order[index + 1];
                                        order[index + 1] = temp;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(resumeProvider.notifier).updateSectionOrder(order);
                Navigator.pop(context);
              },
              child: const Text('Apply Order'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEditorSections(BuildContext context, List<String> sectionOrder, List<CustomSection> customSections, bool forceOnePage) {
    final List<Widget> formCards = [];
    
    formCards.add(const TemplateSelectorCard());
    formCards.add(const SizedBox(height: 16));
    formCards.add(const AtsCompletenessTracker());
    formCards.add(const SizedBox(height: 16));

    formCards.add(Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.reorder_rounded),
            title: const Text('Reorder Resume Sections'),
            subtitle: const Text('Customize the vertical layout of your resume'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => _showReorderSectionsDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add_rounded),
            title: const Text('Add Custom Section'),
            subtitle: const Text('Create a new custom section (e.g. Certifications, Languages)'),
            onTap: () {
              ref.read(resumeProvider.notifier).addCustomSection();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New custom section added at the end!')),
              );
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.compress_rounded),
            title: const Text('Compact One-Page Mode'),
            subtitle: const Text('Reduces text size and spacing to fit on a single page'),
            value: forceOnePage,
            activeTrackColor: Theme.of(context).colorScheme.primaryContainer,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: (val) {
              final currentResume = ref.read(resumeProvider);
              ref.read(resumeProvider.notifier).loadResumeData(
                currentResume.copyWith(forceOnePage: val),
              );
            },
          ),
        ],
      ),
    ));
    formCards.add(const SizedBox(height: 16));

    for (final section in sectionOrder) {
      if (section == 'personal_info') {
        formCards.add(const PersonalInfoSection());
        formCards.add(const SizedBox(height: 16));
      } else if (section == 'experience') {
        formCards.add(const WorkExperienceSection());
        formCards.add(const SizedBox(height: 16));
      } else if (section == 'education') {
        formCards.add(const EducationSection());
        formCards.add(const SizedBox(height: 16));
      } else if (section == 'skills') {
        formCards.add(const SkillsSection());
        formCards.add(const SizedBox(height: 16));
      } else if (section == 'projects') {
        formCards.add(const ProjectsSection());
        formCards.add(const SizedBox(height: 16));
      } else if (section == 'custom_sections') {
        formCards.add(const CustomSectionsSection());
        formCards.add(const SizedBox(height: 16));
      } else if (customSections.any((s) => s.id == section)) {
        final customSecIndex = customSections.indexWhere((s) => s.id == section);
        if (customSecIndex != -1) {
          final customSec = customSections[customSecIndex];
          formCards.add(CustomSectionItem(index: customSecIndex, section: customSec));
          formCards.add(const SizedBox(height: 16));
        }
      }
    }

    formCards.add(Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: const Icon(Icons.add_rounded),
        title: const Text('Add Custom Section'),
        subtitle: const Text('Create a new custom section (e.g. Certifications, Languages)'),
        onTap: () {
          ref.read(resumeProvider.notifier).addCustomSection();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New custom section added at the end!')),
          );
        },
      ),
    ));
    formCards.add(const SizedBox(height: 16));

    // Duplicate 'Add Custom Section' card removed

    formCards.add(const TargetJobSection());
    formCards.add(const SizedBox(height: 16));
    formCards.add(const ImportExportCard());

    return formCards;
  }

  Widget _buildSkeletonLoader(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface.withValues(alpha: 0.05);
    final highlightColor = theme.colorScheme.onSurface.withValues(alpha: 0.1);

    Widget buildSkeletonCard() {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 150,
                    height: 20,
                    decoration: BoxDecoration(color: highlightColor, borderRadius: BorderRadius.circular(4)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutSine,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSkeletonCard(),
          const SizedBox(height: 16),
          buildSkeletonCard(),
          const SizedBox(height: 16),
          buildSkeletonCard(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final authUser = ref.watch(authProvider).value;
    
    // Watch specific fields to prevent full screen rebuilds on every keystroke
    final templateId = ref.watch(resumeProvider.select((r) => r.templateId));
    final sectionOrder = ref.watch(resumeProvider.select((r) => r.sectionOrder));
    final customSections = ref.watch(resumeProvider.select((r) => r.customSections));
    final forceOnePage = ref.watch(resumeProvider.select((r) => r.forceOnePage));

    // Use ref.read() instead of ref.watch() to avoid the feedback loop:
    // keystroke → resumeProvider mutates → listenManual calls updateResume → 
    // resumeListProvider emits new state → ref.watch triggers full rebuild
    final savedResumes = ref.read(resumeListProvider);
    final currentSavedResume = savedResumes.firstWhere(
      (r) => r.id == widget.resumeId,
      orElse: () => SavedResume(
        id: 'temp',
        name: 'My Resume',
        templateId: templateId,
        lastModified: DateTime.now(),
        data: ref.read(resumeProvider),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: InkWell(
              onTap: () => _showRenameCurrentResumeDialog(context, currentSavedResume),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        currentSavedResume.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            actions: [
              // Theme Toggle Button
              IconButton(
                icon: Icon(themeMode.icon),
                tooltip: 'Theme: ${themeMode.label}',
                onPressed: () {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              ),
              // Export DOCX Button
              IconButton(
                icon: const Icon(Icons.description_outlined),
                color: theme.colorScheme.secondary,
                tooltip: 'Export Microsoft Word (.docx)',
                onPressed: () => _exportDocx(context),
              ),
              // Save to Google Drive Button
              IconButton(
                icon: const Icon(Icons.add_to_drive_rounded),
                color: theme.colorScheme.primary,
                tooltip: 'Save to Google Drive',
                onPressed: () async {
                  final authUser = ref.read(authProvider).value;
                  final isDemo = authUser == null || authUser.isMock;
                  if (isDemo) {
                    _showDemoModeSignInDialog(context);
                  } else {
                    final resumeData = ref.read(resumeProvider);
                    final fileName = '${resumeData.personalInfo.fullName.isNotEmpty ? resumeData.personalInfo.fullName.replaceAll(' ', '_') : 'My'}_Resume.pdf';
                    final pdfBytes = await compute(PdfGenerator.generate, resumeData);
                    if (context.mounted) {
                      await _uploadToGoogleDrive(context, pdfBytes, fileName);
                    }
                  }
                },
              ),
              // AI Assistant Trigger
              IconButton(
                icon: const Icon(Icons.auto_awesome_rounded),
                color: theme.colorScheme.primary,
                tooltip: 'Open AI Assistant',
                onPressed: () {
                  if (isDesktop) {
                    _scaffoldKey.currentState?.openEndDrawer();
                  } else {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AiChatSheet(isMobile: true),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              // Profile/Log Out Button
              if (authUser != null)
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'logout') {
                      ref.read(authProvider.notifier).signOut();
                    }
                  },
                  offset: const Offset(0, 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: authUser.photoUrl != null
                          ? NetworkImage(authUser.photoUrl!)
                          : null,
                      child: authUser.photoUrl == null
                          ? Text(
                              authUser.displayName.isNotEmpty
                                  ? authUser.displayName[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                            )
                          : null,
                    ),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Text(
                        authUser.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    PopupMenuItem(
                      enabled: false,
                      child: Text(
                        authUser.email,
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Log Out'),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 12),
            ],
          ),
          // Side Drawer for AI Assistant on Desktop/Tablet
          endDrawer: isDesktop
              ? const Drawer(
                  width: 420,
                  child: SafeArea(
                    child: AiChatSheet(isMobile: false),
                  ),
                )
              : null,
          body: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Editor Panel
                    Expanded(
                      flex: 12,
                      child: Container(
                        color: theme.colorScheme.surfaceContainerLow,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: _isTransitioning
                              ? _buildSkeletonLoader(context)
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _buildEditorSections(context, sectionOrder, customSections, forceOnePage),
                                ),
                        ),
                      ),
                    ),
                    // Vertical Separator
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    // Right PDF Preview Panel with Template Switcher
                    Expanded(
                      flex: 10,
                      child: Container(
                        color: theme.colorScheme.surface,
                        child: Column(
                          children: [
                            // Template Switcher Header Strip
                            _buildTemplateSwitcherHeader(context, theme, templateId),
                            Expanded(
                              child: Consumer(
                                builder: (context, ref, _) {
                                  final pdfState = ref.watch(pdfBytesProvider);
                                  return pdfState.maybeWhen(
                                    data: (bytes) => RepaintBoundary(
                                      child: PdfPreview(
                                        build: (format) => bytes,
                                        useActions: true,
                                        allowPrinting: true,
                                        allowSharing: true,
                                        canChangePageFormat: false,
                                        canChangeOrientation: false,
                                        canDebug: false,
                                      ),
                                    ),
                                    orElse: () {
                                      if (pdfState.hasValue && pdfState.value != null) {
                                        return RepaintBoundary(
                                          child: PdfPreview(
                                            build: (format) => pdfState.value!,
                                            useActions: true,
                                            allowPrinting: true,
                                            allowSharing: true,
                                            canChangePageFormat: false,
                                            canChangeOrientation: false,
                                            canDebug: false,
                                          ),
                                        );
                                      }
                                      return const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(),
                                            SizedBox(height: 16),
                                            Text('Compiling PDF...'),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              // Mobile Layout View with Nav Bar Switch
              : SafeArea(
                  child: IndexedStack(
                    index: _mobileSelectedIndex,
                    children: [
                      // Form Editor
                      Container(
                        color: theme.colorScheme.surfaceContainerLow,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: _isTransitioning
                              ? _buildSkeletonLoader(context)
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _buildEditorSections(context, sectionOrder, customSections, forceOnePage),
                                ),
                        ),
                      ),
                      // Mobile PDF Preview with Template Switcher
                      Container(
                        color: theme.colorScheme.surface,
                        child: Column(
                          children: [
                            _buildTemplateSwitcherHeader(context, theme, templateId),
                            Expanded(
                              child: Consumer(
                                builder: (context, ref, _) {
                                  final pdfState = ref.watch(pdfBytesProvider);
                                  return pdfState.maybeWhen(
                                    data: (bytes) => RepaintBoundary(
                                      child: PdfPreview(
                                        build: (format) => bytes,
                                        useActions: true,
                                        allowPrinting: true,
                                        allowSharing: true,
                                        canChangePageFormat: false,
                                        canChangeOrientation: false,
                                        canDebug: false,
                                      ),
                                    ),
                                    orElse: () {
                                      if (pdfState.hasValue && pdfState.value != null) {
                                        return RepaintBoundary(
                                          child: PdfPreview(
                                            build: (format) => pdfState.value!,
                                            useActions: true,
                                            allowPrinting: true,
                                            allowSharing: true,
                                            canChangePageFormat: false,
                                            canChangeOrientation: false,
                                            canDebug: false,
                                          ),
                                        );
                                      }
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          extendBody: true,
          bottomNavigationBar: isDesktop
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(48, 0, 48, 16),
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final halfWidth = constraints.maxWidth / 2;
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Animated Selection Indicator
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  left: _mobileSelectedIndex == 0 ? 0 : halfWidth,
                                  width: halfWidth,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: Container(
                                      height: 52,
                                      margin: const EdgeInsets.symmetric(horizontal: 6),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                    ),
                                  ),
                                ),
                                // Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _mobileSelectedIndex = 0),
                                        behavior: HitTestBehavior.opaque,
                                        child: Center(
                                          child: AnimatedDefaultTextStyle(
                                            duration: const Duration(milliseconds: 300),
                                            style: TextStyle(
                                              color: _mobileSelectedIndex == 0
                                                  ? theme.colorScheme.onPrimaryContainer
                                                  : theme.colorScheme.onSurfaceVariant,
                                              fontWeight: _mobileSelectedIndex == 0 ? FontWeight.bold : FontWeight.normal,
                                              fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.edit_note_rounded, 
                                                  color: _mobileSelectedIndex == 0 
                                                      ? theme.colorScheme.onPrimaryContainer 
                                                      : theme.colorScheme.onSurfaceVariant,
                                                  size: 22,
                                                ),
                                                const SizedBox(height: 2),
                                                const Text('Editor', style: TextStyle(fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _mobileSelectedIndex = 1),
                                        behavior: HitTestBehavior.opaque,
                                        child: Center(
                                          child: AnimatedDefaultTextStyle(
                                            duration: const Duration(milliseconds: 300),
                                            style: TextStyle(
                                              color: _mobileSelectedIndex == 1
                                                  ? theme.colorScheme.onPrimaryContainer
                                                  : theme.colorScheme.onSurfaceVariant,
                                              fontWeight: _mobileSelectedIndex == 1 ? FontWeight.bold : FontWeight.normal,
                                              fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.picture_as_pdf_rounded, 
                                                  color: _mobileSelectedIndex == 1 
                                                      ? theme.colorScheme.onPrimaryContainer 
                                                      : theme.colorScheme.onSurfaceVariant,
                                                  size: 22,
                                                ),
                                                const SizedBox(height: 2),
                                                const Text('Preview', style: TextStyle(fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildTemplateSwitcherHeader(BuildContext context, ThemeData theme, String templateId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  final newIdx = (_previewTemplateIndex - 1 + _allTemplateIds.length) % _allTemplateIds.length;
                  setState(() => _previewTemplateIndex = newIdx);
                  ref.read(resumeProvider.notifier).updateTemplateId(_allTemplateIds[newIdx]);
                },
              ),
              Expanded(
                child: Text(
                  _allTemplateNames[_previewTemplateIndex],
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {
                  final newIdx = (_previewTemplateIndex + 1) % _allTemplateIds.length;
                  setState(() => _previewTemplateIndex = newIdx);
                  ref.read(resumeProvider.notifier).updateTemplateId(_allTemplateIds[newIdx]);
                },
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_allTemplateIds.length, (i) {
                final isSelected = templateId == _allTemplateIds[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(_allTemplateNames[i], style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _previewTemplateIndex = i);
                        ref.read(resumeProvider.notifier).updateTemplateId(_allTemplateIds[i]);
                      }
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Sub-Widget Section Components to maintain code clarity
// ----------------------------------------------------

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// Personal Info Form
class PersonalInfoSection extends ConsumerStatefulWidget {
  const PersonalInfoSection({super.key});

  @override
  ConsumerState<PersonalInfoSection> createState() => _PersonalInfoSectionState();
}

class _PersonalInfoSectionState extends ConsumerState<PersonalInfoSection> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _locationController;
  late TextEditingController _summaryController;
  late TextEditingController _githubController;

  @override
  void initState() {
    super.initState();
    final data = ref.read(resumeProvider).personalInfo;
    _nameController = TextEditingController(text: data.fullName);
    _emailController = TextEditingController(text: data.email);
    _phoneController = TextEditingController(text: data.phoneNumber);
    _websiteController = TextEditingController(text: data.website);
    _locationController = TextEditingController(text: data.location);
    _summaryController = TextEditingController(text: data.summary);
    _githubController = TextEditingController(text: data.github);
  }

  void _syncState() {
    ref.read(resumeProvider.notifier).updatePersonalInfo(
          PersonalInfo(
            fullName: _nameController.text,
            email: _emailController.text,
            phoneNumber: _phoneController.text,
            website: _websiteController.text,
            location: _locationController.text,
            summary: _summaryController.text,
            github: _githubController.text,
          ),
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    _summaryController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for external AI optimization updates to controllers
    ref.listen<ResumeData>(resumeProvider, (previous, next) {
      final oldSummary = previous?.personalInfo.summary;
      final newSummary = next.personalInfo.summary;
      if (oldSummary != newSummary && _summaryController.text != newSummary) {
        _summaryController.text = newSummary;
      }
      
      final oldName = previous?.personalInfo.fullName;
      final newName = next.personalInfo.fullName;
      if (oldName != newName && _nameController.text != newName) {
        _nameController.text = newName;
      }

      final oldGithub = previous?.personalInfo.github;
      final newGithub = next.personalInfo.github;
      if (oldGithub != newGithub && _githubController.text != newGithub) {
        _githubController.text = newGithub;
      }
    });

    return SectionCard(
      title: 'Contact Information',
      icon: Icons.person_outline_rounded,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full Name'),
            onChanged: (_) => _syncState(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  onChanged: (_) => _syncState(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  onChanged: (_) => _syncState(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location (e.g. San Francisco, CA)'),
                  onChanged: (_) => _syncState(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(labelText: 'Website/LinkedIn'),
                  onChanged: (_) => _syncState(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _githubController,
            decoration: const InputDecoration(labelText: 'GitHub Profile URL'),
            onChanged: (_) => _syncState(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile Summary',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              TextButton.icon(
                onPressed: () => _showSummarySuggestions(context),
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Suggest Summaries', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _summaryController,
            decoration: const InputDecoration(
              hintText: 'Brief summary of your professional background...',
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            onChanged: (_) => _syncState(),
          ),
        ],
      ),
    );
  }

  void _showSummarySuggestions(BuildContext context) {
    final currentData = ref.read(resumeProvider);
    final suggestions = SummarySuggestionEngine.getSuggestions(currentData);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    'AI-Selected Summary Examples',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Based on your skills & experience, here are recommended summaries:',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: suggestions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = suggestions[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _summaryController.text = item.text;
                          });
                          _syncState();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Summary applied!')),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.category,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.text,
                                style: const TextStyle(fontSize: 12.5, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Work Experience List
class WorkExperienceSection extends ConsumerWidget {
  const WorkExperienceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only rebuild when items are added/removed, not when text in items changes
    final list = ref.watch(resumeProvider.select((r) => r.workExperience));

    return SectionCard(
      title: 'Work Experience',
      icon: Icons.work_outline_rounded,
      child: Column(
        children: [
          ...list.asMap().entries.map((entry) {
            final idx = entry.key;
            final exp = entry.value;
            return WorkExperienceItem(key: ValueKey('work_$idx'), index: idx, experience: exp);
          }),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () {
              ref.read(resumeProvider.notifier).addWorkExperience();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Work Experience'),
          ),
        ],
      ),
    );
  }
}

class WorkExperienceItem extends ConsumerStatefulWidget {
  final int index;
  final WorkExperience experience;

  const WorkExperienceItem({
    super.key,
    required this.index,
    required this.experience,
  });

  @override
  ConsumerState<WorkExperienceItem> createState() => _WorkExperienceItemState();
}

class _WorkExperienceItemState extends ConsumerState<WorkExperienceItem> {
  late TextEditingController _companyController;
  late TextEditingController _positionController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(text: widget.experience.company);
    _positionController = TextEditingController(text: widget.experience.position);
    _startController = TextEditingController(text: widget.experience.startDate);
    _endController = TextEditingController(text: widget.experience.endDate);
    _descController = TextEditingController(text: widget.experience.description);
  }

  @override
  void didUpdateWidget(covariant WorkExperienceItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.experience != widget.experience) {
      if (_companyController.text != widget.experience.company) _companyController.text = widget.experience.company;
      if (_positionController.text != widget.experience.position) _positionController.text = widget.experience.position;
      if (_startController.text != widget.experience.startDate) _startController.text = widget.experience.startDate;
      if (_endController.text != widget.experience.endDate) _endController.text = widget.experience.endDate;
      if (_descController.text != widget.experience.description) _descController.text = widget.experience.description;
    }
  }

  void _syncState() {
    ref.read(resumeProvider.notifier).updateWorkExperience(
          widget.index,
          WorkExperience(
            company: _companyController.text,
            position: _positionController.text,
            startDate: _startController.text,
            endDate: _endController.text,
            description: _descController.text,
          ),
        );
  }

  @override
  void dispose() {
    _companyController.dispose();
    _positionController.dispose();
    _startController.dispose();
    _endController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Watch for AI optimization updates to descriptions
    ref.listen<ResumeData>(resumeProvider, (previous, next) {
      if (next.workExperience.length > widget.index) {
        final newDesc = next.workExperience[widget.index].description;
        if (_descController.text != newDesc) {
          _descController.text = newDesc;
        }
      }
    });

    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Entry #${widget.index + 1}',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                  onPressed: () {
                    ref.read(resumeProvider.notifier).removeWorkExperience(widget.index);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(labelText: 'Company/Organization'),
                    onChanged: (_) => _syncState(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _positionController,
                    decoration: const InputDecoration(labelText: 'Role/Position'),
                    onChanged: (_) => _syncState(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startController,
                    decoration: const InputDecoration(labelText: 'Start Date (e.g. Jan 2024)'),
                    onChanged: (_) => _syncState(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _endController,
                    decoration: const InputDecoration(labelText: 'End Date (or Present)'),
                    onChanged: (_) => _syncState(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Roles & Achievements (Bullet Points)',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              onChanged: (_) => _syncState(),
            ),
          ],
        ),
      ),
    );
  }
}

// Education List
class EducationSection extends ConsumerWidget {
  const EducationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(resumeProvider.select((r) => r.education));

    return SectionCard(
      title: 'Education',
      icon: Icons.school_outlined,
      child: Column(
        children: [
          ...list.asMap().entries.map((entry) {
            final idx = entry.key;
            final edu = entry.value;
            return EducationItem(key: ValueKey('edu_$idx'), index: idx, education: edu);
          }),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () {
              ref.read(resumeProvider.notifier).addEducation();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Education'),
          ),
        ],
      ),
    );
  }
}

class EducationItem extends ConsumerStatefulWidget {
  final int index;
  final Education education;

  const EducationItem({
    super.key,
    required this.index,
    required this.education,
  });

  @override
  ConsumerState<EducationItem> createState() => _EducationItemState();
}

class _EducationItemState extends ConsumerState<EducationItem> {
  late TextEditingController _instController;
  late TextEditingController _degController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late TextEditingController _gpaController;

  @override
  void initState() {
    super.initState();
    _instController = TextEditingController(text: widget.education.institution);
    _degController = TextEditingController(text: widget.education.degree);
    _startController = TextEditingController(text: widget.education.startDate);
    _endController = TextEditingController(text: widget.education.endDate);
    _gpaController = TextEditingController(text: widget.education.gpa);
  }

  @override
  void didUpdateWidget(covariant EducationItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.education != widget.education) {
      if (_instController.text != widget.education.institution) _instController.text = widget.education.institution;
      if (_degController.text != widget.education.degree) _degController.text = widget.education.degree;
      if (_startController.text != widget.education.startDate) _startController.text = widget.education.startDate;
      if (_endController.text != widget.education.endDate) _endController.text = widget.education.endDate;
      if (_gpaController.text != widget.education.gpa) _gpaController.text = widget.education.gpa;
    }
  }

  void _syncState() {
    ref.read(resumeProvider.notifier).updateEducation(
          widget.index,
          Education(
            institution: _instController.text,
            degree: _degController.text,
            startDate: _startController.text,
            endDate: _endController.text,
            gpa: _gpaController.text,
          ),
        );
  }

  @override
  void dispose() {
    _instController.dispose();
    _degController.dispose();
    _startController.dispose();
    _endController.dispose();
    _gpaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Entry #${widget.index + 1}',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                  onPressed: () {
                    ref.read(resumeProvider.notifier).removeEducation(widget.index);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _instController,
              decoration: const InputDecoration(labelText: 'Institution/University'),
              onChanged: (_) => _syncState(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _degController,
              decoration: const InputDecoration(labelText: 'Degree/Field of Study'),
              onChanged: (_) => _syncState(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startController,
                    decoration: const InputDecoration(labelText: 'Start Date'),
                    onChanged: (_) => _syncState(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _endController,
                    decoration: const InputDecoration(labelText: 'End Date'),
                    onChanged: (_) => _syncState(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _gpaController,
                    decoration: const InputDecoration(labelText: 'GPA'),
                    onChanged: (_) => _syncState(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Skills List Form
class SkillsSection extends ConsumerWidget {
  const SkillsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(resumeProvider.select((r) => r.skills));

    return SectionCard(
      title: 'Professional Skills',
      icon: Icons.code_rounded,
      child: Column(
        children: [
          ...list.asMap().entries.map((entry) {
            final idx = entry.key;
            final skill = entry.value;
            return SkillItem(key: ValueKey('skill_$idx'), index: idx, skill: skill);
          }),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () {
              ref.read(resumeProvider.notifier).addSkill();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Skill'),
          ),
        ],
      ),
    );
  }
}

class SkillItem extends ConsumerStatefulWidget {
  final int index;
  final Skill skill;

  const SkillItem({
    super.key,
    required this.index,
    required this.skill,
  });

  @override
  ConsumerState<SkillItem> createState() => _SkillItemState();
}

class _SkillItemState extends ConsumerState<SkillItem> {
  late TextEditingController _nameController;
  late TextEditingController _proficiencyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.skill.name);
    _proficiencyController = TextEditingController(text: widget.skill.proficiency);
  }

  @override
  void didUpdateWidget(covariant SkillItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skill != widget.skill) {
      if (_nameController.text != widget.skill.name) _nameController.text = widget.skill.name;
      if (_proficiencyController.text != widget.skill.proficiency) _proficiencyController.text = widget.skill.proficiency;
    }
  }

  void _syncState() {
    ref.read(resumeProvider.notifier).updateSkill(
          widget.index,
          Skill(
            name: _nameController.text,
            proficiency: _proficiencyController.text,
          ),
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _proficiencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Skill (e.g. Flutter)',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (_) => _syncState(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _proficiencyController,
                decoration: const InputDecoration(
                  labelText: 'Proficiency (e.g. Expert)',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (_) => _syncState(),
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
              onPressed: () {
                ref.read(resumeProvider.notifier).removeSkill(widget.index);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Target Job Description Form
class TargetJobSection extends ConsumerStatefulWidget {
  const TargetJobSection({super.key});

  @override
  ConsumerState<TargetJobSection> createState() => _TargetJobSectionState();
}

class _TargetJobSectionState extends ConsumerState<TargetJobSection> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final data = ref.read(resumeProvider);
    _controller = TextEditingController(text: data.targetJobDescription);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Target Job Description',
      icon: Icons.track_changes_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paste the description of the job you are applying for. The AI assistant uses this context to calculate ATS keyword matches and optimize summary alignments.',
            style: TextStyle(fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Target Job Description',
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            onChanged: (val) {
              ref.read(resumeProvider.notifier).updateTargetJobDescription(val);
            },
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Visual Template Selector Component
// -------------------------------------------------------------
class TemplateSelectorCard extends ConsumerWidget {
  const TemplateSelectorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTemplateId = ref.watch(resumeProvider.select((r) => r.templateId));
    final theme = Theme.of(context);

    final templates = [
      {'id': 'modern_indigo', 'name': 'Modern Indigo', 'icon': Icons.palette_outlined},
      {'id': 'minimalist_executive', 'name': 'Minimalist', 'icon': Icons.business_center_outlined},
      {'id': 'tech_professional', 'name': 'Tech Monospace', 'icon': Icons.code_rounded},
      {'id': 'classic_elegance', 'name': 'Classic Serif', 'icon': Icons.menu_book_rounded},
      {'id': 'two_column_sidebar', 'name': 'Two-Column Sidebar', 'icon': Icons.view_sidebar_rounded},
      {'id': 'creative_bold', 'name': 'Creative Bold', 'icon': Icons.format_bold_rounded},
      {'id': 'ats_clean', 'name': 'ATS Clean', 'icon': Icons.check_circle_outline_rounded},
      {'id': 'executive_formal', 'name': 'Executive Formal', 'icon': Icons.workspace_premium_rounded},
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard_customize_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Select Resume Style Template',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: templates.map((tpl) {
                  final isSelected = currentTemplateId == tpl['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(tpl['name'] as String),
                      avatar: Icon(tpl['icon'] as IconData, size: 16),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(resumeProvider.notifier).updateTemplateId(tpl['id'] as String);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// ATS Progress Tracker Component
// -------------------------------------------------------------
class AtsCompletenessTracker extends ConsumerStatefulWidget {
  const AtsCompletenessTracker({super.key});

  @override
  ConsumerState<AtsCompletenessTracker> createState() => _AtsCompletenessTrackerState();
}

class _AtsCompletenessTrackerState extends ConsumerState<AtsCompletenessTracker> {
  double _progress = 0.0;
  int _percentage = 0;
  Color _progressColor = Colors.redAccent;
  String _rankLabel = 'Draft (Incomplete)';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Compute initial score once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _computeScore(ref.read(resumeProvider));
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _computeScore(ResumeData resume) {
    double score = 0.0;
    if (resume.personalInfo.fullName.isNotEmpty) score += 0.10;
    if (resume.personalInfo.email.isNotEmpty) score += 0.05;
    if (resume.personalInfo.phoneNumber.isNotEmpty) score += 0.05;
    if (resume.personalInfo.location.isNotEmpty) score += 0.05;
    if (resume.personalInfo.website.isNotEmpty || resume.personalInfo.github.isNotEmpty) score += 0.05;
    if (resume.personalInfo.summary.isNotEmpty) score += 0.15;
    if (resume.workExperience.isNotEmpty) {
      score += 0.15;
      if (resume.workExperience.any((e) => e.description.isNotEmpty && e.description.length > 20)) {
        score += 0.10;
      }
    }
    if (resume.education.isNotEmpty) score += 0.15;
    if (resume.skills.length >= 3) {
      score += 0.15;
    } else {
      score += (resume.skills.length * 0.05);
    }
    if (resume.projects.isNotEmpty) score += 0.05;

    final progress = score.clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    Color progressColor;
    String rankLabel;
    if (progress < 0.4) {
      progressColor = Colors.redAccent;
      rankLabel = 'Draft (Incomplete)';
    } else if (progress < 0.75) {
      progressColor = Colors.orangeAccent;
      rankLabel = 'Good (Needs Work)';
    } else {
      progressColor = Colors.green;
      rankLabel = 'ATS Optimized (Ready!)';
    }

    if (mounted) {
      setState(() {
        _progress = progress;
        _percentage = percentage;
        _progressColor = progressColor;
        _rankLabel = rankLabel;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Debounce: only recompute score 600ms after the last state change
    ref.listen<ResumeData>(resumeProvider, (_, next) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 600), () {
        _computeScore(next);
      });
    });

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.assessment_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'ATS Profile Completeness',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '$_percentage%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: _progressColor,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Completeness Tier:',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  _rankLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _progressColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Projects Section Editor Component
// -------------------------------------------------------------
class ProjectsSection extends ConsumerWidget {
  const ProjectsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(resumeProvider.select((r) => r.projects));

    return SectionCard(
      title: 'Projects',
      icon: Icons.rocket_launch_outlined,
      child: Column(
        children: [
          ...list.asMap().entries.map((entry) {
            final idx = entry.key;
            final proj = entry.value;
            return ProjectItem(key: ValueKey('proj_$idx'), index: idx, project: proj);
          }),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () {
              ref.read(resumeProvider.notifier).addProject();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Project'),
          ),
        ],
      ),
    );
  }
}

class ProjectItem extends ConsumerStatefulWidget {
  final int index;
  final Project project;

  const ProjectItem({
    super.key,
    required this.index,
    required this.project,
  });

  @override
  ConsumerState<ProjectItem> createState() => _ProjectItemState();
}

class _ProjectItemState extends ConsumerState<ProjectItem> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _linkController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descController = TextEditingController(text: widget.project.description);
    _linkController = TextEditingController(text: widget.project.link);
  }

  @override
  void didUpdateWidget(covariant ProjectItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project != widget.project) {
      if (_nameController.text != widget.project.name) _nameController.text = widget.project.name;
      if (_descController.text != widget.project.description) _descController.text = widget.project.description;
      if (_linkController.text != widget.project.link) _linkController.text = widget.project.link;
    }
  }

  void _syncState() {
    ref.read(resumeProvider.notifier).updateProject(
          widget.index,
          Project(
            name: _nameController.text,
            description: _descController.text,
            link: _linkController.text,
          ),
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Project #${widget.index + 1}',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                  onPressed: () {
                    ref.read(resumeProvider.notifier).removeProject(widget.index);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Project Name'),
              onChanged: (_) => _syncState(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(labelText: 'Project Link (e.g. GitHub URL)'),
              onChanged: (_) => _syncState(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Project Description / Tech Stack',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              onChanged: (_) => _syncState(),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Custom Sections Editor Component
// -------------------------------------------------------------
class CustomSectionsSection extends ConsumerWidget {
  const CustomSectionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(resumeProvider.select((r) => r.customSections));

    return SectionCard(
      title: 'Custom Sections',
      icon: Icons.dashboard_customize_outlined,
      child: Column(
        children: [
          ...list.asMap().entries.map((entry) {
            final idx = entry.key;
            final sec = entry.value;
            return CustomSectionItem(key: ValueKey('custom_${sec.id}'), index: idx, section: sec);
          }),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () {
              ref.read(resumeProvider.notifier).addCustomSection();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Custom Section'),
          ),
        ],
      ),
    );
  }
}

class CustomSectionItem extends ConsumerStatefulWidget {
  final int index;
  final CustomSection section;

  const CustomSectionItem({
    super.key,
    required this.index,
    required this.section,
  });

  @override
  ConsumerState<CustomSectionItem> createState() => _CustomSectionItemState();
}

class _CustomSectionItemState extends ConsumerState<CustomSectionItem> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.section.title);
    _contentController = TextEditingController(text: widget.section.content);
  }

  @override
  void didUpdateWidget(covariant CustomSectionItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      if (_titleController.text != widget.section.title) _titleController.text = widget.section.title;
      if (_contentController.text != widget.section.content) _contentController.text = widget.section.content;
    }
  }

  void _syncState() {
    ref.read(resumeProvider.notifier).updateCustomSection(
          widget.index,
          CustomSection(
            id: widget.section.id,
            title: _titleController.text,
            content: _contentController.text,
          ),
        );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Custom Section #${widget.index + 1}',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                  onPressed: () {
                    ref.read(resumeProvider.notifier).removeCustomSection(widget.index);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Section Title (e.g. Certifications)'),
              onChanged: (_) => _syncState(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Section Content (Markdown/Bullets)',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              onChanged: (_) => _syncState(),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    final text = _contentController.text;
                    final selection = _contentController.selection;
                    final bullet = text.isEmpty || text.endsWith('\n') ? '• ' : '\n• ';
                    
                    String newText;
                    int newCursorPos;
                    
                    if (selection.isValid && selection.start >= 0) {
                      newText = text.replaceRange(selection.start, selection.end, bullet);
                      newCursorPos = selection.start + bullet.length;
                    } else {
                      newText = text + bullet;
                      newCursorPos = newText.length;
                    }
                    
                    _contentController.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(offset: newCursorPos),
                    );
                    _syncState();
                  },
                  icon: const Icon(Icons.format_list_bulleted_rounded, size: 14),
                  label: const Text('Add Bullet Point', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Import / Export JSON Utility Panel
// -------------------------------------------------------------
class ImportExportCard extends ConsumerWidget {
  const ImportExportCard({super.key});

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Resume Data'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paste your exported Resume JSON string here. This will completely overwrite your current editing session.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Resume JSON',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              try {
                final Map<String, dynamic> data = jsonDecode(controller.text);
                final resumeData = ResumeData.fromJson(data);
                ref.read(resumeProvider.notifier).loadResumeData(resumeData);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Resume data imported successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to parse JSON: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  String _buildParsePrompt(String text) {
    return '''
Parse the following resume text and extract the information into a structured JSON format matching this exact schema. If any information is missing, leave the string empty or the array empty.

Schema:
{
  "personalInfo": {
    "fullName": "First and Last Name",
    "email": "Email Address",
    "phoneNumber": "Phone Number",
    "location": "City, State or full address",
    "website": "Personal website or portfolio",
    "github": "GitHub profile URL",
    "summary": "A professional summary or objective statement (extract this carefully, it's often at the top)"
  },
  "targetJob": "Target Job Title (if mentioned)",
  "workExperience": [
    {
      "company": "Company Name",
      "position": "Job Title",
      "startDate": "Start Date",
      "endDate": "End Date or Present",
      "description": "Responsibilities and achievements (can use bullet points starting with •)"
    }
  ],
  "education": [
    {
      "institution": "School/University Name",
      "degree": "Degree and Major",
      "startDate": "Start Date",
      "endDate": "End Date",
      "gpa": "GPA (if specified)"
    }
  ],
  "skills": [
    {
      "name": "Skill Name",
      "proficiency": "e.g. Expert, Intermediate, Beginner"
    }
  ],
  "projects": [
    {
      "name": "Project Name",
      "description": "Short description of the project",
      "link": "Project URL or GitHub link"
    }
  ],
  "customSections": [
    {
      "id": "unique_section_id",
      "title": "Section Title (e.g. Certifications, Languages)",
      "content": "Content of the section, can use newlines and bullet points starting with •"
    }
  ]
}

Ensure:
1. ONLY return a valid JSON object. Do not include markdown code block syntax (like ```json) or any conversational introduction/conclusion.
2. If fields are not found in the raw text, leave them as empty strings "" or empty lists [].
3. For customSections, dynamically create sections for any extra information found in the resume that doesn't fit standard categories (e.g., Certifications, Languages, Publications, Awards). Generate a clean lowercase ID with underscores for each custom section (e.g., "certifications", "languages").

Raw Resume Text to Parse:
$text
''';
  }

  void _showAiExtractorDialog(BuildContext context, WidgetRef ref) {
    final client = ref.read(geminiClientProvider);
    final textController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;
    
    showDialog(
      context: context,
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
                      'Paste the raw text of your existing resume below. Gemini will extract your personal details, work history, education, skills, and projects, and load them into the builder automatically.',
                      style: TextStyle(fontSize: 12, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    if (!client.isConfigured) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Gemini API Key is not configured. Please configure your API key in the AI Assistant Panel (top-right wizard) to use this feature.',
                                style: TextStyle(fontSize: 11, height: 1.3, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(fontSize: 11, color: Colors.red.shade900),
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
                              Text('AI is parsing your resume...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      )
                    else
                      TextFormField(
                        controller: textController,
                        maxLines: 12,
                        enabled: client.isConfigured,
                        decoration: const InputDecoration(
                          labelText: 'Paste raw resume text here',
                          alignLabelWithHint: true,
                          hintText: 'John Doe\njohn.doe@email.com\n\nExperience:\nSenior Developer at Google...',
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

                            setState(() {
                              isLoading = true;
                              errorMessage = 'Extracting from PDF...';
                            });

                            ResumeData parsedData = ref.read(resumeProvider);
                            try {
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
                                setState(() {
                                  isLoading = false;
                                  errorMessage = 'PDF parsing failed: $e';
                                });
                                return;
                            }

                            if (context.mounted) {
                              ref.read(resumeProvider.notifier).loadResumeData(parsedData);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Resume data parsed from PDF successfully!')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: const Text('Upload PDF'),
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
              if (client.isConfigured)
                FilledButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final text = textController.text.trim();
                          if (text.isEmpty) {
                            setState(() {
                              errorMessage = 'Please paste some text to parse.';
                            });
                            return;
                          }
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            final prompt = '''
You are an expert resume parsing system. Your task is to extract all information from the provided raw resume text and format it into a structured JSON matching the database schema.

Here is the exact JSON structure required:
{
  "personalInfo": {
    "fullName": "Name",
    "email": "Email",
    "phoneNumber": "Phone number",
    "website": "Personal website or portfolio",
    "location": "City, State or Country",
    "summary": "Short professional summary",
    "github": "Github URL"
  },
  "workExperience": [
    {
      "company": "Company Name",
      "position": "Job Title",
      "startDate": "Start Date",
      "endDate": "End Date or Present",
      "description": "Responsibilities and achievements (can use bullet points starting with •)"
    }
  ],
  "education": [
    {
      "institution": "School/University Name",
      "degree": "Degree and Major",
      "startDate": "Start Date",
      "endDate": "End Date",
      "gpa": "GPA (if specified)"
    }
  ],
  "skills": [
    {
      "name": "Skill Name",
      "proficiency": "e.g. Expert, Intermediate, Beginner"
    }
  ],
  "projects": [
    {
      "name": "Project Name",
      "description": "Short description of the project",
      "link": "Project URL or GitHub link"
    }
  ],
  "customSections": [
    {
      "id": "unique_section_id",
      "title": "Section Title (e.g. Certifications, Languages)",
      "content": "Content of the section, can use newlines and bullet points starting with •"
    }
  ]
}

Ensure:
1. ONLY return a valid JSON object. Do not include markdown code block syntax (like ```json) or any conversational introduction/conclusion.
2. If fields are not found in the raw text, leave them as empty strings "" or empty lists [].
3. For customSections, dynamically create sections for any extra information found in the resume that doesn't fit standard categories (e.g., Certifications, Languages, Publications, Awards). Generate a clean lowercase ID with underscores for each custom section (e.g., "certifications", "languages").

Raw Resume Text to Parse:
$text
''';
                            final responseText = await client.generateText(prompt: prompt);
                            
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

                            final Map<String, dynamic> data = jsonDecode(cleanJson);
                            final parsedData = ResumeData.fromJson(data);

                            ref.read(resumeProvider.notifier).loadResumeData(parsedData);

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('AI parsed and loaded your resume successfully!')),
                              );
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                              errorMessage = 'AI parsing failed: $e. Make sure you provided a valid API key and try again.';
                            });
                          }
                        },
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Parse Resume'),
                ),
            ],
          );
        },
      ),
    );
  }

  void _exportResume(BuildContext context, WidgetRef ref) {
    final resume = ref.read(resumeProvider);
    final jsonString = jsonEncode(resume.toJson());
    
    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: jsonString));
    
    // Download file using the cross-platform conditional export helper
    final fileName = '${resume.personalInfo.fullName.isNotEmpty ? resume.personalInfo.fullName.replaceAll(' ', '_') : 'My'}_Resume_Data.json';
    downloadJsonFile(jsonString, fileName);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('JSON downloaded and copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.backup_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Backup & Restore',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Export JSON'),
                    onPressed: () => _exportResume(context, ref),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text('Import JSON'),
                    onPressed: () => _showImportDialog(context, ref),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Extract & Import Resume using AI'),
                onPressed: () => _showAiExtractorDialog(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
