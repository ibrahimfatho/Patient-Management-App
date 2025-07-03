import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_indicator.dart';
import 'add_edit_user_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    });
  }

  void _showDeleteConfirmation(BuildContext context, User user) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('هل أنت متأكد من حذف المستخدم ${user.name}؟'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Provider.of<UserProvider>(
                    context,
                    listen: false,
                  ).deleteUser(user.id!).then((success) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم حذف المستخدم بنجاح'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('فشل في حذف المستخدم'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  });
                },
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UserProvider>(
        builder: (ctx, userProvider, child) {
          if (userProvider.isLoading) {
            return const LoadingIndicator();
          }

          if (userProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'حدث خطأ: ${userProvider.error}',
                    style: const TextStyle(color: AppTheme.errorColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'إعادة المحاولة',
                    onPressed: () {
                      userProvider.fetchUsers();
                    },
                  ),
                ],
              ),
            );
          }

          final users =
              userProvider.users
                  .where((user) => user.role != 'patient')
                  .toList();
          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    color: Colors.grey,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا يوجد مستخدمين',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (ctx, index) {
              final user = users[index];
              return CustomCard(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0.2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  user.role == 'admin'
                                      ? Colors.purple.withOpacity(0.1)
                                      : user.role == 'doctor'
                                      ? AppTheme.primaryColor.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                              child: Icon(
                                size: 26,
                                user.role == 'admin'
                                    ? Icons.admin_panel_settings
                                    : user.role == 'doctor'
                                    ? Icons.medical_services
                                    : Icons.person,
                                color:
                                    user.role == 'admin'
                                        ? Colors.purple
                                        : user.role == 'doctor'
                                        ? AppTheme.primaryColor
                                        : Colors.orange,
                              ),
                            ),
                            SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    user.role == 'admin'
                                        ? Colors.purple.withOpacity(0.1)
                                        : user.role == 'doctor'
                                        ? AppTheme.primaryColor.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user.role == 'admin'
                                    ? 'مسجل'
                                    : user.role == 'doctor'
                                    ? 'طبيب'
                                    : 'مريض',
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      user.role == 'admin'
                                          ? Colors.purple
                                          : user.role == 'doctor'
                                          ? AppTheme.primaryColor
                                          : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    user.name,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'اسم المستخدم: ${user.username}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton(
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('تعديل'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text(
                                        'حذف',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (_) => AddEditUserScreen(user: user),
                                  ),
                                );
                                break;
                              case 'delete':
                                _showDeleteConfirmation(context, user);
                                break;
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddEditUserScreen()));
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
