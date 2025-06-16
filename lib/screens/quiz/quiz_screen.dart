import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_dimensions.dart';
import '../../models/quiz_model.dart';
import '../../models/category_model.dart';
import '../results/quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final QuizModel quiz;
  final CategoryModel category;

  const QuizScreen({
    super.key,
    required this.quiz,
    required this.category,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  List<int> userAnswers = [];
  int? selectedAnswer;
  Timer? timer;
  int elapsedSeconds = 0;
  bool showFeedback = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    userAnswers = List.filled(widget.quiz.questions.length, -1);
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        elapsedSeconds++;
      });
    });
  }

  void selectAnswer(int index) {
    if (showFeedback) return;

    setState(() {
      selectedAnswer = index;
      userAnswers[currentQuestionIndex] = index;
      showFeedback = true;
    });

    // Auto-proceed after showing feedback
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && showFeedback) {
        nextQuestion();
      }
    });
  }

  void nextQuestion() {
    if (currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = userAnswers[currentQuestionIndex] != -1
            ? userAnswers[currentQuestionIndex]
            : null;
        showFeedback = false;
      });
    } else {
      finishQuiz();
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        selectedAnswer = userAnswers[currentQuestionIndex] != -1
            ? userAnswers[currentQuestionIndex]
            : null;
        showFeedback = false;
      });
    }
  }

  Future<void> finishQuiz() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    timer?.cancel();

    // Calculate correct answers
    int correctAnswers = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      if (userAnswers[i] == widget.quiz.questions[i].correctAnswerIndex) {
        correctAnswers++;
      }
    }

    final result = QuizResult(
      quizId: widget.quiz.id,
      quizTitle: widget.quiz.title,
      categoryId: widget.category.id,
      totalQuestions: widget.quiz.questions.length,
      correctAnswers: correctAnswers,
      userAnswers: userAnswers,
      completedAt: DateTime.now(),
      timeTaken: elapsedSeconds,
    );

    // Save result to Firebase
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Save quiz result
        await FirebaseFirestore.instance.collection('results').add({
          'userId': user.uid,
          'quizId': result.quizId,
          'quizTitle': result.quizTitle,
          'categoryId': result.categoryId,
          'totalQuestions': result.totalQuestions,
          'correctAnswers': result.correctAnswers,
          'userAnswers': result.userAnswers,
          'completedAt': result.completedAt,
          'timeTaken': result.timeTaken,
          'scorePercentage': result.scorePercentage,
        });

        // Update user stats
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'quizzesCompleted': FieldValue.increment(1),
          'totalPoints': FieldValue.increment(correctAnswers * 10),
          'categoryPoints.${widget.category.id}':
              FieldValue.increment(correctAnswers * 10),
        });
      }
    } catch (e) {
      print('Error saving quiz result: $e');
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(
            result: result,
            quiz: widget.quiz,
            category: widget.category,
          ),
        ),
      );
    }
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.quiz.questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / widget.quiz.questions.length;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Quit Quiz?'),
                content: const Text(
                    'Are you sure you want to quit? Your progress will be lost.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Quit',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            );
          },
        ),
        title: Text(
          widget.quiz.title,
          style: AppTextStyles.titleMedium,
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: AppDimensions.paddingM),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingXS,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: AppDimensions.iconS,
                    color: AppColors.primaryPurple,
                  ),
                  const SizedBox(width: AppDimensions.paddingXXS),
                  Text(
                    formatTime(elapsedSeconds),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          Container(
            height: 8,
            color: AppColors.grey200,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Number
                  Text(
                    'Question ${currentQuestionIndex + 1} of ${widget.quiz.questions.length}',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),

                  // Question
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
                    child: Text(
                      currentQuestion.question,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.paddingXL),

                  // Options
                  ...List.generate(
                    currentQuestion.options.length,
                    (index) => _buildOptionCard(
                      option: currentQuestion.options[index],
                      index: index,
                      isSelected: selectedAnswer == index,
                      isCorrect: index == currentQuestion.correctAnswerIndex,
                      showFeedback: showFeedback,
                    ),
                  ),

                  if (showFeedback && currentQuestion.explanation != null) ...[
                    const SizedBox(height: AppDimensions.paddingL),
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusM),
                        border: Border.all(
                          color: AppColors.info.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: AppDimensions.iconS,
                          ),
                          const SizedBox(width: AppDimensions.paddingS),
                          Expanded(
                            child: Text(
                              currentQuestion.explanation!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                if (currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: showFeedback ? null : previousQuestion,
                      child: const Text('Previous'),
                    ),
                  ),
                if (currentQuestionIndex > 0)
                  const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedAnswer != null && !isLoading
                        ? currentQuestionIndex ==
                                widget.quiz.questions.length - 1
                            ? finishQuiz
                            : (showFeedback ? nextQuestion : null)
                        : null,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textLight,
                              ),
                            ),
                          )
                        : Text(
                            currentQuestionIndex ==
                                    widget.quiz.questions.length - 1
                                ? 'Finish'
                                : 'Next',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String option,
    required int index,
    required bool isSelected,
    required bool isCorrect,
    required bool showFeedback,
  }) {
    Color? backgroundColor;
    Color? borderColor;
    IconData? icon;

    if (showFeedback) {
      if (isCorrect) {
        backgroundColor = AppColors.success.withOpacity(0.1);
        borderColor = AppColors.success;
        icon = Icons.check_circle;
      } else if (isSelected && !isCorrect) {
        backgroundColor = AppColors.error.withOpacity(0.1);
        borderColor = AppColors.error;
        icon = Icons.cancel;
      }
    } else if (isSelected) {
      backgroundColor = AppColors.primaryPurple.withOpacity(0.1);
      borderColor = AppColors.primaryPurple;
    }

    return GestureDetector(
      onTap: showFeedback ? null : () => selectAnswer(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(
            color: borderColor ?? AppColors.grey300,
            width: borderColor != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: borderColor ?? AppColors.grey300,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: AppTextStyles.labelMedium.copyWith(
                    color: borderColor != null
                        ? AppColors.textLight
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: Text(
                option,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (icon != null)
              Icon(
                icon,
                color: borderColor,
                size: AppDimensions.iconM,
              ),
          ],
        ),
      ),
    );
  }
}
