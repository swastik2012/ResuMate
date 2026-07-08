class PersonalInfo {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String website;
  final String location;
  final String summary;
  final String github;

  PersonalInfo({
    this.fullName = '',
    this.email = '',
    this.phoneNumber = '',
    this.website = '',
    this.location = '',
    this.summary = '',
    this.github = '',
  });

  PersonalInfo copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? website,
    String? location,
    String? summary,
    String? github,
  }) {
    return PersonalInfo(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      location: location ?? this.location,
      summary: summary ?? this.summary,
      github: github ?? this.github,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'website': website,
      'location': location,
      'summary': summary,
      'github': github,
    };
  }

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      website: json['website'] ?? '',
      location: json['location'] ?? '',
      summary: json['summary'] ?? '',
      github: json['github'] ?? '',
    );
  }
}

class WorkExperience {
  final String company;
  final String position;
  final String startDate;
  final String endDate;
  final String description;

  WorkExperience({
    this.company = '',
    this.position = '',
    this.startDate = '',
    this.endDate = '',
    this.description = '',
  });

  WorkExperience copyWith({
    String? company,
    String? position,
    String? startDate,
    String? endDate,
    String? description,
  }) {
    return WorkExperience(
      company: company ?? this.company,
      position: position ?? this.position,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company': company,
      'position': position,
      'startDate': startDate,
      'endDate': endDate,
      'description': description,
    };
  }

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      company: json['company'] ?? '',
      position: json['position'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class Education {
  final String institution;
  final String degree;
  final String startDate;
  final String endDate;
  final String gpa;

  Education({
    this.institution = '',
    this.degree = '',
    this.startDate = '',
    this.endDate = '',
    this.gpa = '',
  });

  Education copyWith({
    String? institution,
    String? degree,
    String? startDate,
    String? endDate,
    String? gpa,
  }) {
    return Education(
      institution: institution ?? this.institution,
      degree: degree ?? this.degree,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      gpa: gpa ?? this.gpa,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'institution': institution,
      'degree': degree,
      'startDate': startDate,
      'endDate': endDate,
      'gpa': gpa,
    };
  }

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      institution: json['institution'] ?? '',
      degree: json['degree'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      gpa: json['gpa'] ?? '',
    );
  }
}

class Skill {
  final String name;
  final String proficiency;

  Skill({
    this.name = '',
    this.proficiency = '',
  });

  Skill copyWith({
    String? name,
    String? proficiency,
  }) {
    return Skill(
      name: name ?? this.name,
      proficiency: proficiency ?? this.proficiency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'proficiency': proficiency,
    };
  }

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      name: json['name'] ?? '',
      proficiency: json['proficiency'] ?? '',
    );
  }
}

class Project {
  final String name;
  final String description;
  final String link;

  Project({this.name = '', this.description = '', this.link = ''});

  Project copyWith({String? name, String? description, String? link}) {
    return Project(
      name: name ?? this.name,
      description: description ?? this.description,
      link: link ?? this.link,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'link': link,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        link: json['link'] ?? '',
      );
}

class CustomSection {
  final String id;
  final String title;
  final String content;

  CustomSection({required this.id, required this.title, required this.content});

  CustomSection copyWith({String? id, String? title, String? content}) {
    return CustomSection(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
      };

  factory CustomSection.fromJson(Map<String, dynamic> json) => CustomSection(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
      );
}

class ResumeData {
  final PersonalInfo personalInfo;
  final List<WorkExperience> workExperience;
  final List<Education> education;
  final List<Skill> skills;
  final List<Project> projects;
  final List<CustomSection> customSections;
  final List<String> sectionOrder;
  final String templateId;
  final String targetJobDescription;
  final bool forceOnePage;

