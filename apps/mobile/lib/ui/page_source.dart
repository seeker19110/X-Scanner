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
}

/// [PageSource] backed by `image_picker`: system camera and photo picker,
/// so the app itself needs no camera or storage permission.
///
/// Images are requested without resizing or recompression so the original
/// is kept intact.
class ImagePickerPageSource implements PageSource {
  /// Creates a source using [picker] (a new [ImagePicker] by default).
  ImagePickerPageSource({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

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
