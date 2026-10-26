import 'package:cunning_document_scanner/cunning_document_scanner.dart';

class ScannerService {
  /// Launches the native document scanner (Google Play services on Android, VisionKit on iOS).
  ///
  /// Returns a list of file paths to the cropped and enhanced document images,
  /// or null if the user canceled the scanning session.
  static Future<List<String>?> scanDocuments({int noOfPages = 50}) async {
    try {
      final pictures = await CunningDocumentScanner.getPictures(
        noOfPages: noOfPages,
      );
      return pictures;
    } catch (e) {
      rethrow;
    }
  }
}
