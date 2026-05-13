// Notice that this file is imported and not proxy_ffi.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:universal_ffi/ffi.dart';

import 'abstract_asset_saver.dart';

class SwephAssetSaver extends AbstractAssetSaver<DynamicLibrary, Allocator> {
  static SwephAssetSaver? _instance;

  SwephAssetSaver._(super.epheFilesPath);

  static Future<SwephAssetSaver> init(
      DynamicLibrary library, String epheFilesPath) async {
    if (_instance == null) {
      String resolvedPath = epheFilesPath;
      final epheDir = Directory(epheFilesPath);
      try {
        epheDir.createSync(recursive: true);
        // Test if directory is actually writable
        final testFile = File('${epheDir.path}/.write_test');
        testFile.writeAsBytesSync([0]);
        testFile.deleteSync();
      } catch (_) {
        // Fallback to current working directory if app support dir is read-only
        resolvedPath = epheFilesPath.contains('/')
            ? epheFilesPath
            : '${Directory.current.path}/$epheFilesPath';
        final fallbackDir = Directory(resolvedPath);
        fallbackDir.createSync(recursive: true);
      }
      _instance = SwephAssetSaver._(resolvedPath);
    }

    return _instance!;
  }

  @override
  Future<void> saveEpheFile(String destFile, Uint8List contents) async {
    final destPath = File('$epheFilesPath/$destFile');
    if (destPath.existsSync()) {
      return;
    }
    destPath.writeAsBytesSync(contents);
  }

  @override
  void copyEpheDir(String epheFilesDir, bool forceOverwrite) {
    final srcDir = Directory(epheFilesDir);
    if (!srcDir.existsSync()) {
      return;
    }

    for (final file in srcDir.listSync()) {
      if (file is! File) {
        continue;
      }
      copyEpheFile(file.path, forceOverwrite);
    }
  }

  @override
  void copyEpheFile(String filePath, bool forceOverwrite) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return;
    }

    final filename = basename(filePath);
    final destFile = File('$epheFilesPath/$filename');
    if (destFile.existsSync() && !forceOverwrite) {
      return;
    }

    destFile.writeAsBytesSync(file.readAsBytesSync());
  }
}