class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? dateOfBirth;
  final int? age;
  final String? gender;
  final String authProvider;
  final String? providerId;
  final DateTime createdAt;
  final int level;
  final int xp;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.dateOfBirth,
    this.age,
    this.gender,
    required this.authProvider,
    this.providerId,
    required this.createdAt,
    required this.level,
    required this.xp,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      dateOfBirth: json['date_of_birth'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      authProvider: json['auth_provider'] as String,
      providerId: json['provider_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      level: json['level'] as int,
      xp: json['xp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'date_of_birth': dateOfBirth,
      'age': age,
      'gender': gender,
      'auth_provider': authProvider,
      'provider_id': providerId,
      'created_at': createdAt.toIso8601String(),
      'level': level,
      'xp': xp,
    };
  }

  UserModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? dateOfBirth,
    int? age,
    String? gender,
    String? authProvider,
    String? providerId,
    DateTime? createdAt,
    int? level,
    int? xp,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      authProvider: authProvider ?? this.authProvider,
      providerId: providerId ?? this.providerId,
      createdAt: createdAt ?? this.createdAt,
      level: level ?? this.level,
      xp: xp ?? this.xp,
    );
  }

  String get fullName => '$firstName $lastName';
  
  int get xpForNextLevel => level * 100;
  
  double get xpProgress => xp / xpForNextLevel;
}