import 'dart:io';

import 'package:share_plus/share_plus.dart';

import '../core/session_manifest.dart';

/// Hands exported files to the user, e.g. through the system share sheet.
abstract interface class FileSharer {
  /// Shares [files]; completes once the platform is done with them.
  Future<void> share(List<File> files);
}

/// [FileSharer] using the platform share sheet of `share_plus`.
class SharePlusFileSharer implements FileSharer {
  /// Creates the sharer.
  const SharePlusFileSharer();

  @override
  Future<void> share(List<File> files) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          for (final f in files) XFile(f.path, mimeType: mimeTypeFor(f.path)),
        ],
      ),
    );
  }
}

const Map<String, String> _mimeTypes = {
  'pdf': 'application/pdf',
  'jpg': 'image/jpeg',
  'png': 'image/png',
};

/// MIME type of an exported file from its (case-insensitive) extension.
///
/// Throws [ArgumentError] for anything other than `.pdf`, `.jpg`, `.png`.
String mimeTypeFor(String path) {
  final ext = fileExtension(path);
  final type = ext == null ? null : _mimeTypes[ext];
  if (type == null) {
    throw ArgumentError('not an exported file name', 'path');
  }
  return type;
}
