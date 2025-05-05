import 'dart:io';
import 'package:flutter/material.dart';
import '../services/camera_service.dart';
import '../config/app_constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class CameraTestScreen extends StatefulWidget {
  const CameraTestScreen({Key? key}) : super(key: key);

  @override
  State<CameraTestScreen> createState() => _CameraTestScreenState();
}

class _CameraTestScreenState extends State<CameraTestScreen> {
  File? _standardPhoto;
  File? _enhancedPhoto;
  File? _galleryPhoto;
  File? _documentPhoto;
  File? _documentFile;

  // Image dimensions and file size info
  String _standardPhotoInfo = '';
  String _enhancedPhotoInfo = '';
  String _galleryPhotoInfo = '';
  String _documentPhotoInfo = '';
  String _documentFileInfo = '';
  String _permissionStatus = 'Unknown';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final storageStatus = await Permission.storage.status;

    setState(() {
      _permissionStatus =
          'Camera: ${cameraStatus.toString()}, Storage: ${storageStatus.toString()}';
    });
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();

    setState(() {
      _permissionStatus =
          'Camera: ${cameraStatus.toString()}, Storage: ${storageStatus.toString()}';
    });
  }

  // Direct image picker test to bypass service layer
  Future<void> _directImagePickerTest() async {
    try {
      setState(() {
        _standardPhotoInfo = 'Attempting to open camera...';
      });

      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        setState(() {
          _standardPhoto = File(photo.path);
          _standardPhotoInfo = 'Success! Photo path: ${photo.path}';
        });
      } else {
        setState(() {
          _standardPhotoInfo = 'No photo was taken (user cancelled or error)';
        });
      }
    } catch (e) {
      setState(() {
        _standardPhotoInfo = 'Error: ${e.toString()}';
      });
      print('Direct image picker error: $e');
    }
  }

  // Direct gallery picker
  Future<void> _directGalleryPickerTest() async {
    try {
      setState(() {
        _galleryPhotoInfo = 'Attempting to open gallery...';
      });

      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.gallery);

      if (photo != null) {
        setState(() {
          _galleryPhoto = File(photo.path);
          _galleryPhotoInfo = 'Success! Photo path: ${photo.path}';
        });
      } else {
        setState(() {
          _galleryPhotoInfo = 'No photo was selected (user cancelled or error)';
        });
      }
    } catch (e) {
      setState(() {
        _galleryPhotoInfo = 'Error: ${e.toString()}';
      });
      print('Direct gallery picker error: $e');
    }
  }

  // Direct document picker
  Future<void> _directDocumentPickerTest() async {
    try {
      setState(() {
        _documentFileInfo = 'Attempting to open file picker...';
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        String? filePath = result.files.single.path;
        setState(() {
          _documentFile = File(filePath);
          _documentFileInfo = 'Success! File path: ${filePath}';
        });
      } else {
        setState(() {
          _documentFileInfo =
              'No document was selected (user cancelled or error)';
        });
      }
    } catch (e) {
      setState(() {
        _documentFileInfo = 'Error: ${e.toString()}';
      });
      print('Direct document picker error: $e');
    }
  }

  // Direct document scanning test
  Future<void> _directDocumentScanTest() async {
    try {
      setState(() {
        _documentPhotoInfo = 'Attempting to scan document...';
      });

      // Take the photo first
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 100,
      );

      if (photo == null) {
        setState(() {
          _documentPhotoInfo = 'No photo was taken (user cancelled or error)';
        });
        return;
      }

      // Create PDF from the photo using our service
      setState(() {
        _documentPhotoInfo = 'Photo captured, creating PDF...';
      });

      final pdfFile = await CameraService.scanDocument();

      if (pdfFile != null) {
        setState(() {
          _documentPhoto = pdfFile;
          _documentPhotoInfo = 'Success! PDF created at: ${pdfFile.path}';
        });
      } else {
        setState(() {
          _documentPhotoInfo = 'Failed to create PDF from image';
        });
      }
    } catch (e) {
      setState(() {
        _documentPhotoInfo = 'Error: ${e.toString()}';
      });
      print('Direct document scan error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Permission status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permission Status: $_permissionStatus',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _requestPermissions,
                      child: const Text('Request Permissions'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Direct image picker test button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Direct Camera Test (Bypass Service)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _directImagePickerTest,
                      child: const Text('Test Camera Directly'),
                    ),
                  ),
                  if (_standardPhotoInfo.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_standardPhotoInfo),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Direct gallery picker test button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Direct Gallery Test (Bypass Service)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _directGalleryPickerTest,
                      child: const Text('Test Gallery Directly'),
                    ),
                  ),
                  if (_galleryPhotoInfo.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_galleryPhotoInfo),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Direct document picker test button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Direct Document Test (Bypass Service)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _directDocumentPickerTest,
                      child: const Text('Test Document Picker Directly'),
                    ),
                  ),
                  if (_documentFileInfo.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_documentFileInfo),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Direct document scan test
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Direct Document Scan Test',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _directDocumentScanTest,
                      child: const Text('Scan Document to PDF'),
                    ),
                  ),
                  if (_documentPhotoInfo.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_documentPhotoInfo),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Camera Functionality Test',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Standard Photo Test
            _buildTestSection(
              title: 'Standard Passport Photo',
              image: _standardPhoto,
              info: _standardPhotoInfo,
              onTakePicture: _takeStandardPhoto,
            ),

            // Enhanced Photo Test
            _buildTestSection(
              title: 'Enhanced Photo (HD with compression)',
              image: _enhancedPhoto,
              info: _enhancedPhotoInfo,
              onTakePicture: _takeEnhancedPhoto,
            ),

            // Gallery Photo Test
            _buildTestSection(
              title: 'Gallery Photo (with compression)',
              image: _galleryPhoto,
              info: _galleryPhotoInfo,
              onTakePicture: _pickGalleryPhoto,
              buttonText: 'Select From Gallery',
            ),

            // Document Scan Test
            _buildTestSection(
              title: 'Document Scan',
              image: _documentPhoto,
              info: _documentPhotoInfo,
              onTakePicture: _scanDocument,
              buttonText: 'Scan Document',
            ),

            // Document File Test
            _buildTestSection(
              title: 'Document File',
              image: null,
              customContent: _documentFile != null
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _getFileIcon(_documentFile!.path),
                            size: 60,
                            color: AppConstants.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _documentFile!.path.split('/').last,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(_documentFileInfo),
                        ],
                      ),
                    )
                  : const SizedBox(
                      width: double.infinity,
                      height: 150,
                      child: Center(
                        child: Text('No document selected'),
                      ),
                    ),
              info: '',
              onTakePicture: _selectDocument,
              buttonText: 'Select Document',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection({
    required String title,
    required File? image,
    Widget? customContent,
    required String info,
    required VoidCallback onTakePicture,
    String? buttonText,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            customContent ??
                (image != null
                    ? _buildFilePreview(image)
                    : Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('No image captured'),
                        ),
                      )),
            const SizedBox(height: 8),
            if (info.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(info),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTakePicture,
                child: Text(buttonText ?? 'Take Picture'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to display either an image or a PDF icon
  Widget _buildFilePreview(File file) {
    final extension = path.extension(file.path).toLowerCase();

    if (extension == '.pdf') {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 60,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'PDF Document',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(file.path.split('/').last),
          ],
        ),
      );
    } else {
      // Display the image
      return Image.file(
        file,
        height: 250,
        width: double.infinity,
        fit: BoxFit.contain,
      );
    }
  }

  IconData _getFileIcon(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<String> _getFileInfo(File file) async {
    final bytes = await file.length();
    final kb = bytes / 1024;
    final mb = kb / 1024;

    return 'File size: ${mb > 1 ? '${mb.toStringAsFixed(2)} MB' : '${kb.toStringAsFixed(2)} KB'}';
  }

  Future<void> _takeStandardPhoto() async {
    final photo = await CameraService.takePassportPhoto();
    if (photo != null) {
      setState(() {
        _standardPhoto = photo;
        _getFileInfo(photo).then((info) {
          setState(() {
            _standardPhotoInfo = info;
          });
        });
      });
    }
  }

  Future<void> _takeEnhancedPhoto() async {
    final photo = await CameraService.takeEnhancedPhoto();
    if (photo != null) {
      setState(() {
        _enhancedPhoto = photo;
        _getFileInfo(photo).then((info) {
          setState(() {
            _enhancedPhotoInfo = info;
          });
        });
      });
    }
  }

  Future<void> _pickGalleryPhoto() async {
    final photo = await CameraService.selectPassportPhoto();
    if (photo != null) {
      final compressedPhoto =
          await CameraService.compressImage(photo, quality: 85);
      final finalPhoto = compressedPhoto ?? photo;

      setState(() {
        _galleryPhoto = finalPhoto;
        _getFileInfo(finalPhoto).then((info) {
          setState(() {
            _galleryPhotoInfo = info;
          });
        });
      });
    }
  }

  Future<void> _scanDocument() async {
    final document = await CameraService.scanDocument();
    if (document != null) {
      setState(() {
        _documentPhoto = document;
        _getFileInfo(document).then((info) {
          setState(() {
            _documentPhotoInfo = info;
          });
        });
      });
    }
  }

  Future<void> _selectDocument() async {
    final document = await CameraService.selectDocument();
    if (document != null) {
      setState(() {
        _documentFile = document;
        _getFileInfo(document).then((info) {
          setState(() {
            _documentFileInfo = info;
          });
        });
      });
    }
  }
}
