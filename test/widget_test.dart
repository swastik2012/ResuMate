import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resumate/features/splash/presentation/splash_screen.dart';
import 'package:resumate/features/resume/domain/resume_model.dart';
import 'package:resumate/core/utils/backup_service.dart';
import 'package:resumate/core/utils/docx_generator.dart';

void main() {
  testWidgets('Test SplashScreen renders brand elements', (WidgetTester tester) async {
    bool initCalled = false;

    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: SplashScreen(
          onInitialize: () async {
            initCalled = true;
            return false;
          },
          onComplete: (isSignedIn) {
            // Navigate away to dispose the splash screen and stop animations
            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Done'))),
            );
          },
        ),
      ),
    );

    // Initial render
    await tester.pump();
    expect(find.text('ResuMate'), findsOneWidget);
    expect(find.text('AI-Powered Resume Builder'), findsOneWidget);
    expect(initCalled, isTrue);

    // Advance time to complete the minimum 2.2s timer + init
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 200));

    // Now the splash should have navigated away; pump to settle
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);
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
