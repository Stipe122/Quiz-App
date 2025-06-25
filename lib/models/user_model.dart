import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final int totalPoints;
  final int quizzesCompleted;
  final bool isAdmin;
  final DateTime createdAt;
  final String? photoUrl;
  final Map<String, int> categoryPoints;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.totalPoints = 0,
    this.quizzesCompleted = 0,
    this.isAdmin = false,
    required this.createdAt,
    this.photoUrl,
    Map<String, int>? categoryPoints,
  }) : categoryPoints = categoryPoints ?? {};

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    if (json['createdAt'] != null) {
      if (json['createdAt'] is Timestamp) {
        createdAt = (json['createdAt'] as Timestamp).toDate();
      } else if (json['createdAt'] is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(json['createdAt']);
      } else {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }

    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      totalPoints: json['totalPoints'] ?? 0,
      quizzesCompleted: json['quizzesCompleted'] ?? 0,
      isAdmin: json['isAdmin'] ?? false,
      createdAt: createdAt,
      photoUrl: json['photoUrl'],
      categoryPoints: json['categoryPoints'] != null
          ? Map<String, int>.from(json['categoryPoints'])
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'totalPoints': totalPoints,
      'quizzesCompleted': quizzesCompleted,
      'isAdmin': isAdmin,
      'createdAt': Timestamp.fromDate(createdAt),
      'photoUrl': photoUrl,
      'categoryPoints': categoryPoints,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    int? totalPoints,
    int? quizzesCompleted,
    bool? isAdmin,
    DateTime? createdAt,
    String? photoUrl,
    Map<String, int>? categoryPoints,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      totalPoints: totalPoints ?? this.totalPoints,
      quizzesCompleted: quizzesCompleted ?? this.quizzesCompleted,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      categoryPoints: categoryPoints ?? this.categoryPoints,
    );
  }

  String get initials {
    final nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
      return nameParts[0].substring(0, 2).toUpperCase();
    }
    return 'U';
  }

  int getPointsForCategory(String category) {
    return categoryPoints[category] ?? 0;
  }
}
