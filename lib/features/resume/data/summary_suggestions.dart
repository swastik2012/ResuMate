import 'package:resumate/features/resume/domain/resume_model.dart';

class SummaryTemplate {
  final String category;
  final String text;

  const SummaryTemplate({required this.category, required this.text});
}

class SummarySuggestionEngine {
  static const _summaries = [
    // Software Engineering
    SummaryTemplate(category: 'Software Engineering', text: 'Results-driven Software Engineer with expertise in building scalable applications and microservices. Proficient in modern frameworks and cloud technologies, with a strong track record of delivering high-quality code and optimizing system performance.'),
    SummaryTemplate(category: 'Software Engineering', text: 'Full-stack developer passionate about creating user-centric applications. Experienced in agile methodologies, CI/CD pipelines, and test-driven development. Committed to writing clean, maintainable code that scales.'),
    SummaryTemplate(category: 'Software Engineering', text: 'Innovative software engineer with a focus on mobile and cross-platform development. Skilled in Flutter, React Native, and native Android/iOS frameworks. Passionate about crafting smooth, responsive user experiences.'),
    SummaryTemplate(category: 'Software Engineering', text: 'Backend engineer specializing in distributed systems, database optimization, and API design. Experienced in high-throughput environments and committed to building reliable, fault-tolerant infrastructure.'),
    SummaryTemplate(category: 'Software Engineering', text: 'Detail-oriented software developer with strong problem-solving skills and a passion for learning emerging technologies. Experienced in both startup and enterprise environments, delivering features that drive measurable business impact.'),

    // Data Science & AI
    SummaryTemplate(category: 'Data Science & AI', text: 'Data Scientist with expertise in machine learning, statistical modeling, and data visualization. Proficient in Python, R, and SQL, with experience deploying ML models at scale using cloud platforms.'),
    SummaryTemplate(category: 'Data Science & AI', text: 'AI/ML Engineer passionate about building intelligent systems. Experienced in deep learning, NLP, and computer vision, with a strong publication record and hands-on deployment experience.'),
    SummaryTemplate(category: 'Data Science & AI', text: 'Analytical data professional skilled in transforming complex datasets into actionable business insights. Experienced with BI tools, ETL pipelines, and predictive analytics frameworks.'),
    SummaryTemplate(category: 'Data Science & AI', text: 'Machine Learning Engineer with expertise in building and deploying production-grade ML pipelines. Skilled in TensorFlow, PyTorch, and MLOps best practices for continuous model improvement.'),
    SummaryTemplate(category: 'Data Science & AI', text: 'Research-oriented data scientist with a strong foundation in statistics and experimental design. Experienced in A/B testing, causal inference, and building recommendation systems.'),

    // Product Management
    SummaryTemplate(category: 'Product Management', text: 'Strategic Product Manager with a track record of launching products that delight users and drive revenue growth. Skilled in market research, roadmap planning, and cross-functional team leadership.'),
    SummaryTemplate(category: 'Product Management', text: 'Customer-centric product leader experienced in B2B SaaS and marketplace platforms. Adept at translating user needs into compelling product experiences using data-driven decision making.'),
    SummaryTemplate(category: 'Product Management', text: 'Technical Product Manager bridging engineering and business teams. Experienced in API platforms, developer tools, and infrastructure products with strong technical depth and stakeholder management skills.'),
    SummaryTemplate(category: 'Product Management', text: 'Growth-focused product manager skilled in user acquisition, retention optimization, and experimentation frameworks. Passionate about building products that scale and create lasting value.'),
    SummaryTemplate(category: 'Product Management', text: 'Product leader with deep expertise in mobile and consumer applications. Experienced in design thinking, rapid prototyping, and iterative development to achieve product-market fit.'),

    // Design & UX
    SummaryTemplate(category: 'Design & UX', text: 'Creative UI/UX Designer with a passion for crafting intuitive, accessible digital experiences. Proficient in Figma, Adobe Creative Suite, and design systems, with a strong portfolio of user-centered design work.'),
    SummaryTemplate(category: 'Design & UX', text: 'UX Researcher and Designer experienced in conducting user interviews, usability testing, and creating data-informed design solutions that improve engagement and conversion.'),
    SummaryTemplate(category: 'Design & UX', text: 'Visual designer specializing in brand identity, typography, and modern web aesthetics. Skilled in translating business goals into compelling visual narratives across digital and print media.'),
    SummaryTemplate(category: 'Design & UX', text: 'Interaction designer focused on creating seamless, delightful user flows for mobile and web applications. Experienced in motion design, prototyping, and design-to-development handoffs.'),
    SummaryTemplate(category: 'Design & UX', text: 'Product designer with expertise in design systems, component libraries, and accessible design patterns. Passionate about building scalable design foundations for growing teams.'),

    // Marketing
    SummaryTemplate(category: 'Marketing', text: 'Digital Marketing Specialist with expertise in SEO, SEM, social media strategy, and content marketing. Proven track record of increasing brand visibility and driving qualified leads through data-driven campaigns.'),
    SummaryTemplate(category: 'Marketing', text: 'Growth marketer experienced in performance marketing, funnel optimization, and analytics. Skilled in Google Ads, Meta Ads, and marketing automation platforms with strong ROI focus.'),
    SummaryTemplate(category: 'Marketing', text: 'Content strategist and brand storyteller with experience creating compelling narratives across multiple channels. Skilled in editorial planning, copywriting, and audience engagement analytics.'),
    SummaryTemplate(category: 'Marketing', text: 'Email marketing specialist with expertise in segmentation, A/B testing, and lifecycle campaigns. Experienced in increasing open rates, click-through rates, and customer retention.'),
    SummaryTemplate(category: 'Marketing', text: 'Marketing analyst with strong quantitative skills and experience in attribution modeling, customer journey mapping, and marketing mix optimization.'),

    // Finance & Accounting
    SummaryTemplate(category: 'Finance', text: 'Financial Analyst with expertise in financial modeling, forecasting, and strategic planning. Proficient in Excel, SQL, and BI tools, with experience supporting executive decision-making in fast-paced environments.'),
    SummaryTemplate(category: 'Finance', text: 'Experienced accountant with strong knowledge of GAAP, tax compliance, and audit procedures. Detail-oriented professional committed to accuracy and timely financial reporting.'),
    SummaryTemplate(category: 'Finance', text: 'Investment professional with expertise in portfolio management, risk analysis, and market research. Strong analytical skills with a track record of identifying high-value opportunities.'),
    SummaryTemplate(category: 'Finance', text: 'Corporate finance professional experienced in M&A, capital structure optimization, and financial due diligence. Strong communicator adept at presenting complex financial data to stakeholders.'),
    SummaryTemplate(category: 'Finance', text: 'FP&A specialist skilled in budgeting, variance analysis, and building financial dashboards. Experienced in driving operational efficiency through actionable financial insights.'),

    // Healthcare
    SummaryTemplate(category: 'Healthcare', text: 'Dedicated healthcare professional with clinical experience and a passion for patient-centered care. Skilled in electronic health records, patient education, and interdisciplinary team collaboration.'),
    SummaryTemplate(category: 'Healthcare', text: 'Health informatics specialist bridging clinical workflows and technology solutions. Experienced in EHR implementation, data analytics, and improving healthcare delivery outcomes.'),
    SummaryTemplate(category: 'Healthcare', text: 'Registered nurse with expertise in critical care, patient assessment, and evidence-based practice. Committed to delivering compassionate, high-quality care in fast-paced clinical environments.'),

    // Education
    SummaryTemplate(category: 'Education', text: 'Passionate educator with experience in curriculum development, classroom management, and student engagement strategies. Committed to fostering inclusive learning environments that inspire academic excellence.'),
    SummaryTemplate(category: 'Education', text: 'Instructional designer specializing in e-learning platforms, multimedia content creation, and competency-based education. Experienced in LMS administration and learner analytics.'),
    SummaryTemplate(category: 'Education', text: 'Academic researcher and lecturer with a strong publication record. Experienced in grant writing, student mentorship, and interdisciplinary research collaboration.'),

    // General / Entry Level
    SummaryTemplate(category: 'General', text: 'Motivated recent graduate with strong analytical skills and a passion for continuous learning. Eager to apply academic knowledge and internship experience to contribute to a dynamic team.'),
    SummaryTemplate(category: 'General', text: 'Adaptable professional with a diverse skill set and excellent communication abilities. Proven ability to thrive in fast-paced environments, manage multiple priorities, and deliver results under pressure.'),
    SummaryTemplate(category: 'General', text: 'Goal-oriented professional seeking to leverage strong organizational and interpersonal skills in a challenging role. Committed to professional development and making meaningful contributions to team success.'),
    SummaryTemplate(category: 'General', text: 'Self-motivated individual with a strong work ethic and attention to detail. Experienced in project coordination, stakeholder communication, and process improvement initiatives.'),
    SummaryTemplate(category: 'General', text: 'Versatile professional with a blend of technical and business acumen. Quick learner with hands-on experience in cross-functional collaboration and data-driven problem solving.'),
  ];

