import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resume_builder/main.dart';
import 'package:resume_builder/features/auth/presentation/login_screen.dart';
import 'package:resume_builder/features/home/presentation/home_screen.dart';
import 'package:resume_builder/features/resume/domain/resume_model.dart';
import 'package:resume_builder/core/utils/backup_service.dart';
import 'package:resume_builder/core/utils/docx_generator.dart';

void main() {
  testWidgets('Test sign in with mock fallback and guest mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Let the initial stream subscription event fire and rebuild
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Try Demo Account'), findsOneWidget);

    // Click on the Try Demo Account button
    await tester.tap(find.text('Try Demo Account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  test('Test BackupService export and import roundtrip', () {
    final originalResumes = [
      SavedResume(
        id: 'res_123',
        name: 'John Doe Software Engineer',
        templateId: 'modern_indigo',
        lastModified: DateTime.now(),
        data: ResumeData.demo(),
      ),
    ];

    final exportedJson = BackupService.exportBackup(originalResumes);
    expect(exportedJson.contains('resumate_backup'), isTrue);

    final restoredResumes = BackupService.importBackup(exportedJson);
    expect(restoredResumes.length, equals(1));
    expect(restoredResumes.first.id, equals('res_123'));
    expect(restoredResumes.first.data.personalInfo.fullName, equals('Jane Doe'));
  });

  test('Test DocxGenerator byte output', () {
    final demoData = ResumeData.demo();
    final docxBytes = DocxGenerator.generate(demoData);
    expect(docxBytes.isNotEmpty, isTrue);
    // OpenXML ZIP archives begin with PK signature bytes [0x50, 0x4B, 0x03, 0x04]
    expect(docxBytes[0], equals(0x50));
    expect(docxBytes[1], equals(0x4B));
  });
}
