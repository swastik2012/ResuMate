import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resume_builder/features/resume/domain/resume_model.dart';

class ResumeListNotifier extends Notifier<List<SavedResume>> {
  static const _prefsKey = 'saved_resume_list';

  @override
  List<SavedResume> build() {
    _loadFromPrefs();
    return [];
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final List<dynamic> list = json.decode(raw);
        state = list.map((e) => SavedResume.fromJson(e)).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        json.encode(state.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  /// Migrate legacy single-resume data into the list on first launch
  Future<void> migrateLegacyData() async {
    if (state.isNotEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('saved_resume_data');
      if (raw != null) {
        final data = ResumeData.fromJson(json.decode(raw));
        final saved = SavedResume(
          id: 'resume_${DateTime.now().millisecondsSinceEpoch}',
          name: data.personalInfo.fullName.isNotEmpty
              ? '${data.personalInfo.fullName}\'s Resume'
              : 'My Resume',
          templateId: data.templateId,
          lastModified: DateTime.now(),
          data: data,
        );
        state = [saved];
        await _saveToPrefs();
      }
    } catch (_) {}
  }

  String createResume({required String templateId, String? name, ResumeData? initialData}) {
    final id = 'resume_${DateTime.now().millisecondsSinceEpoch}';
    final initialName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : (initialData != null && initialData.personalInfo.fullName.isNotEmpty
            ? '${initialData.personalInfo.fullName}\'s Resume'
            : 'Untitled Resume');

    final resume = SavedResume(
      id: id,
      name: initialName,
      templateId: templateId,
      lastModified: DateTime.now(),
      data: (initialData ?? ResumeData()).copyWith(templateId: templateId),
    );
    state = [...state, resume];
    _saveToPrefs();
    return id;
  }

  void renameResume(String id, String newName) {
    state = state.map((r) {
      if (r.id == id) {
        return r.copyWith(
          name: newName.trim().isNotEmpty ? newName.trim() : r.name,
          lastModified: DateTime.now(),
        );
      }
      return r;
    }).toList();
    _saveToPrefs();
  }

  void updateResume(String id, ResumeData data) {
    state = state.map((r) {
      if (r.id == id) {
        final currentName = (r.name == 'Untitled Resume' && data.personalInfo.fullName.isNotEmpty)
            ? '${data.personalInfo.fullName}\'s Resume'
            : r.name;
        return r.copyWith(
          data: data,
          templateId: data.templateId,
          name: currentName,
          lastModified: DateTime.now(),
        );
      }
      return r;
    }).toList();
    _saveToPrefs();
  }

  void deleteResume(String id) {
    state = state.where((r) => r.id != id).toList();
    _saveToPrefs();
  }

  void duplicateResume(String id) {
    final original = state.firstWhere((r) => r.id == id);
    final newId = 'resume_${DateTime.now().millisecondsSinceEpoch}';
    final copy = SavedResume(
      id: newId,
      name: '${original.name} (Copy)',
      templateId: original.templateId,
      lastModified: DateTime.now(),
      data: original.data,
    );
    state = [...state, copy];
    _saveToPrefs();
  }

  SavedResume? getResume(String id) {
    try {
      return state.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}

final resumeListProvider =
    NotifierProvider<ResumeListNotifier, List<SavedResume>>(() {
  return ResumeListNotifier();
});
