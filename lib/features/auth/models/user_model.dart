import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String password;
  final String role; // 'super_admin' | 'admin' | 'student'
  final String?
  adminId; // Null for Super Admin & Admin; holds the Admin's UID for Students
  final String loginMethod;
  final String photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.password,
    this.role = 'student',
    this.adminId,
    required this.loginMethod,
    required this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'adminId': adminId,
      'loginMethod': loginMethod,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? 'student',
      adminId: map['adminId'],
      loginMethod: map['loginMethod'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? password,
    String? role,
    String? adminId,
    String? loginMethod,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      adminId: adminId ?? this.adminId,
      loginMethod: loginMethod ?? this.loginMethod,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
