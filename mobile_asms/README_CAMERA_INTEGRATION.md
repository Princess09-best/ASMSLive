# Camera Integration for ASMS Mobile App

## Overview

This document outlines the camera integration features added to the ASMS Mobile application:

1. **Passport Photo Capture** - Take photos directly using the device camera or select from the gallery
2. **Document Scanning** - Scan documents using the device camera or select PDF/DOC files

## Setup Instructions

### 1. Install Dependencies

Add the following dependencies to your `pubspec.yaml` file:

```yaml
dependencies:
  image_picker: ^0.8.7+5  # For picking images from gallery or camera
  camera: ^0.10.5+2  # For direct camera access
  pdf: ^3.10.4  # For PDF creation
  permission_handler: ^10.3.0  # For handling permissions
  file_picker: ^5.2.10  # For document selection
```

Run `flutter pub get` to install these dependencies.

### 2. Configure Platform-Specific Settings

#### Android

Update your `android/app/src/main/AndroidManifest.xml` file to include these permissions:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-feature android:name="android.hardware.camera" />
    <uses-feature android:name="android.hardware.camera.autofocus" />
    
    <!-- rest of your manifest -->
</manifest>
```

#### iOS

Update your `ios/Runner/Info.plist` file to include:

```xml
<dict>
    <!-- existing entries -->
    <key>NSCameraUsageDescription</key>
    <string>This app needs camera access to take passport photos and scan documents</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>This app needs photos access to upload passport photos and documents</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>This app needs microphone access for video recording</string>
    <!-- rest of file -->
</dict>
```

## Usage

### CameraService

The `CameraService` class provides the following methods:

1. `requestPermissions()` - Request camera and storage permissions
2. `takePassportPhoto()` - Take a photo using the device camera
3. `selectPassportPhoto()` - Select a photo from the gallery
4. `scanDocument()` - Use the camera to capture a document
5. `selectDocument()` - Select a document from the file system

### Implementation in Application Screen

The `ScholarshipApplicationScreen` has been updated to use these new camera features:

1. **Passport Photo Capture**: Tap on the photo section to either take a new photo or select one from the gallery
2. **Document Scanning**: Tap on the document section to either scan a document using the camera or select one from the file system

## Troubleshooting

If you encounter issues with camera integration:

1. **Permissions Issues**: Make sure permissions are correctly defined in AndroidManifest.xml and Info.plist
2. **Dependency Versions**: Ensure you're using compatible versions of the dependencies
3. **Emulator Limitations**: Camera features may not work in some emulators. Test on a physical device when possible

## Future Improvements

1. Add document cropping and enhancement features
2. Implement PDF generation from images
3. Add OCR (Optical Character Recognition) to extract text from documents
4. Add image compression to reduce file sizes

## Additional Resources

- [Image Picker Documentation](https://pub.dev/packages/image_picker)
- [Camera Plugin Documentation](https://pub.dev/packages/camera)
- [File Picker Documentation](https://pub.dev/packages/file_picker)
- [Permission Handler Documentation](https://pub.dev/packages/permission_handler) 