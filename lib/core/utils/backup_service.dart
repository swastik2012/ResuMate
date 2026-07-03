import 'dart:convert';
import 'package:resumate/features/resume/domain/resume_model.dart';

class BackupService {
  static const String _appName = 'ResuMate';
  static const String _schemaVersion = '1.0';

  /// Converts list of SavedResume objects into an encrypted/encoded backup JSON string
  static String exportBackup(List<SavedResume> resumes) {
    final payloadMap = {
      'appName': _appName,
      'schemaVersion': _schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'resumeCount': resumes.length,
      'resumes': resumes.map((r) => r.toJson()).toList(),
    };

    final rawJson = jsonEncode(payloadMap);
    final base64Encoded = base64Encode(utf8.encode(rawJson));

    final envelope = {
      'format': 'resumate_backup',
      'signature': 'RESUMATE_ENCRYPTED_BACKUP_V1',
      'payload': base64Encoded,
    };

    return const JsonEncoder.withIndent('  ').convert(envelope);
  }

  /// Parses and validates a backup JSON/resumate string, returning restored SavedResume list
  static List<SavedResume> importBackup(String backupString) {
    final trimmed = backupString.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Backup file is empty.');
    }

    Map<String, dynamic> rootMap;
    try {
      rootMap = jsonDecode(trimmed) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Invalid JSON backup file: $e');
    }

    String rawJson;
    if (rootMap.containsKey('payload') && rootMap['signature'] == 'RESUMATE_ENCRYPTED_BACKUP_V1') {
      final base64Payload = rootMap['payload'] as String;
      rawJson = utf8.decode(base64Decode(base64Payload));
    } else {
      rawJson = trimmed;
    }

    final dataMap = jsonDecode(rawJson) as Map<String, dynamic>;
    final resumesRaw = dataMap['resumes'] as List?;

    if (resumesRaw == null) {
      throw const FormatException('No resume data found in backup file.');
    }

    final restored = <SavedResume>[];
    for (final item in resumesRaw) {
      if (item is Map<String, dynamic>) {
        restored.add(SavedResume.fromJson(item));
      }
    }

    return restored;
  }
}
