import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CardIconStorage {
  static const _folderName = 'images';

  static String? toStoredPath(String? path) {
    if (path == null || path.isEmpty) return path;
    for (final context in [p.windows, p.posix]) {
      final segments = context.split(path);
      final imagesIndex = segments.lastIndexOf(_folderName);
      if (imagesIndex < 0 || imagesIndex != segments.length - 2) continue;
      final filename = segments.last;
      if (filename.isEmpty || filename == '.' || filename == '..') continue;
      return p.posix.join(_folderName, filename);
    }
    return path;
  }

  static String? resolvePath(String? path, String supportDirectory) {
    if (path == null) return null;
    final relativePath = toStoredPath(path);
    if (relativePath == null) return null;
    final pathSegments = p.posix.split(path);
    if (relativePath == path &&
        (pathSegments.length != 2 || pathSegments.first != _folderName)) {
      return path;
    }
    return p.join(supportDirectory, p.joinAll(p.split(relativePath)));
  }

  static Future<String?> importIcon(String? selectedPath) async {
    if (selectedPath == null || selectedPath.isEmpty) return null;

    final storedPath = toStoredPath(selectedPath);
    final supportDirectory = await getApplicationSupportDirectory();
    if (storedPath != null && storedPath != selectedPath) {
      final localPath = p.join(
        supportDirectory.path,
        p.joinAll(p.split(storedPath)),
      );
      if (await File(localPath).exists() || !p.isAbsolute(selectedPath)) {
        return storedPath;
      }
    }

    final source = File(selectedPath);
    if (!await source.exists()) {
      if (storedPath != null && storedPath != selectedPath) {
        return storedPath;
      }
      throw FileSystemException(
        'Selected card icon does not exist',
        selectedPath,
      );
    }

    final imageDirectory = Directory(
      p.join(supportDirectory.path, _folderName),
    );
    await imageDirectory.create(recursive: true);

    final imageBytes = await source.readAsBytes();
    final hash = md5.convert(imageBytes).toString();
    final filename = '$hash${p.extension(selectedPath)}';
    final destination = File(p.join(imageDirectory.path, filename));
    if (!await destination.exists()) {
      await source.copy(destination.path);
    }
    return p.posix.join(_folderName, filename);
  }

  static Future<List<String>> getIconPaths() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final imageDirectory = Directory(
      p.join(supportDirectory.path, _folderName),
    );
    if (!await imageDirectory.exists()) return [];

    final paths = <String>[];
    await for (final entity in imageDirectory.list(
      recursive: false,
      followLinks: false,
    )) {
      if (entity is File && p.extension(entity.path).toLowerCase() == '.png') {
        paths.add(entity.path);
      }
    }
    return paths;
  }
}
