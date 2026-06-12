import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Persists camera frames received from the robot to a debug folder on disk so
/// they can be pulled off the device and inspected byte-for-byte while we
/// stabilise the capture pipeline (see WakeWord/camera notes). Test plumbing —
/// nothing in the product UI depends on these files.
///
/// On Android the files land in the app-specific external dir, pullable without
/// root via:
///   adb pull /sdcard/Android/data/com.example.luni_app/files/luni_captures
class CaptureStore {
  CaptureStore._();

  static const _logTag = 'luni.camera';
  static Directory? _dir;

  /// Resolve (and cache) the captures directory. Prefers app-specific external
  /// storage on Android (easy `adb pull`), falling back to the documents dir.
  static Future<Directory> _resolveDir() async {
    final cached = _dir;
    if (cached != null) return cached;

    Directory base;
    try {
      base = (await getExternalStorageDirectory()) ??
          await getApplicationDocumentsDirectory();
    } on Object {
      base = await getApplicationDocumentsDirectory();
    }
    final dir = Directory('${base.path}/luni_captures');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _dir = dir;
    return dir;
  }

  /// Save [bytes] as a timestamped JPEG. Returns the saved file, or null on
  /// failure (logged). Never throws — saving is best-effort debug output.
  static Future<File?> saveJpeg(Uint8List bytes) async {
    try {
      final dir = await _resolveDir();
      final stamp =
          DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
      final file = File('${dir.path}/cap_$stamp.jpg');
      await file.writeAsBytes(bytes, flush: true);
      debugPrint('[$_logTag] saved ${bytes.length} B -> ${file.path}');
      return file;
    } on Object catch (e, st) {
      debugPrint('[$_logTag] save failed: $e\n$st');
      return null;
    }
  }
}
