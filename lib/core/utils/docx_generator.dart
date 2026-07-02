import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:resume_builder/features/resume/domain/resume_model.dart';

class DocxGenerator {
  /// Generates a valid Microsoft Word (.docx) file byte buffer from ResumeData
  static Uint8List generate(ResumeData data) {
    final archive = Archive();

    // 1. [Content_Types].xml
    const contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''';

    // 2. _rels/.rels
    const rootRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

    // 3. word/_rels/document.xml.rels
    const docRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';

    // 4. word/styles.xml
    const stylesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>
        <w:sz w:val="22"/>
        <w:color w:val="222222"/>
      </w:rPr>
    </w:rPrDefault>
  </w:docDefaults>
</w:styles>''';

    // 5. word/document.xml
    final documentXml = _buildDocumentXml(data);

    // Add files to Zip Archive
    _addFileToArchive(archive, '[Content_Types].xml', contentTypesXml);
    _addFileToArchive(archive, '_rels/.rels', rootRelsXml);
    _addFileToArchive(archive, 'word/_rels/document.xml.rels', docRelsXml);
    _addFileToArchive(archive, 'word/styles.xml', stylesXml);
    _addFileToArchive(archive, 'word/document.xml', documentXml);

    final encoder = ZipEncoder();
    final bytes = encoder.encode(archive);
    return Uint8List.fromList(bytes);
  }