  ResumeData({
    PersonalInfo? personalInfo,
    List<WorkExperience>? workExperience,
    List<Education>? education,
    List<Skill>? skills,
    List<Project>? projects,
    List<CustomSection>? customSections,
    List<String>? sectionOrder,
    this.templateId = 'modern_indigo',
    this.targetJobDescription = '',
    this.forceOnePage = false,
  })  : personalInfo = personalInfo ?? PersonalInfo(),
        workExperience = workExperience ?? [],
        education = education ?? [],
        skills = skills ?? [],
        projects = projects ?? [],
        customSections = customSections ?? [],
        sectionOrder = sectionOrder ??
            [
              'personal_info',
              'summary',
              'experience',
              'education',
              'skills',
              'projects',
              ...(customSections ?? []).map((s) => s.id),
            ];

  ResumeData copyWith({
    PersonalInfo? personalInfo,
    List<WorkExperience>? workExperience,
    List<Education>? education,
    List<Skill>? skills,
    List<Project>? projects,
    List<CustomSection>? customSections,
    List<String>? sectionOrder,
    String? templateId,
    String? targetJobDescription,
    bool? forceOnePage,
  }) {
    return ResumeData(
      personalInfo: personalInfo ?? this.personalInfo,
      workExperience: workExperience ?? this.workExperience,
      education: education ?? this.education,
      skills: skills ?? this.skills,
      projects: projects ?? this.projects,
      customSections: customSections ?? this.customSections,
      sectionOrder: sectionOrder ?? this.sectionOrder,
      templateId: templateId ?? this.templateId,
      targetJobDescription: targetJobDescription ?? this.targetJobDescription,
      forceOnePage: forceOnePage ?? this.forceOnePage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personalInfo': personalInfo.toJson(),
      'workExperience': workExperience.map((e) => e.toJson()).toList(),
      'education': education.map((e) => e.toJson()).toList(),
      'skills': skills.map((e) => e.toJson()).toList(),
      'projects': projects.map((e) => e.toJson()).toList(),
      'customSections': customSections.map((e) => e.toJson()).toList(),
      'sectionOrder': sectionOrder,
      'templateId': templateId,
      'targetJobDescription': targetJobDescription,
      'forceOnePage': forceOnePage,
    };
  }

  factory ResumeData.fromJson(Map<String, dynamic> json) {
    final customSectionsList = (json['customSections'] as List?)
        ?.map((e) => CustomSection.fromJson(e))
        .toList() ?? [];

    var order = (json['sectionOrder'] as List?)?.map((e) => e as String).toList();

    if (order != null) {
      final index = order.indexOf('custom_sections');
      if (index != -1) {
        order.removeAt(index);
        final ids = customSectionsList.map((s) => s.id).toList();
        order.insertAll(index, ids);
      }
      // Ensure any custom sections not in order are added at the end
      for (final cs in customSectionsList) {
        if (!order.contains(cs.id)) {
          order.add(cs.id);
        }
      }
    }

    return ResumeData(
      personalInfo: json['personalInfo'] != null
          ? PersonalInfo.fromJson(json['personalInfo'])
          : null,
      workExperience: (json['workExperience'] as List?)
          ?.map((e) => WorkExperience.fromJson(e))
          .toList(),
      education: (json['education'] as List?)
          ?.map((e) => Education.fromJson(e))
          .toList(),
      skills:
          (json['skills'] as List?)?.map((e) => Skill.fromJson(e)).toList(),
      projects:
          (json['projects'] as List?)?.map((e) => Project.fromJson(e)).toList(),
      customSections: customSectionsList,
      sectionOrder: order,
      templateId: json['templateId'] ?? 'modern_indigo',
      targetJobDescription: json['targetJobDescription'] ?? '',
      forceOnePage: json['forceOnePage'] ?? false,
    );
  }

