import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../models/quiz_model.dart';
import '../../../models/category_model.dart';
import '../../../services/admin_service.dart';
import 'edit_quiz_screen.dart';

class ManageQuizzesScreen extends StatefulWidget {
  const ManageQuizzesScreen({super.key});

  @override
  State<ManageQuizzesScreen> createState() => _ManageQuizzesScreenState();
}

class _ManageQuizzesScreenState extends State<ManageQuizzesScreen> {
  String? _selectedCategoryId;
  Map<String, CategoryModel> _categories = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('categories').get();

    setState(() {
      _categories = {
        for (var doc in snapshot.docs)
          doc.id: CategoryModel.fromJson({
            ...doc.data(),
            'id': doc.id,
          })
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Quizzes',
          style: AppTextStyles.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primaryPurple),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditQuizScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          if (_categories.isNotEmpty)
            Container(
              color: AppColors.backgroundWhite,
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Filter by Category',
                  prefixIcon: Icon(Icons.filter_list),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ..._categories.entries.map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value.name),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),
            ),

          // Quiz List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedCategoryId == null
                  ? FirebaseFirestore.instance
                      .collection('quizzes')
                      .orderBy('createdAt', descending: true)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('quizzes')
                      .where('categoryId', isEqualTo: _selectedCategoryId)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 64,
                          color: AppColors.grey300,
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        Text(
                          'No quizzes found',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingL),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditQuizScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Quiz'),
                        ),
                      ],
                    ),
                  );
                }

                final quizzes = snapshot.data!.docs
                    .map((doc) => QuizModel.fromJson({
                          ...doc.data() as Map<String, dynamic>,
                          'id': doc.id,
                        }))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    final category = _categories[quiz.categoryId];
                    return _buildQuizCard(context, quiz, category);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(
      BuildContext context, QuizModel quiz, CategoryModel? category) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(AppDimensions.paddingM),
        childrenPadding: const EdgeInsets.all(AppDimensions.paddingM),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: category?.color.withOpacity(0.15) ?? AppColors.grey200,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: Icon(
            category?.icon ?? Icons.quiz,
            size: 24,
            color: category?.color ?? AppColors.textSecondary,
          ),
        ),
        title: Text(
          quiz.title,
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimensions.paddingXXS),
            Text(
              quiz.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.paddingXS),
            Row(
              children: [
                _buildInfoChip(
                  Icons.category,
                  category?.name ?? 'Unknown',
                ),
                const SizedBox(width: AppDimensions.paddingM),
                _buildInfoChip(
                  Icons.quiz,
                  '${quiz.totalQuestions} questions',
                ),
                const SizedBox(width: AppDimensions.paddingM),
                _buildInfoChip(
                  Icons.signal_cellular_alt,
                  quiz.difficulty,
                  color: _getDifficultyColor(quiz.difficulty),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            _handleQuizAction(context, quiz, value);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Text('Duplicate'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        children: [
          // Questions Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Questions Preview',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingS),
                ...quiz.questions.take(3).map((question) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppDimensions.paddingS),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${quiz.questions.indexOf(question) + 1}.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingS),
                          Expanded(
                            child: Text(
                              question.question,
                              style: AppTextStyles.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                if (quiz.questions.length > 3)
                  Text(
                    '... and ${quiz.questions.length - 3} more questions',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: AppDimensions.iconXS,
          color: color ?? AppColors.textSecondary,
        ),
        const SizedBox(width: AppDimensions.paddingXXS),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: color ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  void _handleQuizAction(BuildContext context, QuizModel quiz, String action) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditQuizScreen(quiz: quiz),
          ),
        );
        break;
      case 'duplicate':
        _duplicateQuiz(context, quiz);
        break;
      case 'delete':
        _deleteQuiz(context, quiz);
        break;
    }
  }

  Future<void> _duplicateQuiz(BuildContext context, QuizModel quiz) async {
    try {
      final newQuiz = QuizModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        categoryId: quiz.categoryId,
        title: '${quiz.title} (Copy)',
        description: quiz.description,
        questions: quiz.questions,
        difficulty: quiz.difficulty,
        createdAt: DateTime.now(),
      );

      await AdminService.createQuiz(newQuiz);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz duplicated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error duplicating quiz: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteQuiz(BuildContext context, QuizModel quiz) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text(
            'Are you sure you want to delete "${quiz.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminService.deleteQuiz(quiz.id, quiz.categoryId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting quiz: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
