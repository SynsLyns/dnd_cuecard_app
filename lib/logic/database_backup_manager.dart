import 'dart:developer' as developer;
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseBackupManager {
  static const String _databaseName = 'dnd_cuecards.db';
  static const String _backupFolder = 'backups';
  static const int _maxBackups = 3; // Keep last 3 backups

  /// Creates a timestamped backup of the database
  static Future<String?> createBackup() async {
    try {
      final appDocDir = await getApplicationSupportDirectory();
      final dbFile = File(join(appDocDir.path, _databaseName));

      if (!await dbFile.exists()) {
        return null;
      }

      // Create backups folder if it doesn't exist
      final backupDir = Directory(join(appDocDir.path, _backupFolder));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Create timestamped backup
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final backupPath = join(backupDir.path, '${_databaseName}_$timestamp.backup');
      
      await dbFile.copy(backupPath);

      // Clean up old backups
      await _cleanOldBackups(backupDir);

      return backupPath;
    } catch (e) {
      developer.log('Backup error: $e');
      return null;
    }
  }

  /// Gets list of all available backups sorted by date (newest first)
  static Future<List<String>> getAvailableBackups() async {
    try {
      final appDocDir = await getApplicationSupportDirectory();
      final backupDir = Directory(join(appDocDir.path, _backupFolder));

      if (!await backupDir.exists()) {
        return [];
      }

      final backups = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.backup'))
          .map((entity) => entity.path)
          .toList();

      backups.sort((a, b) => b.compareTo(a)); // Newest first
      return backups;
    } catch (e) {
      developer.log('Error getting backups: $e');
      return [];
    }
  }

  /// Automatically creates periodic backups (call this on app startup)
  static Future<void> ensureRecentBackup() async {
    try {
      final backups = await getAvailableBackups();
      
      if (backups.isEmpty) {
        await createBackup();
        return;
      }

      // If most recent backup is older than 24 hours, create new one
      final mostRecentBackup = File(backups.first);
      final lastModified = await mostRecentBackup.lastModified();
      final hoursSinceBackup = DateTime.now().difference(lastModified).inHours;

      if (hoursSinceBackup >= 24) {
        await createBackup();
      }
    } catch (e) {
      developer.log('Error ensuring backup: $e');
    }
  }

  /// Removes old backups, keeping only the most recent ones
  static Future<void> _cleanOldBackups(Directory backupDir) async {
    try {
      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.backup'))
          .cast<File>()
          .toList();

      if (files.length > _maxBackups) {
        files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        
        // Delete oldest backups
        for (int i = _maxBackups; i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (e) {
      developer.log('Error cleaning old backups: $e');
    }
  }
}
