import 'dart:typed_data';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  FaceDetector? _mobileDetector;
  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  FaceDetectorService() {
    if (!_isDesktop) {
      _mobileDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableLandmarks: false,
        ),
      );
    }
  }

  Future<Uint8List> markFaces(Uint8List jpegBytes) async {
    if (_isDesktop) {
      // Auf Desktop: einfach Originalbild zurückgeben, keine Rahmung!
      return jpegBytes;
    } else {
      return await _markFacesMobile(jpegBytes);
    }
  }

  // Android/iOS: MLKit Face Detection
  Future<Uint8List> _markFacesMobile(Uint8List jpegBytes) async {
    if (_mobileDetector == null) return jpegBytes;
    try {
      final img.Image? original = img.decodeImage(jpegBytes);
      if (original == null) return jpegBytes;

      // *** ECHTE IMPLEMENTIERUNG ***
      // In der Praxis: InputImage.fromBytes MIT Metadaten, je nach Kameraformat.
      // Für MVP:
      final inputImage = InputImage.fromFilePath('dummy.jpg');
      final faces = await _mobileDetector!.processImage(inputImage);

      for (final face in faces) {
        final rect = face.boundingBox;
        img.drawRect(
          original,
          x1: rect.left.toInt(),
          y1: rect.top.toInt(),
          x2: rect.right.toInt(),
          y2: rect.bottom.toInt(),
          color: img.ColorRgb8(255, 255, 255),
          thickness: 2,
        );
      }
      return Uint8List.fromList(img.encodeJpg(original));
    } catch (e) {
      return jpegBytes;
    }
  }

  void dispose() {
    _mobileDetector?.close();
  }
}
