class Application {
  final int id;
  final int scholarshipId;
  final String scholarshipName;
  final String provider;
  final double amount;
  final String dateOfBirth;
  final String gender;
  final String category;
  final String major;
  final String homeAddress;
  final String studentId;
  final String status;
  final String appliedDate;
  final String passportPhotoPath;
  final String documentPath;

  Application({
    required this.id,
    required this.scholarshipId,
    required this.scholarshipName,
    required this.provider,
    required this.amount,
    required this.dateOfBirth,
    required this.gender,
    required this.category,
    required this.major,
    required this.homeAddress,
    required this.studentId,
    required this.status,
    required this.appliedDate,
    required this.passportPhotoPath,
    required this.documentPath,
  });

  factory Application.fromMap(Map<String, dynamic> map) {
    return Application(
      id: map['id'] as int,
      scholarshipId: map['scholarshipId'] as int,
      scholarshipName: map['scholarshipName'] as String,
      provider: map['provider'] as String,
      amount: map['amount'] is int
          ? (map['amount'] as int).toDouble()
          : map['amount'] as double,
      dateOfBirth: map['dateOfBirth'] as String,
      gender: map['gender'] as String,
      category: map['category'] as String,
      major: map['major'] as String,
      homeAddress: map['homeAddress'] as String,
      studentId: map['studentId'] as String,
      status: map['status'] as String,
      appliedDate: map['appliedDate'] as String,
      passportPhotoPath: map['passportPhotoPath'] as String,
      documentPath: map['documentPath'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scholarshipId': scholarshipId,
      'scholarshipName': scholarshipName,
      'provider': provider,
      'amount': amount,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'category': category,
      'major': major,
      'homeAddress': homeAddress,
      'studentId': studentId,
      'status': status,
      'appliedDate': appliedDate,
      'passportPhotoPath': passportPhotoPath,
      'documentPath': documentPath,
    };
  }
}
