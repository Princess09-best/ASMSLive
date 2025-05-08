import 'package:intl/intl.dart';

class Application {
  final int id;
  final int scholarshipId;
  final int userId;
  final String status; // submitted, under-review, approved, rejected
  final DateTime submissionDate;
  final List<Document> documents;
  final String? reviewNotes;
  final DateTime? reviewDate;
  final String? scholarshipName; // For convenience, included from scholarship
  final String? providerName; // For convenience, included from scholarship

  Application({
    required this.id,
    required this.scholarshipId,
    required this.userId,
    required this.status,
    required this.submissionDate,
    required this.documents,
    this.reviewNotes,
    this.reviewDate,
    this.scholarshipName,
    this.providerName,
  });

  // Factory constructor to create an Application object from a JSON map
  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'],
      scholarshipId: json['scholarshipId'],
      userId: json['userId'],
      status: json['status'],
      submissionDate: DateTime.parse(json['submissionDate']),
      documents: json['documents'] != null
          ? List<Document>.from(
              json['documents'].map((doc) => Document.fromJson(doc)))
          : [],
      reviewNotes: json['reviewNotes'],
      reviewDate: json['reviewDate'] != null
          ? DateTime.parse(json['reviewDate'])
          : null,
      scholarshipName: json['scholarshipName'],
      providerName: json['providerName'],
    );
  }

  // Convert Application object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scholarshipId': scholarshipId,
      'userId': userId,
      'status': status,
      'submissionDate': submissionDate.toIso8601String(),
      'documents': documents.map((doc) => doc.toJson()).toList(),
      'reviewNotes': reviewNotes,
      'reviewDate': reviewDate?.toIso8601String(),
      'scholarshipName': scholarshipName,
      'providerName': providerName,
    };
  }

  // Get formatted submission date
  String get formattedSubmissionDate {
    return DateFormat('MMM dd, yyyy').format(submissionDate);
  }

  // Get formatted review date if available
  String? get formattedReviewDate {
    return reviewDate != null
        ? DateFormat('MMM dd, yyyy').format(reviewDate!)
        : null;
  }

  // Get status color
  String get statusColor {
    switch (status) {
      case 'submitted':
        return '#3498db'; // Blue
      case 'under-review':
        return '#f39c12'; // Orange
      case 'approved':
        return '#2ecc71'; // Green
      case 'rejected':
        return '#e74c3c'; // Red
      default:
        return '#95a5a6'; // Gray
    }
  }

  // Get formatted status text
  String get formattedStatus {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'under-review':
        return 'Under Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}

class Document {
  final int id;
  final int applicationId;
  final String name;
  final String type; // ID, transcript, recommendation, etc.
  final String filePath;
  final DateTime uploadDate;
  final String status; // pending, verified, rejected
  final String? verificationNotes;

  Document({
    required this.id,
    required this.applicationId,
    required this.name,
    required this.type,
    required this.filePath,
    required this.uploadDate,
    required this.status,
    this.verificationNotes,
  });

  // Factory constructor to create a Document object from a JSON map
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      applicationId: json['applicationId'],
      name: json['name'],
      type: json['type'],
      filePath: json['filePath'],
      uploadDate: DateTime.parse(json['uploadDate']),
      status: json['status'],
      verificationNotes: json['verificationNotes'],
    );
  }

  // Convert Document object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'applicationId': applicationId,
      'name': name,
      'type': type,
      'filePath': filePath,
      'uploadDate': uploadDate.toIso8601String(),
      'status': status,
      'verificationNotes': verificationNotes,
    };
  }

  // Get file extension
  String get fileExtension {
    return filePath.split('.').last.toLowerCase();
  }

  // Check if document is an image
  bool get isImage {
    final imgExtensions = ['jpg', 'jpeg', 'png', 'gif'];
    return imgExtensions.contains(fileExtension);
  }

  // Check if document is a PDF
  bool get isPdf {
    return fileExtension == 'pdf';
  }

  // Get formatted upload date
  String get formattedUploadDate {
    return DateFormat('MMM dd, yyyy').format(uploadDate);
  }
}
