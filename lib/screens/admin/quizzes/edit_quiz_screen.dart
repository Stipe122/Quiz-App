import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../models/quiz_model.dart';
import '../../../models/category_model.dart';
import '../../../services/admin_service.dart';
import '../../../widgets/common/gradient_button.dart';

class EditQuizScreen extends StatefulWidget {
  final QuizModel? quiz;

  const EditQuizScreen({super.key, this.quiz});

  @override
  State<EditQuizScreen> createState() => _EditQuizScreenState();
}

class _EditQuizScreenState extends State<EditQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategoryId;
  String _selectedDifficulty = 'Medium';
  List<Question> _questions = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    if (widget.quiz != null) {
      _titleController.text = widget.quiz!.title;
      _descriptionController.text = widget.quiz!.description;
      _selectedCategoryId = widget.quiz!.categoryId;
      _selectedDifficulty = widget.quiz!.difficulty;
      _questions = List.from(widget.quiz!.questions);
    } else {
      // Start with one empty question
      _questions.add(Question(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        question: '',
        options: ['', '', '', ''],
        correctAnswerIndex: 0,
      ));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .get();

    setState(() {
      _categories = snapshot.docs
          .map((doc) => CategoryModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    });
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate questions
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check if all questions are valid
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.question.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question ${i + 1} is empty'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (q.options.any((opt) => opt.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question ${i + 1} has empty options'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final quiz = QuizModel(
        id: widget.quiz?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        categoryId: _selectedCategoryId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        questions: _questions,
        difficulty: _selectedDifficulty,
        createdAt: widget.quiz?.createdAt ?? DateTime.now(),
      );

      if (widget.quiz == null) {
        await AdminService.createQuiz(quiz);
      } else {
        await AdminService.updateQuiz(quiz);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.quiz == null
                ? 'Quiz created successfully'
                : 'Quiz updated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(Question(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        question: '',
        options: ['', '', '', ''],
        correctAnswerIndex: 0,
      ));
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
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
          widget.quiz == null ? 'Create Quiz' : 'Edit Quiz',
          style: AppTextStyles.titleLarge,
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveQuiz,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? AppColors.grey400 : AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info Section
              Container(
                color: AppColors.backgroundWhite,
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingM),

                    // Quiz Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Quiz Title',
                        hintText: 'Enter quiz title',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter quiz title';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppDimensions.paddingL),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter quiz description',
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppDimensions.paddingL),

                    // Category Selection
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories
                          .map((category) => DropdownMenuItem(
                                value: category.id,
                                child: Text(category.name),
                              ))
                          .toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    ),

                    const SizedBox(height: AppDimensions.paddingL),

                    // Difficulty Selection
                    DropdownButtonFormField<String>(
                      value: _selectedDifficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                        prefixIcon: Icon(Icons.signal_cellular_alt),
                      ),
                      items: ['Easy', 'Medium', 'Hard']
                          .map(
                            (difficulty) => DropdownMenuItem(
                              value: difficulty,
                              child: Text(difficulty),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDifficulty = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.paddingM),

              // Questions Section
              Container(
                color: AppColors.backgroundWhite,
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Questions (${_questions.length})',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          onPressed: _addQuestion,
                          icon: const Icon(Icons.add_circle,
                              color: AppColors.primaryPurple),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingM),

                    // Questions List
                    ..._questions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final question = entry.value;

                      return _buildQuestionCard(index, question);
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.paddingXL),

              // Save Button (Mobile)
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: GradientButton(
                  text: widget.quiz == null ? 'Create Quiz' : 'Save Changes',
                  onPressed: _saveQuiz,
                  width: double.infinity,
                  height: AppDimensions.buttonHeightL,
                  isLoading: _isLoading,
                ),
              ),

              const SizedBox(height: AppDimensions.paddingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, Question question) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingL),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${index + 1}',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_questions.length > 1)
                IconButton(
                  onPressed: () => _removeQuestion(index),
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  iconSize: 20,
                ),
            ],
          ),

          const SizedBox(height: AppDimensions.paddingM),

          // Question Text
          TextFormField(
            initialValue: question.question,
            decoration: const InputDecoration(
              labelText: 'Question',
              hintText: 'Enter the question',
            ),
            onChanged: (value) {
              setState(() {
                _questions[index] = Question(
                  id: question.id,
                  question: value,
                  options: question.options,
                  correctAnswerIndex: question.correctAnswerIndex,
                  explanation: question.explanation,
                );
              });
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a question';
              }
              return null;
            },
          ),

          const SizedBox(height: AppDimensions.paddingM),

          // Options
          Text(
            'Options',
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: AppDimensions.paddingS),

          ...List.generate(4, (optionIndex) {
            final isCorrect = question.correctAnswerIndex == optionIndex;

            return Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
              child: Row(
                children: [
                  Radio<int>(
                    value: optionIndex,
                    groupValue: question.correctAnswerIndex,
                    onChanged: (value) {
                      setState(() {
                        _questions[index] = Question(
                          id: question.id,
                          question: question.question,
                          options: question.options,
                          correctAnswerIndex: value!,
                          explanation: question.explanation,
                        );
                      });
                    },
                    activeColor: AppColors.success,
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: question.options[optionIndex],
                      decoration: InputDecoration(
                        labelText:
                            'Option ${String.fromCharCode(65 + optionIndex)}',
                        hintText: 'Enter option',
                        suffixIcon: isCorrect
                            ? const Icon(Icons.check_circle,
                                color: AppColors.success)
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          final newOptions =
                              List<String>.from(question.options);
                          newOptions[optionIndex] = value;
                          _questions[index] = Question(
                            id: question.id,
                            question: question.question,
                            options: newOptions,
                            correctAnswerIndex: question.correctAnswerIndex,
                            explanation: question.explanation,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: AppDimensions.paddingM),

          // Explanation (Optional)
          TextFormField(
            initialValue: question.explanation,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Explanation (Optional)',
              hintText: 'Explain why this answer is correct',
              prefixIcon: Icon(Icons.info_outline),
              alignLabelWithHint: true,
            ),
            onChanged: (value) {
              setState(() {
                _questions[index] = Question(
                  id: question.id,
                  question: question.question,
                  options: question.options,
                  correctAnswerIndex: question.correctAnswerIndex,
                  explanation: value.isEmpty ? null : value,
                );
              });
            },
          ),
        ],
      ),
    );
  }
}
