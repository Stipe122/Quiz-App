import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_dimensions.dart';
import '../../models/quiz_model.dart';
import '../../models/category_model.dart';
import '../../widgets/common/gradient_button.dart';
import '../navigation/main_navigation.dart';

class QuizResultScreen extends StatelessWidget {
  final QuizResult result;
  final QuizModel quiz;
  final CategoryModel category;

  const QuizResultScreen({
    super.key,
    required this.result,
    required this.quiz,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = result.scorePercentage;
    final isPassed = percentage >= 60;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quiz Complete!',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainNavigation(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isPassed
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.success.withOpacity(0.8),
                                  AppColors.success,
                                ],
                              )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.error.withOpacity(0.8),
                                  AppColors.error,
                                ],
                              ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isPassed ? AppColors.success : AppColors.error)
                                    .withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${percentage.toInt()}%',
                            style: AppTextStyles.displayMedium.copyWith(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Score',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textLight.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingXL),
                    Text(
                      'Grade: ${result.grade}',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPassed ? AppColors.success : AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    Text(
                      isPassed
                          ? 'Congratulations! You passed the quiz!'
                          : 'Keep practicing! You can do better!',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.paddingXL),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.check_circle,
                            value: '${result.correctAnswers}',
                            label: 'Correct',
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.paddingM),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.cancel,
                            value:
                                '${result.totalQuestions - result.correctAnswers}',
                            label: 'Wrong',
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.timer,
                            value: _formatTime(result.timeTaken),
                            label: 'Time',
                            color: AppColors.primaryPurple,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.paddingM),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.category,
                            value: category.name,
                            label: 'Category',
                            color: category.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingXL),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.paddingL),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Answer Summary',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                          Wrap(
                            spacing: AppDimensions.paddingS,
                            runSpacing: AppDimensions.paddingS,
                            children: List.generate(
                              quiz.questions.length,
                              (index) => Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: result.userAnswers[index] ==
                                          quiz.questions[index]
                                              .correctAnswerIndex
                                      ? AppColors.success.withOpacity(0.2)
                                      : AppColors.error.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusS),
                                  border: Border.all(
                                    color: result.userAnswers[index] ==
                                            quiz.questions[index]
                                                .correctAnswerIndex
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: result.userAnswers[index] ==
                                              quiz.questions[index]
                                                  .correctAnswerIndex
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingXL),
                    GradientButton(
                      text: 'Try Another Quiz',
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainNavigation(),
                          ),
                          (route) => false,
                        );
                      },
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: AppDimensions.iconL,
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }
}
