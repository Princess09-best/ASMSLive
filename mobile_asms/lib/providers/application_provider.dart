import 'dart:io';
import 'package:flutter/material.dart';
import '../models/application_model.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';
import '../services/notification_service.dart';
import '../config/api_config.dart';

class ApplicationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final CameraService _cameraService = CameraService();
  final NotificationService _notificationService = NotificationService();

  List<Application> _applications = [];
  Application? _selectedApplication;
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<Application> get applications => _applications;
  Application? get selectedApplication => _selectedApplication;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Fetch user applications
  Future<void> fetchApplications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get(ApiConfig.applications);

      final List<dynamic> applicationData = response['data']['applications'];
      _applications =
          applicationData.map((data) => Application.fromJson(data)).toList();

      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get application details
  Future<void> getApplicationDetails(int applicationId) async {
    _isLoading = true;
    _selectedApplication = null;
    notifyListeners();

    try {
      final response = await _apiService.get(
        '${ApiConfig.applicationDetails}/$applicationId',
      );

      _selectedApplication = Application.fromJson(response['data']);
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Submit new application
  Future<bool> submitApplication(
      int scholarshipId, Map<String, dynamic> formData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = {
        'scholarshipId': scholarshipId,
        ...formData,
      };

      final response = await _apiService.post(
        ApiConfig.submitApplication,
        data,
      );

      // Add the new application to the list
      final Application newApplication = Application.fromJson(response['data']);
      _applications.add(newApplication);

      // Show notification for application submission
      await _notificationService.showApplicationStatusNotification(
        applicationId: newApplication.id,
        scholarshipName: newApplication.scholarshipName ?? 'Scholarship',
        status: newApplication.status,
      );

      _errorMessage = '';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Upload document for application
  Future<bool> uploadDocument(
    int applicationId,
    String documentType,
    File file,
    String documentName,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fields = {
        'applicationId': applicationId.toString(),
        'type': documentType,
        'name': documentName,
      };

      final response = await _apiService.uploadFile(
        ApiConfig.uploadDocument,
        file,
        fields: fields,
      );

      // If this document is for the selected application, update it
      if (_selectedApplication != null &&
          _selectedApplication!.id == applicationId) {
        final Document newDocument = Document.fromJson(response['data']);

        // Create a new list with the added document
        final updatedDocuments = [
          ..._selectedApplication!.documents,
          newDocument
        ];

        // Update the selected application
        _selectedApplication = Application(
          id: _selectedApplication!.id,
          scholarshipId: _selectedApplication!.scholarshipId,
          userId: _selectedApplication!.userId,
          status: _selectedApplication!.status,
          submissionDate: _selectedApplication!.submissionDate,
          documents: updatedDocuments,
          reviewNotes: _selectedApplication!.reviewNotes,
          reviewDate: _selectedApplication!.reviewDate,
          scholarshipName: _selectedApplication!.scholarshipName,
          providerName: _selectedApplication!.providerName,
        );
      }

      _errorMessage = '';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Take document photo and upload
  Future<bool> takeDocumentPhotoAndUpload(
    int applicationId,
    String documentType,
    String documentName,
    BuildContext context,
  ) async {
    try {
      // Show image picker dialog
      final File? image = await _cameraService.showImagePickerDialog(context);

      if (image == null) {
        return false;
      }

      // Upload the image as a document
      return await uploadDocument(
        applicationId,
        documentType,
        image,
        documentName,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get application status
  Future<String> checkApplicationStatus(int applicationId) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.applicationStatus}/$applicationId',
      );

      final status = response['data']['status'];

      // If the application exists in our list, update its status
      final applicationIndex =
          _applications.indexWhere((app) => app.id == applicationId);
      if (applicationIndex != -1) {
        final updatedApplication = Application(
          id: _applications[applicationIndex].id,
          scholarshipId: _applications[applicationIndex].scholarshipId,
          userId: _applications[applicationIndex].userId,
          status: status,
          submissionDate: _applications[applicationIndex].submissionDate,
          documents: _applications[applicationIndex].documents,
          reviewNotes: response['data']['reviewNotes'],
          reviewDate: response['data']['reviewDate'] != null
              ? DateTime.parse(response['data']['reviewDate'])
              : null,
          scholarshipName: _applications[applicationIndex].scholarshipName,
          providerName: _applications[applicationIndex].providerName,
        );

        _applications[applicationIndex] = updatedApplication;

        // If this is the selected application, update it too
        if (_selectedApplication != null &&
            _selectedApplication!.id == applicationId) {
          _selectedApplication = updatedApplication;
        }

        notifyListeners();
      }

      return status;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return '';
    }
  }

  // Set selected application
  void setSelectedApplication(Application application) {
    _selectedApplication = application;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Clear selected application
  void clearSelectedApplication() {
    _selectedApplication = null;
    notifyListeners();
  }

  // Filter applications by status
  List<Application> filterApplicationsByStatus(String status) {
    return _applications
        .where((application) => application.status == status)
        .toList();
  }
}
