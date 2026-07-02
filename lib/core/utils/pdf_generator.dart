import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:resume_builder/features/resume/domain/resume_model.dart';

class PdfGenerator {
  static Future<Uint8List> generate(ResumeData resumeData) async {
    final String templateId = resumeData.templateId;

    // Two-column sidebar uses a completely different page layout
    if (templateId == 'two_column_sidebar') {
      return _generateTwoColumnSidebar(resumeData);
    }

    final pdf = pw.Document(
      title: '${resumeData.personalInfo.fullName.replaceAll(' ', '_')}_Resume',
      author: resumeData.personalInfo.fullName,
    );

    final bool isClassic = templateId == 'classic_elegance';
    final bool isMinimal = templateId == 'minimalist_executive';
    final bool isTech = templateId == 'tech_professional';
    final bool isCreativeBold = templateId == 'creative_bold';
    final bool isAtsClean = templateId == 'ats_clean';
    final bool isExecutive = templateId == 'executive_formal';

    // Theme color palettes
    PdfColor primaryColor;
    if (isMinimal || isAtsClean) {
      primaryColor = PdfColor.fromHex('#000000');
    } else if (isTech) {
      primaryColor = PdfColor.fromHex('#006064');
    } else if (isCreativeBold) {
      primaryColor = PdfColor.fromHex('#BF360C');
    } else if (isExecutive) {
      primaryColor = PdfColor.fromHex('#0D47A1');
    } else {
      primaryColor = PdfColor.fromHex('#1a237e');
    }
    final textColor = PdfColor.fromHex('#212121');
    final accentColor = isMinimal ? PdfColor.fromHex('#424242') : PdfColor.fromHex('#555555');

    // Theme font selection
    pw.Font baseFont;
    pw.Font boldFont;
    pw.Font italicFont;
    if (isClassic || isExecutive) {
      baseFont = pw.Font.times();
      boldFont = pw.Font.timesBold();
      italicFont = pw.Font.timesItalic();
    } else if (isTech) {
      baseFont = pw.Font.courier();
      boldFont = pw.Font.courierBold();
      italicFont = pw.Font.courierOblique();
    } else {
      baseFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
      italicFont = pw.Font.helveticaOblique();
    }

    final marginValue = isMinimal ? 30.0 : (isAtsClean ? 50.0 : 40.0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: pw.EdgeInsets.symmetric(horizontal: marginValue, vertical: marginValue),
        build: (pw.Context context) {
          final List<pw.Widget> contentWidgets = [];

          // 1. Render Contact Header
          if (isCreativeBold) {
            // Creative Bold: colored banner header
            contentWidgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      resumeData.personalInfo.fullName.isNotEmpty
                          ? resumeData.personalInfo.fullName.toUpperCase()
                          : 'YOUR NAME',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 26,
                        color: PdfColors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      [
                        if (resumeData.personalInfo.email.isNotEmpty) resumeData.personalInfo.email,
                        if (resumeData.personalInfo.phoneNumber.isNotEmpty) resumeData.personalInfo.phoneNumber,
                        if (resumeData.personalInfo.location.isNotEmpty) resumeData.personalInfo.location,
                        if (resumeData.personalInfo.website.isNotEmpty) resumeData.personalInfo.website,
                        if (resumeData.personalInfo.github.isNotEmpty) resumeData.personalInfo.github,
                      ].join('  |  '),
                      style: pw.TextStyle(
                        font: baseFont,
                        fontSize: 9.0,
                        color: PdfColor.fromHex('#FFFFFF'),
                      ),
                    ),
                  ],
                ),
              ),
            );
            contentWidgets.add(pw.SizedBox(height: 12));
          } else if (isExecutive) {
            // Executive Formal: centered name with gold underline
            final goldAccent = PdfColor.fromHex('#B8860B');
            contentWidgets.addAll([
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    resumeData.personalInfo.fullName.isNotEmpty
                        ? resumeData.personalInfo.fullName.toUpperCase()
                        : 'YOUR NAME',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 24,
                      color: primaryColor,
                      letterSpacing: 3.0,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(height: 2, width: 80, color: goldAccent),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    [
                      if (resumeData.personalInfo.email.isNotEmpty) resumeData.personalInfo.email,
                      if (resumeData.personalInfo.phoneNumber.isNotEmpty) resumeData.personalInfo.phoneNumber,
                      if (resumeData.personalInfo.location.isNotEmpty) resumeData.personalInfo.location,
                      if (resumeData.personalInfo.website.isNotEmpty) resumeData.personalInfo.website,
                      if (resumeData.personalInfo.github.isNotEmpty) resumeData.personalInfo.github,
                    ].join('  |  '),
                    style: pw.TextStyle(font: baseFont, fontSize: 9.0, color: accentColor),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(color: primaryColor, thickness: 1.5),
                ],
              ),
              pw.SizedBox(height: 10),
            ]);
          } else {
            // Default header (Modern Indigo, Minimalist, Tech, Classic, ATS Clean)
            contentWidgets.addAll([
              pw.Column(
                crossAxisAlignment: isClassic
                    ? pw.CrossAxisAlignment.center
                    : pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    resumeData.personalInfo.fullName.isNotEmpty
                        ? resumeData.personalInfo.fullName.toUpperCase()
                        : 'YOUR NAME',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: isMinimal ? 20 : (isAtsClean ? 18 : 22),
                      color: primaryColor,
                      letterSpacing: isTech ? 0.0 : 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    [
                      if (resumeData.personalInfo.email.isNotEmpty) resumeData.personalInfo.email,
                      if (resumeData.personalInfo.phoneNumber.isNotEmpty) resumeData.personalInfo.phoneNumber,
                      if (resumeData.personalInfo.location.isNotEmpty) resumeData.personalInfo.location,
                      if (resumeData.personalInfo.website.isNotEmpty) resumeData.personalInfo.website,
                      if (resumeData.personalInfo.github.isNotEmpty) resumeData.personalInfo.github,
                    ].join('  |  '),
                    style: pw.TextStyle(
                      font: baseFont,
                      fontSize: 9.0,
                      color: accentColor,
                    ),
                    textAlign: isClassic ? pw.TextAlign.center : pw.TextAlign.left,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(color: primaryColor, thickness: isClassic ? 1.5 : (isAtsClean ? 0.5 : 1.0)),
                ],
              ),
              pw.SizedBox(height: 10),
            ]);
          }

          // 2. Loop over sectionOrder to render rest of contents dynamically
          for (final section in resumeData.sectionOrder) {
            final List<pw.Widget> sectionContent = [];
            String sectionTitle = '';

            switch (section) {
              case 'summary':
                if (resumeData.personalInfo.summary.isNotEmpty) {
                  sectionTitle = 'Summary';
                  sectionContent.add(
                    _buildBulletOrParagraphText(
                      resumeData.personalInfo.summary,
                      baseFont,
                      9.5,
                      textColor,
                      isClassic ? 2.5 : 2.0,
                    ),
                  );
                }
                break;
              case 'experience':
                if (resumeData.workExperience.isNotEmpty) {
                  sectionTitle = 'Experience';
                  sectionContent.addAll(resumeData.workExperience.map((exp) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                child: pw.RichText(
                                  text: pw.TextSpan(
                                    children: [
                                      pw.TextSpan(
                                        text: exp.position.isNotEmpty ? exp.position : 'Position Title',
                                        style: pw.TextStyle(font: boldFont, fontSize: 10, color: textColor),
                                      ),
                                      if (exp.company.isNotEmpty)
                                        pw.TextSpan(
                                          text: ' at ${exp.company}',
                                          style: pw.TextStyle(font: italicFont, fontSize: 9.5, color: accentColor),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              pw.Text(
                                [exp.startDate, exp.endDate].where((s) => s.isNotEmpty).join(' - '),
                                style: pw.TextStyle(font: boldFont, fontSize: 9, color: accentColor),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 2),
                          if (exp.description.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(left: 6),
                              child: _buildBulletOrParagraphText(
                                exp.description,
                                baseFont,
                                9,
                                textColor,
                                1.8,
                              ),
                            ),
                        ],
                      ),
                    );
                  }));
                }
                break;
              case 'education':
                if (resumeData.education.isNotEmpty) {
                  sectionTitle = 'Education';
                  sectionContent.addAll(resumeData.education.map((edu) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  edu.degree.isNotEmpty ? edu.degree : 'Degree Program',
                                  style: pw.TextStyle(font: boldFont, fontSize: 10, color: textColor),
                                ),
                              ),
                              pw.Text(
                                [edu.startDate, edu.endDate].where((s) => s.isNotEmpty).join(' - '),
                                style: pw.TextStyle(font: boldFont, fontSize: 9, color: accentColor),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 1),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                edu.institution.isNotEmpty ? edu.institution : 'University/School Name',
                                style: pw.TextStyle(font: italicFont, fontSize: 9, color: accentColor),
                              ),
                              if (edu.gpa.isNotEmpty)
                                pw.Text(
                                  'GPA: ${edu.gpa}',
                                  style: pw.TextStyle(font: baseFont, fontSize: 9, color: textColor),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }));
                }
                break;
              case 'skills':
                if (resumeData.skills.isNotEmpty) {
                  sectionTitle = 'Skills';
                  sectionContent.add(
                    pw.Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: resumeData.skills.map((skill) {
                        return pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#f1f3f8'),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            skill.proficiency.isNotEmpty ? '${skill.name} (${skill.proficiency})' : skill.name,
                            style: pw.TextStyle(font: baseFont, fontSize: 8.5, color: textColor),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }
                break;
              case 'projects':
                if (resumeData.projects.isNotEmpty) {
                  sectionTitle = 'Projects';
                  sectionContent.addAll(resumeData.projects.map((proj) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                proj.name.isNotEmpty ? proj.name : 'Project Name',
                                style: pw.TextStyle(font: boldFont, fontSize: 10, color: textColor),
                              ),
                              if (proj.link.isNotEmpty)
                                pw.Text(
                                  proj.link,
                                  style: pw.TextStyle(font: italicFont, fontSize: 8.5, color: primaryColor),
                                ),
                            ],
                          ),
                          pw.SizedBox(height: 2),
                          if (proj.description.isNotEmpty)
                            _buildBulletOrParagraphText(
                              proj.description,
                              baseFont,
                              9,
                              textColor,
                              1.8,
                            ),
                        ],
                      ),
                    );
                  }));
                }
                break;
              case 'custom_sections':
                for (final customSec in resumeData.customSections) {
                  if (customSec.title.isNotEmpty && customSec.content.isNotEmpty) {
                    final List<pw.Widget> customSecContent = [
                      _buildBulletOrParagraphText(
                        customSec.content,
                        baseFont,
                        9,
                        textColor,
                        1.8,
                      )
                    ];
                    contentWidgets.add(
                      _renderSection(
                        customSec.title,
                        customSecContent,
                        boldFont,
                        primaryColor,
                        templateId,
                      ),
                    );
                  }
                }
                break;
              default:
                if (section.startsWith('custom_')) {
                  final customSecIndex = resumeData.customSections.indexWhere((s) => s.id == section);
                  if (customSecIndex != -1) {
                    final customSec = resumeData.customSections[customSecIndex];
                    if (customSec.title.isNotEmpty && customSec.content.isNotEmpty) {
                      final List<pw.Widget> customSecContent = [
                        _buildBulletOrParagraphText(
                          customSec.content,
                          baseFont,
                          9,
                          textColor,
                          1.8,
                        )
                      ];
                      contentWidgets.add(
                        _renderSection(
                          customSec.title,
                          customSecContent,
                          boldFont,
                          primaryColor,
                          templateId,
                        ),
                      );
                    }
                  }
                }
                break;
            }

            if (sectionTitle.isNotEmpty && sectionContent.isNotEmpty) {
              contentWidgets.add(
                _renderSection(
                  sectionTitle,
                  sectionContent,
                  boldFont,
                  primaryColor,
                  templateId,
                ),
              );
            }
          }

          return contentWidgets;
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _renderSection(
    String title,
    List<pw.Widget> content,
    pw.Font font,
    PdfColor color,
    String templateId,
  ) {
    final bool isTech = templateId == 'tech_professional';

    if (isTech) {
      // Tech Professional uses a modern left-hand side-by-side header structure!
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        child: pw.Column(
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 90,
                  padding: const pw.EdgeInsets.only(right: 12),
                  child: pw.Text(
                    title.toUpperCase(),
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 9.5,
                      color: color,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: content,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          ],
        ),
      );
    }

    // Default top-header style (Modern Indigo, Classic Elegance, Minimalist Executive)
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, font, color, templateId),
        ...content,
        pw.SizedBox(height: 6),
      ],
    );
  }

  static pw.Widget _buildSectionHeader(String title, pw.Font font, PdfColor color, String templateId) {
    final bool isClassic = templateId == 'classic_elegance';
    final bool isMinimal = templateId == 'minimalist_executive';

    return pw.Column(
      crossAxisAlignment: isClassic ? pw.CrossAxisAlignment.center : pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 8),
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            font: font,
            fontSize: isMinimal ? 10 : 11,
            color: isMinimal ? PdfColor.fromHex('#000000') : color,
            letterSpacing: 1.0,
          ),
        ),
        pw.SizedBox(height: 2),
        if (!isMinimal)
          pw.Container(
            height: isClassic ? 1.5 : 1.0,
            color: isClassic ? PdfColor.fromHex('#000000') : PdfColor.fromHex('#c5cae9'),
          ),
        pw.SizedBox(height: 6),
      ],
    );
  }

  static pw.Widget _buildBulletOrParagraphText(
    String text,
    pw.Font font,
    double fontSize,
    PdfColor textColor,
    double lineSpacing,
  ) {
    final lines = text.split('\n').map((l) => l.trim()).toList();
    if (lines.length <= 1 &&
        !text.startsWith('•') &&
        !text.startsWith('-') &&
        !text.startsWith('*')) {
      return pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize,
          color: textColor,
          lineSpacing: lineSpacing,
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.isEmpty) return pw.SizedBox(height: 2);

        bool isBullet = line.startsWith('•') || line.startsWith('-') || line.startsWith('*');
        String cleanedText = line;
        if (isBullet) {
          cleanedText = line.substring(1).trim();
        }

        if (isBullet) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 3.5,
                  height: 3.5,
                  margin: const pw.EdgeInsets.only(top: 4.5, right: 6),
                  decoration: pw.BoxDecoration(
                    color: textColor,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    cleanedText,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: fontSize,
                      color: textColor,
                      lineSpacing: lineSpacing,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              cleanedText,
              style: pw.TextStyle(
                font: font,
                fontSize: fontSize,
                color: textColor,
                lineSpacing: lineSpacing,
              ),
            ),
          );
        }
      }).toList(),
    );
  }

  // -------------------------------------------------------
  // Two-Column Sidebar Layout
  // -------------------------------------------------------
  static Future<Uint8List> _generateTwoColumnSidebar(ResumeData resumeData) async {
    final pdf = pw.Document(
      title: '${resumeData.personalInfo.fullName.replaceAll(' ', '_')}_Resume',
      author: resumeData.personalInfo.fullName,
    );

    final sidebarColor = PdfColor.fromHex('#1B3A4B');
    final sidebarText = PdfColors.white;
    final sidebarAccent = PdfColor.fromHex('#7EB8DA');
    final mainText = PdfColor.fromHex('#212121');
    final mainAccent = PdfColor.fromHex('#555555');
    final headingColor = PdfColor.fromHex('#1B3A4B');

    final baseFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();
    final italicFont = pw.Font.helveticaOblique();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // LEFT SIDEBAR
              pw.Container(
                width: 190,
                color: sidebarColor,
                padding: const pw.EdgeInsets.all(18),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Name
                    pw.Text(
                      resumeData.personalInfo.fullName.isNotEmpty
                          ? resumeData.personalInfo.fullName
                          : 'Your Name',
                      style: pw.TextStyle(font: boldFont, fontSize: 16, color: sidebarText),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Container(height: 2, width: 40, color: sidebarAccent),
                    pw.SizedBox(height: 16),

                    // Contact Info
                    pw.Text('CONTACT', style: pw.TextStyle(font: boldFont, fontSize: 9, color: sidebarAccent, letterSpacing: 1.5)),
                    pw.SizedBox(height: 6),
                    if (resumeData.personalInfo.email.isNotEmpty)
                      _sidebarContactRow('Email: ', resumeData.personalInfo.email, baseFont, sidebarText),
                    if (resumeData.personalInfo.phoneNumber.isNotEmpty)
                      _sidebarContactRow('Phone: ', resumeData.personalInfo.phoneNumber, baseFont, sidebarText),
                    if (resumeData.personalInfo.location.isNotEmpty)
                      _sidebarContactRow('Loc: ', resumeData.personalInfo.location, baseFont, sidebarText),
                    if (resumeData.personalInfo.website.isNotEmpty)
                      _sidebarContactRow('Web: ', resumeData.personalInfo.website, baseFont, sidebarText),
                    if (resumeData.personalInfo.github.isNotEmpty)
                      _sidebarContactRow('GitHub: ', resumeData.personalInfo.github, baseFont, sidebarText),

                    pw.SizedBox(height: 18),

                    // Skills
                    if (resumeData.skills.isNotEmpty) ...[
                      pw.Text('SKILLS', style: pw.TextStyle(font: boldFont, fontSize: 9, color: sidebarAccent, letterSpacing: 1.5)),
                      pw.SizedBox(height: 6),
                      ...resumeData.skills.map((skill) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Row(
                          children: [
                            pw.Container(width: 3.5, height: 3.5, decoration: pw.BoxDecoration(color: sidebarAccent, shape: pw.BoxShape.circle)),
                            pw.SizedBox(width: 6),
                            pw.Expanded(
                              child: pw.Text(
                                skill.name,
                                style: pw.TextStyle(font: baseFont, fontSize: 8.5, color: sidebarText),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],

                    pw.SizedBox(height: 18),

                    // Education in sidebar
                    if (resumeData.education.isNotEmpty) ...[
                      pw.Text('EDUCATION', style: pw.TextStyle(font: boldFont, fontSize: 9, color: sidebarAccent, letterSpacing: 1.5)),
                      pw.SizedBox(height: 6),
                      ...resumeData.education.map((edu) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(edu.degree.isNotEmpty ? edu.degree : 'Degree',
                                style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: sidebarText)),
                            pw.Text(edu.institution,
                                style: pw.TextStyle(font: italicFont, fontSize: 8, color: PdfColor.fromHex('#B0C4D8'))),
                            if (edu.startDate.isNotEmpty || edu.endDate.isNotEmpty)
                              pw.Text(
                                [edu.startDate, edu.endDate].where((s) => s.isNotEmpty).join(' - '),
                                style: pw.TextStyle(font: baseFont, fontSize: 7.5, color: PdfColor.fromHex('#8FA8BE')),
                              ),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),

              // RIGHT MAIN CONTENT
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(24),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Summary
                      if (resumeData.personalInfo.summary.isNotEmpty) ...[
                        pw.Text('SUMMARY', style: pw.TextStyle(font: boldFont, fontSize: 11, color: headingColor, letterSpacing: 1.0)),
                        pw.SizedBox(height: 2),
                        pw.Container(height: 1, color: PdfColor.fromHex('#C5CAE9')),
                        pw.SizedBox(height: 6),
                        _buildBulletOrParagraphText(resumeData.personalInfo.summary, baseFont, 9, mainText, 2.0),
                        pw.SizedBox(height: 14),
                      ],

                      // Experience
                      if (resumeData.workExperience.isNotEmpty) ...[
                        pw.Text('EXPERIENCE', style: pw.TextStyle(font: boldFont, fontSize: 11, color: headingColor, letterSpacing: 1.0)),
                        pw.SizedBox(height: 2),
                        pw.Container(height: 1, color: PdfColor.fromHex('#C5CAE9')),
                        pw.SizedBox(height: 6),
                        ...resumeData.workExperience.map((exp) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Expanded(
                                    child: pw.RichText(
                                      text: pw.TextSpan(children: [
                                        pw.TextSpan(text: exp.position.isNotEmpty ? exp.position : 'Position',
                                            style: pw.TextStyle(font: boldFont, fontSize: 10, color: mainText)),
                                        if (exp.company.isNotEmpty)
                                          pw.TextSpan(text: ' at ${exp.company}',
                                              style: pw.TextStyle(font: italicFont, fontSize: 9.5, color: mainAccent)),
                                      ]),
                                    ),
                                  ),
                                  pw.Text(
                                    [exp.startDate, exp.endDate].where((s) => s.isNotEmpty).join(' - '),
                                    style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: mainAccent),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 2),
                              if (exp.description.isNotEmpty)
                                pw.Padding(
                                  padding: const pw.EdgeInsets.only(left: 6),
                                  child: _buildBulletOrParagraphText(exp.description, baseFont, 9, mainText, 1.8),
                                ),
                            ],
                          ),
                        )),
                        pw.SizedBox(height: 8),
                      ],

                      // Projects
                      if (resumeData.projects.isNotEmpty) ...[
                        pw.Text('PROJECTS', style: pw.TextStyle(font: boldFont, fontSize: 11, color: headingColor, letterSpacing: 1.0)),
                        pw.SizedBox(height: 2),
                        pw.Container(height: 1, color: PdfColor.fromHex('#C5CAE9')),
                        pw.SizedBox(height: 6),
                        ...resumeData.projects.map((proj) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 6),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(proj.name.isNotEmpty ? proj.name : 'Project Name',
                                  style: pw.TextStyle(font: boldFont, fontSize: 10, color: mainText)),
                              if (proj.description.isNotEmpty)
                                pw.Padding(
                                  padding: const pw.EdgeInsets.only(left: 6, top: 2),
                                  child: _buildBulletOrParagraphText(proj.description, baseFont, 9, mainText, 1.6),
                                ),
                            ],
                          ),
                        )),
                        pw.SizedBox(height: 8),
                      ],

                      // Custom Sections
                      ...resumeData.customSections.where((cs) => cs.content.isNotEmpty).map((cs) => pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(cs.title.toUpperCase(), style: pw.TextStyle(font: boldFont, fontSize: 11, color: headingColor, letterSpacing: 1.0)),
                          pw.SizedBox(height: 2),
                          pw.Container(height: 1, color: PdfColor.fromHex('#C5CAE9')),
                          pw.SizedBox(height: 6),
                          _buildBulletOrParagraphText(cs.content, baseFont, 9, mainText, 1.8),
                          pw.SizedBox(height: 10),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _sidebarContactRow(String label, String text, pw.Font font, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        '$label$text',
        style: pw.TextStyle(font: font, fontSize: 8, color: color),
      ),
    );
  }
}
