import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_dimensions.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  String _selectedDifficulty = 'Medium';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        title: Text(
          'Settings',
          style: AppTextStyles.headlineSmall,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Preferences
            _buildSettingsSection(
              title: 'App Preferences',
              children: [
                SwitchListTile(
                  title: Text(
                    'Push Notifications',
                    style: AppTextStyles.bodyLarge,
                  ),
                  subtitle: Text(
                    'Receive quiz reminders and updates',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                  activeColor: AppColors.primaryPurple,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(
                    'Sound Effects',
                    style: AppTextStyles.bodyLarge,
                  ),
                  subtitle: Text(
                    'Play sounds for correct/wrong answers',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                  },
                  activeColor: AppColors.primaryPurple,
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.paddingXL),

            // Quiz Settings
            _buildSettingsSection(
              title: 'Quiz Settings',
              children: [
                ListTile(
                  title: Text(
                    'Default Difficulty',
                    style: AppTextStyles.bodyLarge,
                  ),
                  subtitle: Text(
                    _selectedDifficulty,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.grey400,
                  ),
                  onTap: () {
                    _showDifficultyDialog();
                  },
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.paddingXL),

            // Data & Storage
            _buildSettingsSection(
              title: 'Data & Storage',
              children: [
                ListTile(
                  title: Text(
                    'Clear Quiz History',
                    style: AppTextStyles.bodyLarge,
                  ),
                  subtitle: Text(
                    'Remove all completed quiz results',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  onTap: () {
                    _showClearDataDialog();
                  },
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.paddingXL),

            // Support
            _buildSettingsSection(
              title: 'Support',
              children: [
                ListTile(
                  title: Text(
                    'Help Center',
                    style: AppTextStyles.bodyLarge,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.grey400,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help center coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(
                    'Contact Support',
                    style: AppTextStyles.bodyLarge,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.grey400,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Contact support coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(
                    'Privacy Policy',
                    style: AppTextStyles.bodyLarge,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.grey400,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Privacy policy coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(
                    'Terms of Service',
                    style: AppTextStyles.bodyLarge,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.grey400,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Terms of service coming soon!')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.paddingXXL),

            // Version Info
            Center(
              child: Column(
                children: [
                  Text(
                    'QuizMaster',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingXXS),
                  Text(
                    'Version 1.0.0',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.paddingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Default Difficulty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Easy'),
              value: 'Easy',
              groupValue: _selectedDifficulty,
              onChanged: (value) {
                setState(() {
                  _selectedDifficulty = value!;
                });
                Navigator.pop(context);
              },
              activeColor: AppColors.primaryPurple,
            ),
            RadioListTile<String>(
              title: const Text('Medium'),
              value: 'Medium',
              groupValue: _selectedDifficulty,
              onChanged: (value) {
                setState(() {
                  _selectedDifficulty = value!;
                });
                Navigator.pop(context);
              },
              activeColor: AppColors.primaryPurple,
            ),
            RadioListTile<String>(
              title: const Text('Hard'),
              value: 'Hard',
              groupValue: _selectedDifficulty,
              onChanged: (value) {
                setState(() {
                  _selectedDifficulty = value!;
                });
                Navigator.pop(context);
              },
              activeColor: AppColors.primaryPurple,
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Quiz History'),
        content: const Text(
          'Are you sure you want to clear all quiz history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Clear quiz history
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quiz history cleared!')),
              );
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
