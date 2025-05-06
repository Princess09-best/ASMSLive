import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // Take a photo with the camera
  Future<File?> takePhoto({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality ?? 85,
    );

    if (image == null) return null;

    return File(image.path);
  }

  // Pick an image from the gallery
  Future<File?> pickImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality ?? 85,
    );

    if (image == null) return null;

    return File(image.path);
  }

  // Pick multiple images from the gallery
  Future<List<File>> pickMultipleImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    return images.map((image) => File(image.path)).toList();
  }

  // Save image to app directory
  Future<File> saveImageToAppDirectory(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${_uuid.v4()}${path.extension(imageFile.path)}';
    final savedImage = await imageFile.copy('${appDir.path}/$fileName');
    return savedImage;
  }

  // Get a unique file name for an image
  String getUniqueFileName(String extension) {
    return '${_uuid.v4()}.$extension';
  }

  // Check if camera is available - simplified version
  Future<bool> isCameraAvailable() async {
    try {
      // Simply check if we can access the camera
      final XFile? image = await _picker
          .pickImage(
            source: ImageSource.camera,
            maxWidth: 1,
            maxHeight: 1,
            imageQuality: 1,
            requestFullMetadata: false,
          )
          .timeout(const Duration(milliseconds: 500), onTimeout: () => null);

      return image != null;
    } catch (e) {
      print('Camera availability check error: $e');
      return false;
    }
  }

  // Get camera permission status - simplified version
  Future<bool> requestCameraPermission() async {
    try {
      // We'll try a minimal camera access to trigger permission request
      await _picker
          .pickImage(
            source: ImageSource.camera,
            maxWidth: 1,
            maxHeight: 1,
            imageQuality: 1,
            requestFullMetadata: false,
          )
          .timeout(const Duration(milliseconds: 500), onTimeout: () => null);

      // If we reach here without exception, permission is likely granted
      return true;
    } catch (e) {
      print('Camera permission error: $e');
      return false;
    }
  }

  // Show image picker dialog
  Future<File?> showImagePickerDialog(BuildContext context) async {
    return await showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt),
                        SizedBox(width: 10),
                        Text('Take a Photo'),
                      ],
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop(
                      await takePhoto(
                        maxWidth: 800,
                        imageQuality: 75,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.photo_library),
                        SizedBox(width: 10),
                        Text('Choose from Gallery'),
                      ],
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop(
                      await pickImage(
                        maxWidth: 800,
                        imageQuality: 75,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Static method for document scanning
  static Future<File?> scanDocument() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 100,
      );

      if (photo == null) return null;

      // For now, we'll just return the image file
      // In a full implementation, this would convert the image to PDF
      final File imageFile = File(photo.path);

      // Create a unique filename for the document
      final directory = await getApplicationDocumentsDirectory();
      final String fileName =
          'doc_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final String filePath = '${directory.path}/$fileName';

      // In a real implementation, we would convert the image to PDF here
      // For now, we'll just copy the image file
      final File documentFile = await imageFile.copy(filePath);

      return documentFile;
    } catch (e) {
      print('Error in scanDocument: $e');
      return null;
    }
  }

  // Static method for taking a passport photo
  static Future<File?> takePassportPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (photo == null) return null;
      return File(photo.path);
    } catch (e) {
      print('Error taking passport photo: $e');
      return null;
    }
  }

  // Static method for taking an enhanced photo with better quality
  static Future<File?> takeEnhancedPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 100,
      );

      if (photo == null) return null;
      return File(photo.path);
    } catch (e) {
      print('Error taking enhanced photo: $e');
      return null;
    }
  }

  // Static method for selecting a passport photo from gallery
  static Future<File?> selectPassportPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (photo == null) return null;
      return File(photo.path);
    } catch (e) {
      print('Error selecting passport photo: $e');
      return null;
    }
  }

  // Static method for compressing an image file
  static Future<File?> compressImage(File file, {int quality = 85}) async {
    try {
      // Create a unique filename for the compressed image
      final directory = await getApplicationDocumentsDirectory();
      final extension = path.extension(file.path);
      final fileName =
          'compressed_${DateTime.now().millisecondsSinceEpoch}$extension';
      final String filePath = '${directory.path}/$fileName';

      // In a real implementation, we would use a proper image compression library
      // Here we'll simulate compression by creating a copy
      final File compressedFile = await file.copy(filePath);

      return compressedFile;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  // Static method for selecting a document (PDF, DOC, DOCX)
  static Future<File?> selectDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        lockParentWindow: true,
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      print('Error selecting document: $e');
      return null;
    }
  }
}
