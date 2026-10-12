import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Where new page images come from.
///
/// Every method returns the path of an image file, or `null` when the user
/// cancelled or there is nothing to return.
abstract interface class PageSource {
  /// Takes a photo with the system camera.
  Future<String?> capture();

  /// Lets the user pick one image from the system photo picker.
  Future<String?> pickFromGallery();

  /// Returns a photo taken just before Android killed the app, if any.
  Future<String?> retrieveLost();

  /// Tells the source the app has kept its own copy of the image at
  /// [path]; the source deletes its temporary copy, if it has one.
  /// Never throws.
  Future<void> discard(String path);
}

/// [PageSource] backed by `image_picker`: system camera and photo picker,
/// so the app itself needs no camera or storage permission.
///
/// Images are requested without resizing or recompression so the original
/// is kept intact.
class ImagePickerPageSource implements PageSource {
  /// Creates a source using [picker] (a new [ImagePicker] by default).
  /// `cacheDir` is the folder where the picker leaves its copies (the
  /// app's cache on Android); [discard] only ever deletes inside it.
  ImagePickerPageSource({ImagePicker? picker, this._cacheDir})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  final Directory? _cacheDir;

  /// Deletes the picker's copy at [path] once the app has its own.
  ///
  /// Only a file strictly inside the cache folder given to the constructor
  /// is deleted, compared after resolving symbolic links, followed by its
  /// folder when that is a now empty subfolder of the cache (the photo
  /// picker copies into `cache/{uuid}/`). Without a cache folder nothing
  /// is deleted.
  @override
  Future<void> discard(String path) async {
    final cacheDir = _cacheDir;
    if (cacheDir == null) return;
    try {
      final root = await cacheDir.resolveSymbolicLinks();
      final resolved = await File(path).resolveSymbolicLinks();
      if (!_isInside(resolved, root)) return;
      final type = await FileSystemEntity.type(resolved, followLinks: false);
      if (type != FileSystemEntityType.file) return;
      final file = File(resolved);
      await file.delete();
      final folder = file.parent;
      if (_isInside(folder.path, root) && await folder.list().isEmpty) {
        await folder.delete();
      }
    } on FileSystemException {
      // A copy that is already gone, unreadable or still in use only costs
      // cache space, which the OS reclaims; the page itself is saved, so
      // the user is not bothered and nothing is logged.
    }
  }

  /// Whether the resolved [path] lies strictly below the folder [root].
  static bool _isInside(String path, String root) {
    final prefix = root.endsWith(Platform.pathSeparator)
        ? root
        : '$root${Platform.pathSeparator}';
    return path.length > prefix.length && path.startsWith(prefix);
  }

  @override
  Future<String?> capture() => _pick(ImageSource.camera);

  @override
  Future<String?> pickFromGallery() => _pick(ImageSource.gallery);

  @override
  Future<String?> retrieveLost() async {
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty || response.exception != null) {
        return null;
      }
      return response.file?.path;
    } on PlatformException {
      return null;
    }
  }

  Future<String?> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        requestFullMetadata: false,
      );
      return file?.path;
    } on PlatformException {
      // Denied, unavailable or already in use: treated like a cancel.
      return null;
    }
  }
}
