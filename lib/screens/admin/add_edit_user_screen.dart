import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddEditUserScreen extends StatefulWidget {
  final User? user;

  const AddEditUserScreen({Key? key, this.user}) : super(key: key);

  @override
  State<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends State<AddEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _role = 'doctor';
  bool _isObscure = true;
  bool _isObscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameController.text = widget.user!.name;
      _usernameController.text = widget.user!.username;
      _role = widget.user!.role;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final user = User(
      id: widget.user?.id,
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text.isEmpty && widget.user != null
          ? widget.user!.password
          : _passwordController.text.trim(),
      role: _role,
    );

    bool success;
    if (widget.user == null) {
      // Add new user
      success = await userProvider.addUser(user);
    } else {
      // Update existing user
      success = await userProvider.updateUser(user);
    }

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.user == null
                ? 'تم إضافة المستخدم بنجاح'
                : 'تم تحديث بيانات المستخدم بنجاح',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.user == null
                ? 'فشل في إضافة المستخدم'
                : 'فشل في تحديث بيانات المستخدم',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? 'إضافة مستخدم جديد' : 'تعديل بيانات المستخدم'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'الاسم',
                hint: 'أدخل اسم المستخدم الكامل',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال اسم المستخدم';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: 'اسم المستخدم',
                hint: 'أدخل اسم المستخدم للدخول',
                controller: _usernameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال اسم المستخدم للدخول';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: widget.user == null ? 'كلمة المرور' : 'كلمة المرور (اتركها فارغة إذا لم ترد تغييرها)',
                hint: 'أدخل كلمة المرور',
                controller: _passwordController,
                obscureText: _isObscure,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                ),
                validator: (value) {
                  if (widget.user == null && (value == null || value.isEmpty)) {
                    return 'الرجاء إدخال كلمة المرور';
                  }
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: 'تأكيد كلمة المرور',
                hint: 'أعد إدخال كلمة المرور',
                controller: _confirmPasswordController,
                obscureText: _isObscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscureConfirm ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscureConfirm = !_isObscureConfirm;
                    });
                  },
                ),
                validator: (value) {
                  if (_passwordController.text.isNotEmpty &&
                      value != _passwordController.text) {
                    return 'كلمات المرور غير متطابقة';
                  }
                  if (widget.user == null && (value == null || value.isEmpty)) {
                    return 'الرجاء تأكيد كلمة المرور';
                  }
                  return null;
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الدور',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _role,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('مسؤول'),
                          ),
                          DropdownMenuItem(
                            value: 'doctor',
                            child: Text('طبيب'),
                          ),
                        ],
                        onChanged: (newValue) {
                          setState(() {
                            _role = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: widget.user == null ? 'إضافة مستخدم' : 'تحديث البيانات',
                onPressed: _saveUser,
                isLoading: _isLoading,
                width: double.infinity,
                height: 50,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
