class Scholarship {
  final int id;
  final String name;
  final String provider;
  final double amount;
  final String deadline;
  final String location;
  final double distance;

  Scholarship({
    required this.id,
    required this.name,
    required this.provider,
    required this.amount,
    required this.deadline,
    required this.location,
    required this.distance,
  });

  factory Scholarship.fromJson(Map<String, dynamic> json) {
    return Scholarship(
      id: json['id'] as int,
      name: json['name'] as String,
      provider: json['provider'] as String,
      amount: (json['amount'] is int)
          ? (json['amount'] as int).toDouble()
          : json['amount'] as double,
      deadline: json['deadline'] as String,
      location: json['location'] as String,
      distance: (json['distance'] is int)
          ? (json['distance'] as int).toDouble()
          : json['distance'] as double,
    );
  }

  factory Scholarship.fromMap(Map<String, dynamic> map) {
    return Scholarship(
      id: map['id'] as int,
      name: map['name'] as String,
      provider: map['provider'] as String,
      amount: (map['amount'] is int)
          ? (map['amount'] as int).toDouble()
          : map['amount'] as double,
      deadline: map['deadline'] as String,
      location: map['location'] as String,
      distance: (map['distance'] is int)
          ? (map['distance'] as int).toDouble()
          : map['distance'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider,
      'amount': amount,
      'deadline': deadline,
      'location': location,
      'distance': distance,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'provider': provider,
      'amount': amount,
      'deadline': deadline,
      'location': location,
      'distance': distance,
    };
  }
}
