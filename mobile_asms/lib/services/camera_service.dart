import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

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
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1,
        maxHeight: 1,
        imageQuality: 1,
        requestFullMetadata: false,
      ).timeout(const Duration(milliseconds: 500), onTimeout: () => null);
      
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
      await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1,
        maxHeight: 1,
        imageQuality: 1,
        requestFullMetadata: false,
      ).timeout(const Duration(milliseconds: 500), onTimeout: () => null);
      
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
} 