import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/premium_ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  final courseController = TextEditingController();

  final collegeController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    courseController.dispose();
    collegeController.dispose();

    super.dispose();
  }

  // =====================================================
  // REGISTER
  // =====================================================

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    final success = await AuthService.instance.registerUser(
      name: nameController.text,
      email: emailController.text,
      password: passwordController.text,
      course: courseController.text,
      college: collegeController.text,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration failed. Email may already exist.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =====================================================
  // INPUT DECORATION
  // =====================================================

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,

      filled: true,

      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F3FF), Color(0xFFFFF1F2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),

            child: AnimatedReveal(
              child: Card(
              elevation: 5,

              shadowColor: Colors.black12,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),

              child: Padding(
                padding: const EdgeInsets.all(28),

                child: Form(
                  key: _formKey,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [
                      const Icon(
                        Icons.school_rounded,
                        size: 55,
                        color: Color(0xFF4F46E5),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Join Student Help',
                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Create your student community account',
                        textAlign: TextAlign.center,

                        style: TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 28),

                      TextFormField(
                        controller: nameController,

                        textCapitalization: TextCapitalization.words,

                        decoration: inputDecoration(
                          label: 'Full Name',
                          icon: Icons.person,
                        ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your name';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: emailController,

                        keyboardType: TextInputType.emailAddress,

                        decoration: inputDecoration(
                          label: 'Email',
                          icon: Icons.email,
                        ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your email';
                          }

                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: passwordController,

                        obscureText: obscurePassword,

                        decoration: inputDecoration(
                          label: 'Password',
                          icon: Icons.lock,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),

                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter a password';
                          }

                          if (value.length < 6) {
                            return 'Password must contain at least 6 characters';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: courseController,

                        textCapitalization: TextCapitalization.words,

                        decoration: inputDecoration(
                          label: 'Course',
                          icon: Icons.menu_book,
                        ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your course';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: collegeController,

                        textCapitalization: TextCapitalization.words,

                        decoration: inputDecoration(
                          label: 'College',
                          icon: Icons.account_balance,
                        ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your college';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        height: 52,

                        child: ElevatedButton(
                          onPressed: isLoading ? null : register,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),

                            foregroundColor: Colors.white,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),

                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'CREATE ACCOUNT',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          const Text('Already have an account? '),

                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },

                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
