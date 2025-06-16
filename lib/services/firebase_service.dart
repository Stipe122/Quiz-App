import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/quiz_model.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Get user data
  static Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Get all categories
  static Future<List<CategoryModel>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      return snapshot.docs
          .map((doc) => CategoryModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  // Get quizzes for a category
  static Future<List<QuizModel>> getQuizzesForCategory(
      String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection('quizzes')
          .where('categoryId', isEqualTo: categoryId)
          .get();
      return snapshot.docs
          .map((doc) => QuizModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting quizzes: $e');
      return [];
    }
  }

  // Save quiz result
  static Future<void> saveQuizResult(QuizResult result) async {
    try {
      // Save result
      await _firestore.collection('results').add({
        'userId': currentUser!.uid,
        'quizId': result.quizId,
        'quizTitle': result.quizTitle,
        'categoryId': result.categoryId,
        'totalQuestions': result.totalQuestions,
        'correctAnswers': result.correctAnswers,
        'userAnswers': result.userAnswers,
        'completedAt': result.completedAt,
        'timeTaken': result.timeTaken,
      });

      // Update user stats
      final userRef = _firestore.collection('users').doc(currentUser!.uid);
      await userRef.update({
        'quizzesCompleted': FieldValue.increment(1),
        'totalPoints': FieldValue.increment(result.correctAnswers * 10),
      });
    } catch (e) {
      print('Error saving quiz result: $e');
    }
  }

  // Get user results
  static Future<List<QuizResult>> getUserResults() async {
    try {
      final snapshot = await _firestore
          .collection('results')
          .where('userId', isEqualTo: currentUser!.uid)
          .orderBy('completedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return QuizResult(
          quizId: data['quizId'],
          quizTitle: data['quizTitle'],
          categoryId: data['categoryId'],
          totalQuestions: data['totalQuestions'],
          correctAnswers: data['correctAnswers'],
          userAnswers: List<int>.from(data['userAnswers']),
          completedAt: (data['completedAt'] as Timestamp).toDate(),
          timeTaken: data['timeTaken'],
        );
      }).toList();
    } catch (e) {
      print('Error getting user results: $e');
      return [];
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    required String name,
    String? photoUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  // Logout
  static Future<void> logout() async {
    await _auth.signOut();
  }
}
