import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../models/quiz_model.dart';
import '../../../models/user_model.dart';
import '../../../widgets/common/avatar_widget.dart';
import '../../../services/admin_service.dart';

class AdminScoreboardsScreen extends StatefulWidget {
  const AdminScoreboardsScreen({super.key});

  @override
  State<AdminScoreboardsScreen> createState() => _AdminScoreboardsScreenState();
}

class _AdminScoreboardsScreenState extends State<AdminScoreboardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, QuizModel> _quizzes = {};
  Map<String, UserModel> _users = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Load quizzes
    final quizzesSnapshot =
        await FirebaseFirestore.instance.collection('quizzes').get();

    setState(() {
      _quizzes = {
        for (var doc in quizzesSnapshot.docs)
          doc.id: QuizModel.fromJson({
            ...doc.data(),
            'id': doc.id,
          })
      };
    });

    // Load users
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    setState(() {
      _users = {
        for (var doc in usersSnapshot.docs)
          doc.id: UserModel.fromJson(doc.data())
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
          'Scoreboards',
          style: AppTextStyles.titleLarge,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryPurple,
          tabs: const [
            Tab(text: 'All Results'),
            Tab(text: 'By Quiz'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllResultsTab(),
          _buildByQuizTab(),
        ],
      ),
    );
  }

  Widget _buildAllResultsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: AdminService.getAllQuizResults(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No quiz results yet');
        }

        final results = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
            'completedAt': (data['completedAt'] as Timestamp).toDate(),
          };
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            final user = _users[result['userId']];
            final quiz = _quizzes[result['quizId']];

            return _buildResultCard(
              result: result,
              user: user,
              quiz: quiz,
            );
          },
        );
      },
    );
  }

  Widget _buildByQuizTab() {
    if (_quizzes.isEmpty) {
      return _buildEmptyState('No quizzes available');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: _quizzes.length,
      itemBuilder: (context, index) {
        final quiz = _quizzes.values.elementAt(index);

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
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: const Icon(
                Icons.quiz,
                color: AppColors.primaryPurple,
              ),
            ),
            title: Text(
              quiz.title,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${quiz.totalQuestions} questions • ${quiz.difficulty}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('results')
                    .where('quizId', isEqualTo: quiz.id)
                    .orderBy('correctAnswers', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      child: Text(
                        'No results for this quiz yet',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  final results = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'id': doc.id,
                      ...data,
                      'completedAt':
                          (data['completedAt'] as Timestamp).toDate(),
                    };
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppDimensions.paddingM),
                        child: Text(
                          'Top 10 Scores',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ...results.asMap().entries.map((entry) {
                        final rank = entry.key + 1;
                        final result = entry.value;
                        final user = _users[result['userId']];

                        return _buildLeaderboardItem(
                          rank: rank,
                          user: user,
                          score: result['correctAnswers'],
                          totalQuestions: result['totalQuestions'],
                          timeTaken: result['timeTaken'],
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultCard({
    required Map<String, dynamic> result,
    UserModel? user,
    QuizModel? quiz,
  }) {
    final scorePercentage =
        (result['correctAnswers'] / result['totalQuestions'] * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingL),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (user != null) ...[
                AvatarWidget(
                  initials: user.initials,
                  photoUrl: user.photoUrl,
                  size: 40,
                ),
                const SizedBox(width: AppDimensions.paddingM),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Unknown User',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      quiz?.title ?? 'Unknown Quiz',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                  vertical: AppDimensions.paddingS,
                ),
                decoration: BoxDecoration(
                  color: _getScoreColor(scorePercentage).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Text(
                  '$scorePercentage%',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: _getScoreColor(scorePercentage),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Row(
            children: [
              _buildInfoChip(
                Icons.check_circle,
                '${result['correctAnswers']}/${result['totalQuestions']}',
              ),
              const SizedBox(width: AppDimensions.paddingM),
              _buildInfoChip(
                Icons.timer,
                _formatTime(result['timeTaken']),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              _buildInfoChip(
                Icons.calendar_today,
                _formatDate(result['completedAt']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem({
    required int rank,
    UserModel? user,
    required int score,
    required int totalQuestions,
    required int timeTaken,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: AppTextStyles.labelMedium.copyWith(
                  color:
                      rank <= 3 ? AppColors.textLight : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          if (user != null) ...[
            AvatarWidget(
              initials: user.initials,
              photoUrl: user.photoUrl,
              size: 32,
            ),
            const SizedBox(width: AppDimensions.paddingS),
          ],
          Expanded(
            child: Text(
              user?.name ?? 'Unknown User',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score/$totalQuestions',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPurple,
                ),
              ),
              Text(
                _formatTime(timeTaken),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppDimensions.iconXS,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppDimensions.paddingXXS),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 64,
            color: AppColors.grey300,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            message,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.accentGold;
      case 2:
        return AppColors.grey400;
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.grey300;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
