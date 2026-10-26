import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:image_picker/image_picker.dart';

class ScannerService {
  final ImagePicker _picker = ImagePicker();

  /// Scans physical documents using the platform system document scanner.
  ///
  /// On Android: Google Play services Document Scanner.
  /// On iOS: Apple VisionKit VNDocumentCameraViewController.
  /// Returns a list of image file paths, or null if the user canceled.
  Future<List<String>?> scanWithDocumentScanner({int maxPages = 50}) async {
    try {
      final pictures = await CunningDocumentScanner.getPictures(
        noOfPages: maxPages,
      );
      if (pictures == null || pictures.isEmpty) {
        return null;
      }
      return pictures;
    } catch (e) {
      rethrow;
    }
  }

  /// Fallback: Imports images from the device photo gallery.
  /// Used when camera permission is denied or on non-GMS devices.
  Future<List<String>?> pickImagesFromGallery() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isEmpty) {
        return null;
      }
      return pickedFiles.map((x) => x.path).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fallback: Captures a single photo from standard camera.
  Future<String?> captureFromStandardCamera() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera);
      return photo?.path;
    } catch (e) {
      rethrow;
    }
  }
}
