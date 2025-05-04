class User {
  final int id;
  final String fullName;
  final String email;
  final String? mobileNumber;
  final String? profileImage;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.mobileNumber,
    this.profileImage,
    this.lastLogin,
  });

  // Factory constructor to create a User object from a JSON map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      mobileNumber: json['mobileNumber'],
      profileImage: json['profileImage'],
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin']) 
          : null,
    );
  }

  // Convert User object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'mobileNumber': mobileNumber,
      'profileImage': profileImage,
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  // Create a copy of the User with updated fields
  User copyWith({
    int? id,
    String? fullName,
    String? email,
    String? mobileNumber,
    String? profileImage,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      profileImage: profileImage ?? this.profileImage,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
} 