# Enhanced Camera Functionality Documentation

This document explains the enhanced camera functionality implemented in the Academic Scholarship Management System (ASMS) mobile application.

## Overview

The camera functionality in ASMS mobile app allows users to:

1. Take passport photos directly with their device camera
2. Select passport photos from their gallery
3. Scan documents using the camera
4. Select documents (PDF, DOC, DOCX) from their device
5. Optimize images for better upload performance and storage efficiency

## Key Features

### 1. Image Compression

Images are now automatically compressed to reduce file size while maintaining good quality:
- Passport photos are compressed to 85% quality with dimensions of 800x800 pixels
- Document images are compressed to 90% quality
- Compression happens automatically in the background

### 2. Enhanced Quality Photography

The new `takeEnhancedPhoto()` method provides better quality photos by:
- Taking initial photos at maximum quality (100%)
- Using the device's rear camera for better resolution
- Capturing at higher resolution (1600x1600)
- Auto-applying compression afterward to balance quality and file size

### 3. Document Type Handling

The application intelligently handles different document types:
- Images (JPG, JPEG, PNG) are automatically compressed
- PDFs and documents are handled in their native format
- File format validation ensures only appropriate document types are accepted

## Implementation Details

### CameraService Methods

- `takePassportPhoto()`: Standard method to take a photo
- `selectPassportPhoto()`: Select a photo from gallery
- `scanDocument()`: Use camera to capture a document
- `selectDocument()`: Select a document from file system
- `compressImage()`: Compress an image file to reduce size
- `takeEnhancedPhoto()`: Take high-quality photos with automatic optimization

### Permissions

The app requires and handles the following permissions:
- Camera permission for taking photos and scanning documents
- Storage permission for accessing gallery images and documents

### Optimizations

- Automatic compression for better app performance and reduced data usage
- Image dimensions are optimized for display purposes
- File size is reduced while maintaining acceptable quality
- Output quality is configurable based on use case

## Usage Example

```dart
// Take a high-quality passport photo with auto-compression
final File? photo = await CameraService.takeEnhancedPhoto();
if (photo != null) {
  // Use the photo...
}

// Select and compress a gallery image
final File? originalPhoto = await CameraService.selectPassportPhoto();
if (originalPhoto != null) {
  final File? compressedPhoto = await CameraService.compressImage(
    originalPhoto, 
    quality: 85
  );
  // Use compressedPhoto ?? originalPhoto...
}
```

## Future Improvements

1. OCR (Optical Character Recognition) to extract text from documents
2. Document edge detection for better document scanning
3. Automatic cropping for passport photos based on face detection
4. PDF generation from multiple scanned document images
5. Document categorization and tagging 