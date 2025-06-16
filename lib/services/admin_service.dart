import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';
import '../models/quiz_model.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if current user is admin
  static Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['isAdmin'] ?? false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Category Management
  static Future<void> createCategory(CategoryModel category) async {
    final isUserAdmin = await isAdmin();
    if (!isUserAdmin) throw Exception('Unauthorized: Admin access required');

    await _firestore
        .collection('categories')
        .doc(category.id)
        .set(category.toJson());
  }

  static Future<void> updateCategory(CategoryModel category) async {
    final isUserAdmin = await isAdmin();
    if (!isUserAdmin) throw Exception('Unauthorized: Admin access required');

    await _firestore
        .collection('categories')
        .doc(category.id)
        .update(category.toJson());
  }

  static Future<void> deleteCategory(String categoryId) async {
    final isUserAdmin = await isAdmin();
    if (!isUserAdmin) throw Exception('Unauthorized: Admin access required');

    // Delete all quizzes in this category first
    final quizzes = await _firestore
        .collection('quizzes')
        .where('categoryId', isEqualTo: categoryId)
        .get();

    final batch = _firestore.batch();
    for (var quiz in quizzes.docs) {
      batch.delete(quiz.reference);
    }

    // Delete the category
    batch.delete(_firestore.collection('categories').doc(categoryId));
    await batch.commit();
  }

  // Quiz Management
  static Future<void> createQuiz(QuizModel quiz) async {
    final isUserAdmin = await isAdmin();
    if (!isUserAdmin) throw Exception('Unauthorized: Admin access required');

    await _firestore.collection('quizzes').doc(quiz.id).set(quiz.toJson());

    // Update quiz count in category
    await _firestore.collection('categories').doc(quiz.categoryId).update({
      'quizCount': FieldValue.increment(1),
    });
  }

  static Future<void> updateQuiz(QuizModel quiz) async {
    final isUserAdmin = await isAdmin();
    if (!isUserAdmin) throw Exception('Unauthorized: Admin access required');

    await _firestore.collection('quizzes').doc(quiz.id).update(quiz.toJson());
  }

  static Future<void> deleteQuiz(String quizId, String categoryId) async {
    final isUserAdmin = await isAdmin();
    if (!isUserAdmin) throw Exception('Unauthorized: Admin access required');

    await _firestore.collection('quizzes').doc(quizId).delete();

    // Update quiz count in category
    await _firestore.collection('categories').doc(categoryId).update({
      'quizCount': FieldValue.increment(-1),
    });
  }

  // Get all quiz results (for scoreboards)
  static Stream<QuerySnapshot> getAllQuizResults() {
    return _firestore
        .collection('results')
        .orderBy('completedAt', descending: true)
        .snapshots();
  }

  // Get quiz results by quiz ID
  static Stream<QuerySnapshot> getQuizResults(String quizId) {
    return _firestore
        .collection('results')
        .where('quizId', isEqualTo: quizId)
        .orderBy('scorePercentage', descending: true)
        .snapshots();
  }

  // Dashboard Statistics
  static Future<Map<String, int>> getDashboardStats() async {
    try {
      // Traditional approach - fetch documents and count them
      final usersSnapshot = await _firestore.collection('users').get();
      final categoriesSnapshot =
          await _firestore.collection('categories').get();
      final quizzesSnapshot = await _firestore.collection('quizzes').get();
      final resultsSnapshot = await _firestore.collection('results').get();

      return {
        'totalUsers': usersSnapshot.docs.length,
        'totalCategories': categoriesSnapshot.docs.length,
        'totalQuizzes': quizzesSnapshot.docs.length,
        'quizzesCompleted': resultsSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {
        'totalUsers': 0,
        'totalCategories': 0,
        'totalQuizzes': 0,
        'quizzesCompleted': 0,
      };
    }
  }
}
