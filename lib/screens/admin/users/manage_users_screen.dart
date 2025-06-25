import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../models/user_model.dart';
import '../../../widgets/common/avatar_widget.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

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
          'Manage Users',
          style: AppTextStyles.titleLarge,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
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
                    Icons.people_outline,
                    size: 64,
                    color: AppColors.grey300,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  Text(
                    'No users found',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data!.docs
              .map((doc) =>
                  UserModel.fromJson(doc.data() as Map<String, dynamic>))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserCard(context, user);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppDimensions.paddingM),
        leading: AvatarWidget(
          initials: user.initials,
          photoUrl: user.photoUrl,
          size: 48,
        ),
        title: Row(
          children: [
            Text(
              user.name,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (user.isAdmin) ...[
              const SizedBox(width: AppDimensions.paddingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingS,
                  vertical: AppDimensions.paddingXXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  'ADMIN',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimensions.paddingXXS),
            Text(user.email),
            const SizedBox(height: AppDimensions.paddingXS),
            Row(
              children: [
                _buildInfoChip(
                  Icons.quiz,
                  '${user.quizzesCompleted} quizzes',
                ),
                const SizedBox(width: AppDimensions.paddingM),
                _buildInfoChip(
                  Icons.calendar_today,
                  _formatDate(user.createdAt),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            _handleUserAction(context, user, value);
          },
          itemBuilder: (context) => [
            if (!user.isAdmin)
              const PopupMenuItem(
                value: 'make_admin',
                child: Text('Make Admin'),
              ),
            if (user.isAdmin)
              const PopupMenuItem(
                value: 'remove_admin',
                child: Text('Remove Admin'),
              ),
            const PopupMenuItem(
              value: 'view_results',
              child: Text('View Results'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete User', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleUserAction(BuildContext context, UserModel user, String action) {
    switch (action) {
      case 'make_admin':
        _updateAdminStatus(context, user, true);
        break;
      case 'remove_admin':
        _updateAdminStatus(context, user, false);
        break;
      case 'view_results':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('View results feature coming soon!')),
        );
        break;
      case 'delete':
        _deleteUser(context, user);
        break;
    }
  }

  Future<void> _updateAdminStatus(
      BuildContext context, UserModel user, bool isAdmin) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'isAdmin': isAdmin});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isAdmin ? 'User is now an admin' : 'Admin privileges removed'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteUser(BuildContext context, UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to delete ${user.name}? This action cannot be undone.'),
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
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted from database')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
