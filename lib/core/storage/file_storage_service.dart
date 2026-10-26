import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileStorageService {
  Directory? _appDir;

  Future<void> initialize({Directory? customBaseDir}) async {
    if (customBaseDir != null) {
      _appDir = customBaseDir;
    } else {
      _appDir = await getApplicationDocumentsDirectory();
    }
    // Ensure standard directories exist
    await documentsDir.create(recursive: true);
    await thumbnailsDir.create(recursive: true);
    await tempDir.create(recursive: true);
  }

  Directory get baseDir {
    if (_appDir == null) {
      throw StateError('FileStorageService has not been initialized.');
    }
    return _appDir!;
  }

  Directory get documentsDir => Directory(p.join(baseDir.path, 'documents'));
  Directory get thumbnailsDir => Directory(p.join(baseDir.path, 'thumbnails'));
  Directory get tempDir => Directory(p.join(baseDir.path, 'temp'));

  /// Creates a unique temporary file path inside `temp/`.
  String createTempFilePath({String extension = 'tmp'}) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return p.join(tempDir.path, 'temp_$timestamp.$extension');
  }

  /// Writes data atomically to a destination file via a temporary file.
  Future<File> writeBytesAtomically(String destinationPath, Uint8List bytes) async {
    final tempPath = createTempFilePath(extension: p.extension(destinationPath).replaceFirst('.', ''));
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(bytes, flush: true);

    final destFile = File(destinationPath);
    if (await destFile.exists()) {
      await destFile.delete();
    }
    await destFile.parent.create(recursive: true);
    return tempFile.rename(destinationPath);
  }

  /// Saves a final generated PDF into the managed `documents/` directory.
  Future<File> saveManagedPdf(String filename, Uint8List pdfBytes) async {
    final cleanName = sanitizeFilename(filename);
    final finalPath = p.join(documentsDir.path, cleanName.endsWith('.pdf') ? cleanName : '$cleanName.pdf');
    return writeBytesAtomically(finalPath, pdfBytes);
  }

  /// Saves a thumbnail into the managed `thumbnails/` directory.
  Future<File> saveThumbnail(String documentId, Uint8List thumbnailBytes) async {
    final finalPath = p.join(thumbnailsDir.path, '${documentId}_thumb.jpg');
    return writeBytesAtomically(finalPath, thumbnailBytes);
  }

  /// Cleans all stale temporary files in `temp/`.
  Future<int> cleanTempDirectory() async {
    if (!await tempDir.exists()) return 0;
    int deletedCount = 0;
    final entries = tempDir.listSync(followLinks: false);
    for (final entry in entries) {
      try {
        if (entry is File) {
          await entry.delete();
          deletedCount++;
        } else if (entry is Directory) {
          await entry.delete(recursive: true);
          deletedCount++;
        }
      } catch (_) {
        // Ignore files currently locked by an active process
      }
    }
    return deletedCount;
  }

  /// Sanitizes a filename to avoid path traversal and illegal filesystem characters.
  static String sanitizeFilename(String filename) {
    return filename
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