  factory ResumeData.demo() {
    return ResumeData(
      personalInfo: PersonalInfo(
        fullName: 'Jane Doe',
        email: 'jane.doe@example.com',
        phoneNumber: '+1 (555) 019-2834',
        website: 'linkedin.com/in/janedoe',
        location: 'San Francisco, CA',
        summary:
            'Experienced Software Engineer with a passion for building user-centric interfaces. Proficient in Dart, Flutter, and Firebase, with a solid track record of optimizing on-device systems and leading small developer squads.',
        github: 'github.com/janedoe',
      ),
      workExperience: [
        WorkExperience(
          company: 'Tech Solutions Inc.',
          position: 'Senior Flutter Developer',
          startDate: 'Jan 2024',
          endDate: 'Present',
          description:
              'Designed and deployed responsive mobile and web layouts. Optimized rendering pipeline, leading to 25% increase in UI frame consistency. Conducted client-side performance audits.',
        ),
        WorkExperience(
          company: 'Mobile Crafters',
          position: 'Software Engineer',
          startDate: 'Jun 2022',
          endDate: 'Dec 2023',
          description:
              'Authored state management blueprints using Riverpod. Integrated Google AI Studio API for smart workflow triggers. Upgraded legacy databases to Firebase.',
        ),
      ],
      education: [
        Education(
          institution: 'University of Computer Science',
          degree: 'Bachelor of Science in Computer Science',
          startDate: 'Sep 2018',
          endDate: 'May 2022',
          gpa: '3.8',
        ),
      ],
      skills: [
        Skill(name: 'Flutter & Dart', proficiency: 'Expert'),
        Skill(name: 'Firebase Suite', proficiency: 'Expert'),
        Skill(name: 'State Management (Riverpod)', proficiency: 'Expert'),
        Skill(name: 'Google AI Studio & LLM Integration', proficiency: 'Intermediate'),
        Skill(name: 'On-Device PDF Compilation', proficiency: 'Intermediate'),
      ],
      projects: [
        Project(
          name: 'Smart Resume Builder',
          description:
              'An AI-powered offline-first resume compiler built using Flutter and Google Gemini. Features responsive layouts and on-device PDF generation.',
          link: 'https://github.com/janedoe/resume-builder',
        ),
        Project(
          name: 'Task Flow Mobile App',
          description:
              'A productivity application designed with clean architecture and reactive state management. Downloaded over 10k times on Android.',
          link: 'https://github.com/janedoe/task-flow',
        ),
      ],
      customSections: [
        CustomSection(
          id: 'certifications',
          title: 'Certifications',
          content:
              '• Google Certified Professional Cloud Architect (2025)\n• Associate Android Developer certification (2023)',
        ),
      ],
      targetJobDescription:
          'Looking for a Senior Software Engineer specializing in cross-platform UI frameworks like Flutter. Experience with responsive layouts, state management solutions (Riverpod, Bloc), and integrating on-device AI/LLM components is a plus.',
    );
  }
}

class SavedResume {
  final String id;
  final String name;
  final String templateId;
  final DateTime lastModified;
  final ResumeData data;

  SavedResume({
    required this.id,
    required this.name,
    required this.templateId,
    required this.lastModified,
    required this.data,
  });

  SavedResume copyWith({
    String? id,
    String? name,
    String? templateId,
    DateTime? lastModified,
    ResumeData? data,
  }) {
    return SavedResume(
      id: id ?? this.id,
      name: name ?? this.name,
      templateId: templateId ?? this.templateId,
      lastModified: lastModified ?? this.lastModified,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'templateId': templateId,
        'lastModified': lastModified.toIso8601String(),
        'data': data.toJson(),
      };

  factory SavedResume.fromJson(Map<String, dynamic> json) => SavedResume(
        id: json['id'] ?? '',
        name: json['name'] ?? 'Untitled Resume',
        templateId: json['templateId'] ?? 'modern_indigo',
        lastModified: json['lastModified'] != null
            ? DateTime.tryParse(json['lastModified']) ?? DateTime.now()
            : DateTime.now(),
        data: json['data'] != null
            ? ResumeData.fromJson(json['data'])
            : ResumeData(),
      );
}