  static void _addFileToArchive(Archive archive, String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  static String _buildDocumentXml(ResumeData data) {
    final sb = StringBuffer();
    sb.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    sb.write('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">\n');
    sb.write('  <w:body>\n');

    final info = data.personalInfo;

    // --- Header / Name ---
    if (info.fullName.isNotEmpty) {
      sb.write(_p(info.fullName, size: 48, bold: true, color: '1A365D', spaceAfter: 100));
    }

    // --- Contact Row ---
    final contacts = [
      if (info.email.isNotEmpty) info.email,
      if (info.phoneNumber.isNotEmpty) info.phoneNumber,
      if (info.location.isNotEmpty) info.location,
      if (info.website.isNotEmpty) info.website,
      if (info.github.isNotEmpty) info.github,
    ];
    if (contacts.isNotEmpty) {
      sb.write(_p(contacts.join('   |   '), size: 20, italic: true, color: '4A5568', spaceAfter: 240));
    }

    // Divider
    sb.write('<w:p><w:pPr><w:pBdr><w:bottom w:val="single" w:sz="12" w:space="1" w:color="2B6CB0"/></w:pBdr></w:pPr></w:p>\n');

    // --- Summary Section ---
    if (info.summary.isNotEmpty) {
      sb.write(_heading('PROFESSIONAL SUMMARY'));
      sb.write(_p(info.summary, size: 22, spaceAfter: 200));
    }

    // --- Work Experience Section ---
    if (data.workExperience.isNotEmpty) {
      sb.write(_heading('WORK EXPERIENCE'));
      for (final exp in data.workExperience) {
        sb.write(_subHeading(exp.position, exp.company, '${exp.startDate} – ${exp.endDate}'));
        if (exp.description.isNotEmpty) {
          final lines = exp.description.split('\n').where((l) => l.trim().isNotEmpty);
          for (final line in lines) {
            var cleanLine = line.trim();
            if (cleanLine.startsWith('•') || cleanLine.startsWith('-')) {
              cleanLine = cleanLine.substring(1).trim();
            }
            sb.write(_bullet(cleanLine));
          }
        }
        sb.write(_space(120));
      }
    }

    // --- Education Section ---
    if (data.education.isNotEmpty) {
      sb.write(_heading('EDUCATION'));
      for (final edu in data.education) {
        sb.write(_subHeading(edu.degree, edu.institution, '${edu.startDate} – ${edu.endDate}'));
        if (edu.gpa.isNotEmpty) {
          sb.write(_p('GPA / Grade: ${edu.gpa}', size: 20, italic: true, spaceAfter: 60));
        }
        sb.write(_space(100));
      }
    }

    // --- Skills Section ---
    if (data.skills.isNotEmpty) {
      sb.write(_heading('SKILLS & COMPETENCIES'));
      final skillList = data.skills.map((s) => s.proficiency.isNotEmpty ? '${s.name} (${s.proficiency})' : s.name).join('  •  ');
      sb.write(_p(skillList, size: 22, spaceAfter: 200));
    }

    // --- Projects Section ---
    if (data.projects.isNotEmpty) {
      sb.write(_heading('PROJECTS'));
      for (final proj in data.projects) {
        sb.write(_subHeading(proj.name, proj.link, ''));
        if (proj.description.isNotEmpty) {
          sb.write(_p(proj.description, size: 22, spaceAfter: 120));
        }
      }
    }

    // --- Custom Sections ---
    if (data.customSections.isNotEmpty) {
      for (final cs in data.customSections) {
        sb.write(_heading(cs.title.toUpperCase()));
        final lines = cs.content.split('\n').where((l) => l.trim().isNotEmpty);
        for (final line in lines) {
          var cleanLine = line.trim();
          if (cleanLine.startsWith('•') || cleanLine.startsWith('-')) {
            cleanLine = cleanLine.substring(1).trim();
            sb.write(_bullet(cleanLine));
          } else {
            sb.write(_p(cleanLine, size: 22, spaceAfter: 100));
          }
        }
        sb.write(_space(120));
      }
    }

    sb.write('  </w:body>\n');
    sb.write('</w:document>');
    return sb.toString();
  }

  static String _heading(String title) {
    return '''<w:p>
      <w:pPr>
        <w:pBdr><w:bottom w:val="single" w:sz="6" w:space="2" w:color="2B6CB0"/></w:pBdr>
        <w:spacing w:before="240" w:after="120"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="28"/>
          <w:color w:val="1A365D"/>
        </w:rPr>
        <w:t>${_xmlEscape(title)}</w:t>
      </w:r>
    </w:p>\n''';
  }

  static String _subHeading(String title, String subtitle, String date) {
    return '''<w:p>
      <w:pPr><w:spacing w:before="120" w:after="40"/></w:pPr>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="2D3748"/></w:rPr>
        <w:t>${_xmlEscape(title)}</w:t>
      </w:r>
      ${subtitle.isNotEmpty ? '''<w:r>
        <w:rPr><w:sz w:val="24"/><w:color w:val="4A5568"/></w:rPr>
        <w:t>  |  ${_xmlEscape(subtitle)}</w:t>
      </w:r>''' : ''}
      ${date.isNotEmpty ? '''<w:r>
        <w:rPr><w:i/><w:sz w:val="22"/><w:color w:val="718096"/></w:rPr>
        <w:t>   (${_xmlEscape(date)})</w:t>
      </w:r>''' : ''}
    </w:p>\n''';
  }

  static String _bullet(String text) {
    return '''<w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
        <w:ind w:left="360" w:hanging="240"/>
        <w:spacing w:before="30" w:after="30"/>
      </w:pPr>
      <w:r><w:rPr><w:sz w:val="22"/><w:color w:val="2B6CB0"/></w:rPr><w:t>• </w:t></w:r>
      <w:r><w:rPr><w:sz w:val="22"/><w:color w:val="2D3748"/></w:rPr><w:t>${_xmlEscape(text)}</w:t></w:r>
    </w:p>\n''';
  }

  static String _p(String text, {int size = 22, bool bold = false, bool italic = false, String color = '2D3748', int spaceAfter = 120}) {
    return '''<w:p>
      <w:pPr><w:spacing w:after="$spaceAfter"/></w:pPr>
      <w:r>
        <w:rPr>
          ${bold ? '<w:b/>' : ''}
          ${italic ? '<w:i/>' : ''}
          <w:sz w:val="$size"/>
          <w:color w:val="$color"/>
        </w:rPr>
        <w:t xml:space="preserve">${_xmlEscape(text)}</w:t>
      </w:r>
    </w:p>\n''';
  }

  static String _space(int val) {
    return '<w:p><w:pPr><w:spacing w:after="$val"/></w:pPr></w:p>\n';
  }

  static String _xmlEscape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