  /// Detect the most likely category based on resume data
  static String _detectCategory(ResumeData resume) {
    final allText = [
      resume.personalInfo.summary,
      ...resume.workExperience.map((e) => '${e.position} ${e.description}'),
      ...resume.skills.map((s) => s.name),
      ...resume.education.map((e) => e.degree),
      ...resume.projects.map((p) => '${p.name} ${p.description}'),
    ].join(' ').toLowerCase();

    final categoryKeywords = {
      'Software Engineering': ['software', 'developer', 'engineer', 'flutter', 'react', 'java', 'python', 'code', 'frontend', 'backend', 'fullstack', 'mobile', 'web', 'api', 'devops', 'cloud'],
      'Data Science & AI': ['data', 'machine learning', 'ml', 'ai', 'deep learning', 'nlp', 'analytics', 'tensorflow', 'pytorch', 'statistics', 'model'],
      'Product Management': ['product', 'roadmap', 'strategy', 'stakeholder', 'agile', 'scrum', 'prioritization', 'user stories', 'pm'],
      'Design & UX': ['design', 'ux', 'ui', 'figma', 'sketch', 'prototype', 'user experience', 'visual', 'creative', 'adobe'],
      'Marketing': ['marketing', 'seo', 'sem', 'campaign', 'brand', 'content', 'social media', 'digital', 'growth', 'ads'],
      'Finance': ['finance', 'accounting', 'audit', 'investment', 'portfolio', 'budget', 'gaap', 'tax', 'banking', 'financial'],
      'Healthcare': ['healthcare', 'medical', 'clinical', 'patient', 'nurse', 'doctor', 'hospital', 'ehr', 'pharmacy'],
      'Education': ['education', 'teacher', 'instructor', 'curriculum', 'student', 'academic', 'university', 'professor', 'learning'],
    };

    int maxScore = 0;
    String bestCategory = 'General';

    for (final entry in categoryKeywords.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        if (allText.contains(keyword)) score++;
      }
      if (score > maxScore) {
        maxScore = score;
        bestCategory = entry.key;
      }
    }

    return maxScore >= 2 ? bestCategory : 'General';
  }

  /// Get top 5 relevant summaries for the user's profile
  static List<SummaryTemplate> getSuggestions(ResumeData resume) {
    final category = _detectCategory(resume);

    // Get all summaries for the detected category
    final categoryMatches = _summaries.where((s) => s.category == category).toList();

    // Also include some general ones
    final generalOnes = _summaries.where((s) => s.category == 'General').toList();

    final results = <SummaryTemplate>[];
    results.addAll(categoryMatches.take(4));
    results.addAll(generalOnes.take(2));

    return results.take(5).toList();
  }

  /// Get all categories
  static List<String> get categories =>
      _summaries.map((s) => s.category).toSet().toList()..sort();
}
