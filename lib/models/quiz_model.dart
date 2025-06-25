import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final String categoryId;
  final String title;
  final String description;
  final List<Question> questions;
  final int timeLimit;
  final String difficulty;
  final DateTime createdAt;

  QuizModel({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.questions,
    this.timeLimit = 0,
    required this.difficulty,
    required this.createdAt,
  });

  int get totalQuestions => questions.length;

  factory QuizModel.fromJson(Map<String, dynamic> json) {
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

    return QuizModel(
      id: json['id'] ?? '',
      categoryId: json['categoryId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      questions: (json['questions'] as List? ?? [])
          .map((q) => Question.fromJson(q))
          .toList(),
      timeLimit: json['timeLimit'] ?? 0,
      difficulty: json['difficulty'] ?? 'Medium',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
      'timeLimit': timeLimit,
      'difficulty': difficulty,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class Question {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
      explanation: json['explanation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }

  String get correctAnswer => options[correctAnswerIndex];
}

class QuizResult {
  final String quizId;
  final String quizTitle;
  final String categoryId;
  final int totalQuestions;
  final int correctAnswers;
  final List<int> userAnswers;
  final DateTime completedAt;
  final int timeTaken; // in seconds

  QuizResult({
    required this.quizId,
    required this.quizTitle,
    required this.categoryId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.userAnswers,
    required this.completedAt,
    required this.timeTaken,
  });

  double get scorePercentage => (correctAnswers / totalQuestions) * 100;

  String get grade {
    final percentage = scorePercentage;
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }
}
