import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_constants.dart';
import '../models/scholarship.dart';
import '../services/application_service.dart';
import '../services/camera_service.dart';

class ScholarshipApplicationScreen extends StatefulWidget {
  final Scholarship scholarship;

  const ScholarshipApplicationScreen({
    super.key,
    required this.scholarship,
  });

  @override
  State<ScholarshipApplicationScreen> createState() =>
      _ScholarshipApplicationScreenState();
}

class _ScholarshipApplicationScreenState
    extends State<ScholarshipApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form field controllers
  final _dateOfBirthController = TextEditingController();
  final _majorController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _ashesiIdController = TextEditingController();

  // Form data
  File? _passportPhoto;
  DateTime? _dateOfBirth;
  String _gender = 'Male';
  String _category = 'HighNeed';
  File? _requiredDocument;
  bool _isSubmitting = false;

  // Category options
  final List<String> _categoryOptions = [
    'HighNeed',
    'Average',
    'Merit',
    'International',
    'Sports'
  ];

  @override
  void dispose() {
    _dateOfBirthController.dispose();
    _majorController.dispose();
    _homeAddressController.dispose();
    _ashesiIdController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickPassportPhoto() async {
    try {
      final cameraService = CameraService();
      final File? photo = await cameraService.showImagePickerDialog(context);

      if (photo != null) {
        setState(() {
          _passportPhoto = photo;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Check if the file is a PDF, DOC, or DOCX file
  bool _isValidDocumentType(File file) {
    final extension = path.extension(file.path).toLowerCase();
    return extension == '.pdf' || extension == '.doc' || extension == '.docx';
  }

  Future<void> _pickRequiredDocument() async {
    try {
      final cameraService = CameraService();

      // Show option dialog for document selection
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo of Document'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    // Use CameraService to take a document photo
                    final File? file = await cameraService.takePhoto(
                      maxWidth: 1600,
                      maxHeight: 1600,
                      imageQuality: 90,
                    );

                    if (file != null) {
                      setState(() {
                        _requiredDocument = file;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Pick from Gallery'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final File? file = await cameraService.pickImage(
                      maxWidth: 1600,
                      imageQuality: 90,
                    );

                    if (file != null && _isValidDocumentType(file)) {
                      setState(() {
                        _requiredDocument = file;
                      });
                    } else if (file != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Please select a PDF, DOC, or DOCX file'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Use Sample PDF (For Demo)'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    _useSamplePdf();
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking document: $e')),
      );
    }
  }

  Future<void> _useSamplePdf() async {
    try {
      // Create a sample PDF for testing
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/sample_document.pdf';

      // Check if the file already exists
      final file = File(filePath);
      if (!await file.exists()) {
        // Load the sample PDF from assets
        final ByteData data =
            await rootBundle.load('assets/documents/sample_document.pdf');
        final bytes = data.buffer.asUint8List();
        await file.writeAsBytes(bytes);
      }

      setState(() {
        _requiredDocument = file;
      });
    } catch (e) {
      print('Error creating sample PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating sample PDF: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
        _dateOfBirthController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Future<void> _submitApplication() async {
    if (_formKey.currentState!.validate()) {
      // Validate required files
      if (_passportPhoto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a passport photo')),
        );
        return;
      }

      if (_requiredDocument == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload required documents')),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      // Submit application using the ApplicationService
      final success = await ApplicationService.submitApplication(
        scholarshipId: widget.scholarship.id,
        scholarshipName: widget.scholarship.name,
        provider: widget.scholarship.provider,
        amount: widget.scholarship.amount,
        dateOfBirth: _dateOfBirthController.text,
        gender: _gender,
        category: _category,
        major: _majorController.text,
        homeAddress: _homeAddressController.text,
        studentId: _ashesiIdController.text,
        passportPhoto: _passportPhoto!,
        document: _requiredDocument!,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (success) {
          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Application Submitted'),
                content: const Text(
                  'Your application has been submitted successfully. You can track its status in the Applications tab.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Return to previous screen
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          // Show error dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit application. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Scroll to the first error
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Scholarship'),
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Submitting your application...'),
                ],
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scholarship info
                    Text(
                      widget.scholarship.name,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      widget.scholarship.provider,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppConstants.textSecondaryColor,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Form fields
                    const Text(
                      'Application Form',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Passport Photo
                    const Text(
                      'Passport Photo:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickPassportPhoto,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _passportPhoto == null
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, size: 40),
                                    SizedBox(height: 8),
                                    Text('Upload Passport Photo'),
                                  ],
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _passportPhoto!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date of Birth
                    const Text(
                      'Date of Birth:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dateOfBirthController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      decoration: InputDecoration(
                        hintText: 'MM/DD/YYYY',
                        suffixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your date of birth';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Gender
                    const Text(
                      'Gender:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['Male', 'Female', 'Other']
                          .map((gender) => DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _gender = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category
                    const Text(
                      'Category:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _categoryOptions
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _category = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Major
                    const Text(
                      'Major:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _majorController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Computer Science',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your major';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Home Address
                    const Text(
                      'Home Address:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _homeAddressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter your home address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your home address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Required Documents
                    const Text(
                      'Upload Required Documents:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please include: 1. Guardians bank statements 2. Proof of admission',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Only PDF, DOC, or DOCX files are accepted',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppConstants.errorColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickRequiredDocument,
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _requiredDocument == null
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.upload_file, size: 32),
                                    SizedBox(height: 8),
                                    Text(
                                        'Upload Documents (PDF, DOC, or DOCX)'),
                                  ],
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _getDocumentIcon(),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Document uploaded: ${_requiredDocument!.path.split('/').last}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Format: ${path.extension(_requiredDocument!.path).toUpperCase().replaceAll('.', '')}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ashesi ID
                    const Text(
                      'Ashesi ID:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ashesiIdController,
                      decoration: InputDecoration(
                        hintText: 'Enter your Ashesi ID',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your Ashesi ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitApplication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'SUBMIT APPLICATION',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper method to get the appropriate icon for the document
  Widget _getDocumentIcon() {
    if (_requiredDocument == null) {
      return const Icon(Icons.upload_file, color: Colors.grey, size: 32);
    }

    final extension = path.extension(_requiredDocument!.path).toLowerCase();

    switch (extension) {
      case '.pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32);
      case '.doc':
      case '.docx':
        return const Icon(Icons.description, color: Colors.blue, size: 32);
      default:
        return const Icon(Icons.insert_drive_file,
            color: Colors.amber, size: 32);
    }
  }
}
