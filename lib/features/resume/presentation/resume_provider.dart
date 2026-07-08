import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resumate/core/utils/pdf_generator.dart';
import 'package:resumate/features/resume/domain/resume_model.dart';

class ResumeNotifier extends Notifier<ResumeData> {
  static const _prefsKey = 'saved_resume_data';
  Timer? _saveTimer;

  @override
  ResumeData build() {
    _loadFromPrefs();
    return ResumeData.demo();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_prefsKey);
      if (rawJson != null) {
        final Map<String, dynamic> data = json.decode(rawJson);
        state = ResumeData.fromJson(data);
        debugPrint('Resume data loaded from local storage successfully.');
      }
    } catch (e) {
      debugPrint('Failed to load local resume data: $e');
    }
  }

  void _saveToPrefs(ResumeData current) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsKey, json.encode(current.toJson()));
      } catch (e) {
        debugPrint('Failed to persist resume data: $e');
      }
    });
  }

  void updatePersonalInfo(PersonalInfo info) {
    state = state.copyWith(personalInfo: info);
    _saveToPrefs(state);
  }

  void updateWorkExperience(int index, WorkExperience exp) {
    final list = List<WorkExperience>.from(state.workExperience);
    if (index >= 0 && index < list.length) {
      list[index] = exp;
      state = state.copyWith(workExperience: list);
      _saveToPrefs(state);
    }
  }

  void addWorkExperience() {
    final list = List<WorkExperience>.from(state.workExperience);
    list.add(WorkExperience(
      company: '',
      position: '',
      startDate: '',
      endDate: '',
      description: '',
    ));
    state = state.copyWith(workExperience: list);
    _saveToPrefs(state);
  }

  void removeWorkExperience(int index) {
    final list = List<WorkExperience>.from(state.workExperience);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      state = state.copyWith(workExperience: list);
      _saveToPrefs(state);
    }
  }

  void updateEducation(int index, Education edu) {
    final list = List<Education>.from(state.education);
    if (index >= 0 && index < list.length) {
      list[index] = edu;
      state = state.copyWith(education: list);
      _saveToPrefs(state);
    }
  }

  void addEducation() {
    final list = List<Education>.from(state.education);
    list.add(Education(
      institution: '',
      degree: '',
      startDate: '',
      endDate: '',
      gpa: '',
    ));
    state = state.copyWith(education: list);
    _saveToPrefs(state);
  }

  void removeEducation(int index) {
    final list = List<Education>.from(state.education);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      state = state.copyWith(education: list);
      _saveToPrefs(state);
    }
  }

  void updateSkill(int index, Skill skill) {
    final list = List<Skill>.from(state.skills);
    if (index >= 0 && index < list.length) {
      list[index] = skill;
      state = state.copyWith(skills: list);
      _saveToPrefs(state);
    }
  }

  void addSkill() {
    final list = List<Skill>.from(state.skills);
    list.add(Skill(name: '', proficiency: ''));
    state = state.copyWith(skills: list);
    _saveToPrefs(state);
  }

  void removeSkill(int index) {
    final list = List<Skill>.from(state.skills);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      state = state.copyWith(skills: list);
      _saveToPrefs(state);
    }
  }

  void updateTargetJobDescription(String desc) {
    state = state.copyWith(targetJobDescription: desc);
    _saveToPrefs(state);
  }

  void updateProject(int index, Project proj) {
    final list = List<Project>.from(state.projects);
    if (index >= 0 && index < list.length) {
      list[index] = proj;
      state = state.copyWith(projects: list);
      _saveToPrefs(state);
    }
  }

  void addProject() {
    final list = List<Project>.from(state.projects);
    list.add(Project(name: '', description: '', link: ''));
    state = state.copyWith(projects: list);
    _saveToPrefs(state);
  }

  void removeProject(int index) {
    final list = List<Project>.from(state.projects);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      state = state.copyWith(projects: list);
      _saveToPrefs(state);
    }
  }

  void updateCustomSection(int index, CustomSection sec) {
    final list = List<CustomSection>.from(state.customSections);
    if (index >= 0 && index < list.length) {
      list[index] = sec;
      state = state.copyWith(customSections: list);
      _saveToPrefs(state);
    }
  }

  void addCustomSection() {
    final list = List<CustomSection>.from(state.customSections);
    final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    list.add(CustomSection(id: newId, title: 'New Section', content: ''));
    
    final order = List<String>.from(state.sectionOrder);
    order.add(newId);

    state = state.copyWith(customSections: list, sectionOrder: order);
    _saveToPrefs(state);
  }

  void removeCustomSection(int index) {
    final list = List<CustomSection>.from(state.customSections);
    if (index >= 0 && index < list.length) {
      final removed = list.removeAt(index);
      
      final order = List<String>.from(state.sectionOrder)..remove(removed.id);

      state = state.copyWith(customSections: list, sectionOrder: order);
      _saveToPrefs(state);
    }
  }

  void updateTemplateId(String templateId) {
    state = state.copyWith(templateId: templateId);
    _saveToPrefs(state);
  }

  void updateSectionOrder(List<String> order) {
    state = state.copyWith(sectionOrder: order);
    _saveToPrefs(state);
  }

  void loadResumeData(ResumeData data) {
    state = data;
    _saveToPrefs(state);
  }
}

final resumeProvider = NotifierProvider<ResumeNotifier, ResumeData>(() {
  return ResumeNotifier();
});

// Debounced provider for reactive rendering of the PDF Preview.
// This allows immediate form responses while preventing CPU spikes during rapid keystrokes.
final pdfBytesProvider = FutureProvider<Uint8List>((ref) async {
  final resumeData = ref.watch(resumeProvider);
  
  bool isCancelled = false;
  ref.onDispose(() => isCancelled = true);

  // Wait for 800ms. If resumeData changes, Riverpod will automatically discard the previous future and re-run.
  await Future.delayed(const Duration(milliseconds: 800));
  
  if (isCancelled) {
    throw Exception('Debounced/Cancelled by newer keystroke');
  }
  
  // Run heavy PDF layout in background isolate to keep UI smooth
  return compute(PdfGenerator.generate, resumeData);
});
