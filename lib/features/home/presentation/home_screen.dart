import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:resumate/core/theme/theme_provider.dart';
import 'package:resumate/core/utils/backup_service.dart';
import 'package:resumate/features/auth/presentation/auth_provider.dart';
import 'package:resumate/features/home/presentation/resume_list_provider.dart';
import 'package:resumate/features/resume/domain/resume_model.dart';
import 'package:resumate/features/templates/presentation/template_selection_screen.dart';
import 'package:resumate/features/resume/presentation/workspace_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isNavigating = false;
  
  @override
  void initState() {
    super.initState();
    // Migrate legacy single-resume data on first launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(resumeListProvider.notifier).migrateLegacyData();
    });
  }

  Future<void> _exportBackup(BuildContext context) async {
    final resumes = ref.read(resumeListProvider);
    if (resumes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No resumes available to export.')),
      );
      return;
    }

    final backupJson = BackupService.exportBackup(resumes);
    final filename = 'resumate_backup_${DateTime.now().millisecondsSinceEpoch}.resumate';
    await Printing.sharePdf(
      bytes: Uint8List.fromList(utf8.encode(backupJson)),
      filename: filename,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported ${resumes.length} resumes to backup file!')),
      );
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String content = '';
        if (file.bytes != null) {
          content = utf8.decode(file.bytes!);
        } else if (file.path != null) {
          final f = File(file.path!);
          content = await f.readAsString();
        }

        if (content.trim().isNotEmpty) {
          final restored = BackupService.importBackup(content);
          final importedCount = ref.read(resumeListProvider.notifier).importResumes(restored);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Successfully restored $importedCount resumes!')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resumes = ref.watch(resumeListProvider);
    final authUser = ref.watch(authProvider).value;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Premium App Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                ),
                onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.swap_vert_circle_outlined),
                tooltip: 'Backup & Restore',
                onSelected: (val) {
                  if (val == 'export_backup') {
                    _exportBackup(context);
                  } else if (val == 'import_backup') {
                    _importBackup(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export_backup',
                    child: Row(
                      children: [
                        Icon(Icons.upload_file_rounded, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Export Backup (JSON)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'import_backup',
                    child: Row(
                      children: [
                        Icon(Icons.download_for_offline_rounded, size: 18, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Import Backup (Restore)'),
                      ],
                    ),
                  ),
                ],
              ),
              if (authUser != null)
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'logout') {
                      ref.read(authProvider.notifier).signOut();
                    }
                  },
                  offset: const Offset(0, 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                            theme.colorScheme.surface,
                          ]
                        : [
                            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                            theme.colorScheme.surface,
                          ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ResuMate',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'AI-Powered • ATS-Optimized • Beautiful',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
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
              ),
            ),
          ),

          // Action Cards
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.add_circle_rounded,
                      title: 'Start from\nScratch',
                      subtitle: 'Choose a template',
                      gradient: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.7),
                      ],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TemplateSelectionScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Import with\nAI',
                      subtitle: 'From existing resume',
                      gradient: [
                        theme.colorScheme.tertiary,
                        theme.colorScheme.tertiary.withValues(alpha: 0.7),
                      ],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TemplateSelectionScreen(startWithImport: true),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // My Resumes Header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Icon(Icons.folder_rounded,
                      color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'My Resumes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${resumes.length} resume${resumes.length != 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Resume List or Empty State
          if (resumes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Resumes Yet',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start from scratch or import with AI to build your perfect resume.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final resume = resumes[index];
                    return _ResumeListTile(
                      resume: resume,
                      onTap: () => _openResume(context, resume.id),
                      onRename: () => _showRenameDialog(context, resume),
                      onDuplicate: () => ref.read(resumeListProvider.notifier).duplicateResume(resume.id),
                      onDelete: () => _confirmDelete(context, resume),
                    );
                  },
                  childCount: resumes.length,
                ),
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  void _openResume(BuildContext context, String resumeId) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkspaceScreen(resumeId: resumeId),
      ),
    );
    
    if (mounted) {
      setState(() => _isNavigating = false);
    }
  }

  void _showRenameDialog(BuildContext context, SavedResume resume) {
    final controller = TextEditingController(text: resume.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Resume'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Resume Name',
            hintText: 'e.g. Software Developer Resume',
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
              if (newName.isNotEmpty) {
                ref.read(resumeListProvider.notifier).renameResume(resume.id, newName);
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

  void _confirmDelete(BuildContext context, SavedResume resume) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Resume?'),
        content: Text('Are you sure you want to delete "${resume.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(resumeListProvider.notifier).deleteResume(resume.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------
// Action Card (Start from Scratch / Import with AI)
// -------------------------------------------------------
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: gradient.first.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------
// Resume List Tile
// -------------------------------------------------------
class _ResumeListTile extends StatelessWidget {
  final SavedResume resume;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _ResumeListTile({
    required this.resume,
    required this.onTap,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
  });

  static const _templateNames = {
    'modern_indigo': 'Modern Indigo',
    'minimalist_executive': 'Minimalist',
    'tech_professional': 'Tech Monospace',
    'classic_elegance': 'Classic Serif',
    'two_column_sidebar': 'Two-Column Sidebar',
    'creative_bold': 'Creative Bold',
    'ats_clean': 'ATS Clean',
    'executive_formal': 'Executive Formal',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modified = resume.lastModified;
    final timeAgo = _formatTimeAgo(modified);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resume.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_templateNames[resume.templateId] ?? resume.templateId} • $timeAgo',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  switch (val) {
                    case 'rename':
                      onRename();
                      break;
                    case 'duplicate':
                      onDuplicate();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Rename'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Duplicate'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: theme.colorScheme.error),
                        const SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: theme.colorScheme.error)),
                      ],
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

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
