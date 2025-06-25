import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quizapp/screens/auth/auth_wrapper.dart';
import 'package:quizapp/screens/profile/edit_profile_screen.dart';
import 'package:quizapp/screens/scoreboard/scoreboard_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_dimensions.dart';
import '../../models/user_model.dart';
import '../../widgets/common/avatar_widget.dart';
import '../results/results_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? currentUser;
  int totalQuizzes = 0;
  double avgScore = 0.0;
  int totalTime = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            currentUser = UserModel.fromJson(userDoc.data()!);
          });
        }

        final resultsSnapshot = await FirebaseFirestore.instance
            .collection('results')
            .where('userId', isEqualTo: user.uid)
            .get();

        if (resultsSnapshot.docs.isNotEmpty) {
          final results = resultsSnapshot.docs;
          final scores = results
              .map((doc) =>
                  (doc.data()['scorePercentage'] as num?)?.toDouble() ?? 0.0)
              .toList();
          final times = results
              .map((doc) => (doc.data()['timeTaken'] as num?)?.toInt() ?? 0)
              .toList();

          setState(() {
            totalQuizzes = results.length;
            avgScore = scores.isNotEmpty
                ? scores.reduce((a, b) => a + b) / scores.length
                : 0.0;
            totalTime = times.fold<int>(0, (sum, time) => sum + time);
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          '/auth',
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundWhite,
          elevation: 0,
          title: Text(
            'Profile',
            style: AppTextStyles.headlineSmall,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundWhite,
          elevation: 0,
          title: Text(
            'Profile',
            style: AppTextStyles.headlineSmall,
          ),
        ),
        body: const Center(
          child: Text('Please log in to view your profile'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        title: Text(
          'Profile',
          style: AppTextStyles.headlineSmall,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primaryPurple),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.paddingXL),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    AvatarWidget(
                      initials: currentUser!.initials,
                      photoUrl: currentUser!.photoUrl,
                      size: 100,
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    Text(
                      currentUser!.name,
                      style: AppTextStyles.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingXS),
                    Text(
                      currentUser!.email,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingL),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingL,
                            vertical: AppDimensions.paddingS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusXL),
                          ),
                          child: Text(
                            'Member since ${_formatDate(currentUser!.createdAt)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (currentUser!.isAdmin) ...[
                          const SizedBox(width: AppDimensions.paddingM),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.paddingL,
                              vertical: AppDimensions.paddingS,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusXL),
                            ),
                            child: Text(
                              'ADMIN',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.accentGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXL),
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Quiz Statistics',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingL),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          value: totalQuizzes.toString(),
                          label: 'Quizzes\nTaken',
                        ),
                        _buildStatItem(
                          value: '${avgScore.toInt()}%',
                          label: 'Average\nScore',
                        ),
                        _buildStatItem(
                          value: _formatTotalTime(totalTime),
                          label: 'Total\nTime',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXL),
              _buildMenuSection(
                title: 'Quiz Activity',
                items: [
                  _MenuItemData(
                    icon: Icons.history,
                    title: 'Quiz History',
                    subtitle: 'View your completed quizzes',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResultsHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuItemData(
                    icon: Icons.analytics,
                    title: 'Performance Analytics',
                    subtitle: 'Detailed stats and progress',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Analytics coming soon!')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingM),
              _buildMenuSection(
                title: 'Settings',
                items: [
                  _MenuItemData(
                    icon: Icons.edit,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuItemData(
                    icon: Icons.leaderboard,
                    title: 'Scoreboards',
                    subtitle: 'View quiz rankings and your position',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScoreboardScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingM),
              _buildMenuSection(
                title: 'About',
                items: [
                  _MenuItemData(
                    icon: Icons.info_outline,
                    title: 'About QuizMaster',
                    subtitle: 'App information',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('About QuizMaster'),
                          content: const Text(
                            'QuizMaster v1.0.0\n\n'
                            'Test your knowledge with our fun and educational quizzes!\n\n'
                            'Made with Flutter & Firebase',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingXL),
              ElevatedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentRed,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingM,
                    horizontal: AppDimensions.paddingXL,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingXS),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(
      {required String title, required List<_MenuItemData> items}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
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
          Text(
            title,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          ...items.map(
            (item) => ListTile(
              leading: Icon(item.icon, color: AppColors.primaryPurple),
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: item.onTap,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTotalTime(int seconds) {
    final Duration duration = Duration(seconds: seconds);
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes % 60;
    final int secs = duration.inSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _MenuItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
