import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int quizCount;
  final int totalQuestions;
  final String difficulty;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.quizCount = 0,
    this.totalQuestions = 0,
    this.difficulty = 'Medium',
    this.isActive = true,
  });

  // Factory constructor to create CategoryModel from Firebase document
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: _getIconFromString(json['icon'] ?? 'help_outline'),
      color: Color(json['color'] ?? 0xFF667EEA),
      quizCount: json['quizCount'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      difficulty: json['difficulty'] ?? 'Medium',
      isActive: json['isActive'] ?? true,
    );
  }

  // Convert CategoryModel to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': _getStringFromIcon(icon),
      'color': color.value,
      'quizCount': quizCount,
      'totalQuestions': totalQuestions,
      'difficulty': difficulty,
      'isActive': isActive,
    };
  }

  // Helper method to convert string to IconData
  static IconData _getIconFromString(String iconName) {
    // Map of common category icons
    final iconMap = {
      'science': Icons.science,
      'history': Icons.history_edu,
      'geography': Icons.public,
      'sports': Icons.sports_basketball,
      'movies_tv': Icons.movie,
      'music': Icons.music_note,
      'technology': Icons.computer,
      'literature': Icons.menu_book,
      'art': Icons.palette,
      'food': Icons.restaurant,
      'nature': Icons.eco,
      'general': Icons.lightbulb,
    };

    return iconMap[iconName] ?? Icons.help_outline;
  }

  // Helper method to convert IconData to string
  static String _getStringFromIcon(IconData icon) {
    // Reverse map of icons to strings
    if (icon == Icons.science) return 'science';
    if (icon == Icons.history_edu) return 'history';
    if (icon == Icons.public) return 'geography';
    if (icon == Icons.sports_basketball) return 'sports';
    if (icon == Icons.movie) return 'movies_tv';
    if (icon == Icons.music_note) return 'music';
    if (icon == Icons.computer) return 'technology';
    if (icon == Icons.menu_book) return 'literature';
    if (icon == Icons.palette) return 'art';
    if (icon == Icons.restaurant) return 'food';
    if (icon == Icons.eco) return 'nature';
    if (icon == Icons.lightbulb) return 'general';
    return 'help_outline';
  }

  // Create a copy with updated fields
  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    int? quizCount,
    int? totalQuestions,
    String? difficulty,
    bool? isActive,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      quizCount: quizCount ?? this.quizCount,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      difficulty: difficulty ?? this.difficulty,
      isActive: isActive ?? this.isActive,
    );
  }

  // Get difficulty color
  Color getDifficultyColor() {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF10B981); // Green
      case 'medium':
        return const Color(0xFFF59E0B); // Orange
      case 'hard':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  // Check if category has quizzes
  bool get hasQuizzes => quizCount > 0;

  // Get average questions per quiz
  double get averageQuestionsPerQuiz {
    if (quizCount == 0) return 0;
    return totalQuestions / quizCount;
  }
}
