import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      final profile = await AuthService.fetchProfile();
      _usernameController.text = profile['username'] ?? '';
      _emailController.text = profile['email'] ?? '';
    } catch (error) {
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
        _message = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      await AuthService.updateProfile(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
      );
      setState(() {
        _message = 'Profile updated successfully.';
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _passwordController.clear();
          _confirmController.clear();
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Update your username, email, and password for the current account.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              filled: true,
                              fillColor: AppColors.field,
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Username is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              filled: true,
                              fillColor: AppColors.field,
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final emailRegex = RegExp(
                                  r"^[^@\s]+@[^@\s]+\.[^@\s]+$",
                                );
                                if (!emailRegex.hasMatch(value)) {
                                  return 'Enter a valid email';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'New Password',
                              filled: true,
                              fillColor: AppColors.field,
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              filled: true,
                              fillColor: AppColors.field,
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          if (_errorMessage != null)
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          if (_message != null)
                            Text(
                              _message!,
                              style: const TextStyle(color: AppColors.accent),
                            ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('Save changes'),
                            ),
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
}
