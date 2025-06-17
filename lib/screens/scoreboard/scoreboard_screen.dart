import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_dimensions.dart';
import '../../models/user_model.dart';
import '../../models/quiz_model.dart';
import '../../widgets/common/avatar_widget.dart';

class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedQuizId;
  Map<String, QuizModel> _quizzes = {};
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQuizzes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizzes() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('quizzes').get();

    setState(() {
      _quizzes = {
        for (var doc in snapshot.docs)
          doc.id: QuizModel.fromJson({
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
          'Scoreboards',
          style: AppTextStyles.titleLarge,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryPurple,
          tabs: const [
            Tab(text: 'Overall'),
            Tab(text: 'By Quiz'),
            Tab(text: 'My Position'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverallLeaderboard(),
          _buildQuizLeaderboard(),
          _buildMyPosition(),
        ],
      ),
    );
  }

  Widget _buildOverallLeaderboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('totalPoints', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No users found');
        }

        final users = snapshot.data!.docs
            .map(
                (doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final isCurrentUser = user.uid == _currentUserId;

            return _buildLeaderboardItem(
              rank: index + 1,
              user: user,
              points: user.totalPoints,
              quizzesCompleted: user.quizzesCompleted,
              isCurrentUser: isCurrentUser,
            );
          },
        );
      },
    );
  }

  Widget _buildQuizLeaderboard() {
    return Column(
      children: [
        // Quiz Selector
        Container(
          color: AppColors.backgroundWhite,
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: DropdownButtonFormField<String>(
            value: _selectedQuizId,
            decoration: const InputDecoration(
              labelText: 'Select Quiz',
              prefixIcon: Icon(Icons.quiz),
            ),
            items: _quizzes.entries
                .map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value.title),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedQuizId = value;
              });
            },
          ),
        ),

        // Leaderboard
        if (_selectedQuizId != null)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('results')
                  .where('quizId', isEqualTo: _selectedQuizId)
                  .orderBy('correctAnswers', descending: true)
                  .orderBy('timeTaken')
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState('No results for this quiz');
                }

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadUsersForResults(snapshot.data!.docs),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      itemCount: userSnapshot.data!.length,
                      itemBuilder: (context, index) {
                        final data = userSnapshot.data![index];
                        final isCurrentUser = data['userId'] == _currentUserId;

                        return _buildQuizLeaderboardItem(
                          rank: index + 1,
                          userName: data['userName'],
                          userPhotoUrl: data['userPhotoUrl'],
                          score: data['correctAnswers'],
                          totalQuestions: data['totalQuestions'],
                          timeTaken: data['timeTaken'],
                          isCurrentUser: isCurrentUser,
                        );
                      },
                    );
                  },
                );
              },
            ),
          )
        else
          Expanded(
            child: Center(
              child: Text(
                'Select a quiz to view its leaderboard',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMyPosition() {
    if (_currentUserId == null) {
      return Center(
        child: Text(
          'Please login to view your position',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          // Overall Stats Card
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(_currentUserId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final userData = UserModel.fromJson(
                  snapshot.data!.data() as Map<String, dynamic>);

              return Container(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    AvatarWidget(
                      initials: userData.initials,
                      photoUrl: userData.photoUrl,
                      size: 80,
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    Text(
                      userData.name,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingL),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          'Total Points',
                          userData.totalPoints.toString(),
                          Icons.star,
                        ),
                        _buildStatColumn(
                          'Quizzes',
                          userData.quizzesCompleted.toString(),
                          Icons.quiz,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: AppDimensions.paddingXL),

          // Recent Results
          Text(
            'Your Recent Results',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('results')
                .where('userId', isEqualTo: _currentUserId)
                .orderBy('completedAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingXL),
                  child: Text(
                    'No quiz results yet',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final quiz = _quizzes[data['quizId']];
                  final scorePercentage =
                      (data['correctAnswers'] / data['totalQuestions'] * 100)
                          .toInt();

                  return Container(
                    margin:
                        const EdgeInsets.only(bottom: AppDimensions.paddingM),
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusL),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _getScoreColor(scorePercentage)
                                .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusM),
                          ),
                          child: Center(
                            child: Text(
                              '$scorePercentage%',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: _getScoreColor(scorePercentage),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.paddingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quiz?.title ?? 'Unknown Quiz',
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.paddingXXS),
                              Text(
                                '${data['correctAnswers']}/${data['totalQuestions']} correct • ${_formatTime(data['timeTaken'])}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem({
    required int rank,
    required UserModel user,
    required int points,
    required int quizzesCompleted,
    required bool isCurrentUser,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primaryPurple.withOpacity(0.1)
            : AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: isCurrentUser
            ? Border.all(color: AppColors.primaryPurple, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(
                      Icons.emoji_events,
                      color: AppColors.textLight,
                      size: 20,
                    )
                  : Text(
                      rank.toString(),
                      style: AppTextStyles.titleSmall.copyWith(
                        color: rank <= 10
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),

          // User Info
          AvatarWidget(
            initials: user.initials,
            photoUrl: user.photoUrl,
            size: 40,
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name + (isCurrentUser ? ' (You)' : ''),
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$quizzesCompleted quizzes completed',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                points.toString(),
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPurple,
                ),
              ),
              Text(
                'points',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuizLeaderboardItem({
    required int rank,
    required String userName,
    String? userPhotoUrl,
    required int score,
    required int totalQuestions,
    required int timeTaken,
    required bool isCurrentUser,
  }) {
    final scorePercentage = (score / totalQuestions * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primaryPurple.withOpacity(0.1)
            : AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: isCurrentUser
            ? Border.all(color: AppColors.primaryPurple, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(
                      Icons.emoji_events,
                      color: AppColors.textLight,
                      size: 20,
                    )
                  : Text(
                      rank.toString(),
                      style: AppTextStyles.titleSmall.copyWith(
                        color: rank <= 10
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),

          // User Info
          AvatarWidget(
            initials: _getInitials(userName),
            photoUrl: userPhotoUrl,
            size: 40,
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName + (isCurrentUser ? ' (You)' : ''),
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Time: ${_formatTime(timeTaken)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score/$totalQuestions',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(scorePercentage),
                ),
              ),
              Text(
                '$scorePercentage%',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.textLight,
          size: AppDimensions.iconL,
        ),
        const SizedBox(height: AppDimensions.paddingS),
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textLight.withOpacity(0.8),
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

  Future<List<Map<String, dynamic>>> _loadUsersForResults(
      List<QueryDocumentSnapshot> results) async {
    final List<Map<String, dynamic>> enrichedResults = [];

    for (var result in results) {
      final data = result.data() as Map<String, dynamic>;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(data['userId'])
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        enrichedResults.add({
          ...data,
          'userName': userData['name'] ?? 'Unknown User',
          'userPhotoUrl': userData['photoUrl'],
        });
      } else {
        enrichedResults.add({
          ...data,
          'userName': 'Unknown User',
          'userPhotoUrl': null,
        });
      }
    }

    return enrichedResults;
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
        if (rank <= 10) return AppColors.primaryPurple;
        return AppColors.grey300;
    }
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }

  String _getInitials(String name) {
    final nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
      return nameParts[0].substring(0, 2).toUpperCase();
    }
    return 'U';
  }
}
