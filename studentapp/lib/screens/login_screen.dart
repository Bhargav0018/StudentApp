import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme_controller.dart';
import '../widgets/premium_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService.instance;

  bool _obscurePassword = true;
  bool _isLoading = false;

  static const Color primaryColor = Color(0xFF4F46E5);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // STUDENT LOGIN
  // ============================================================

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await _authService.loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Invalid email or password',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  // ============================================================
  // OPEN ADMIN LOGIN
  // ============================================================

  void _openAdminLogin() {
    Navigator.pushNamed(context, '/admin-login');
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.45,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.35),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEF2FF), Color(0xFFFDF2F8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -90,
              top: -80,
              child: _buildBackgroundOrb(230, const Color(0xFF6366F1)),
            ),
            Positioned(
              right: -70,
              bottom: -70,
              child: _buildBackgroundOrb(210, const Color(0xFFF472B6)),
            ),
            Positioned(
              right: 40,
              top: 70,
              child: _buildBackgroundOrb(54, const Color(0xFF22D3EE)),
            ),
            Positioned(
              right: 24,
              top: 18,
              child: ValueListenableBuilder<bool>(
                valueListenable: ThemeController.instance.isDarkMode,
                builder: (context, isDark, child) {
                  return Material(
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(24),
                    child: IconButton(
                      tooltip: 'Toggle theme',
                      onPressed: ThemeController.instance.toggle,
                      icon: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: isDark ? const Color(0xFF4F46E5) : const Color(0xFFF59E0B),
                      ),
                    ),
                  );
                },
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 700) {
                  return const SizedBox.shrink();
                }

                return Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildBrandPanel(constraints.maxWidth),
                  ),
                );
              },
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: MediaQuery.sizeOf(context).width >= 700 ? 0.53 : 1,
                  child: Center(
                    child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: AnimatedReveal(
                child: Card(
                elevation: 8,
                shadowColor: primaryColor.withValues(alpha: 0.15),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 34,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // ==================================================
                        // APP HEADER
                        // ==================================================

                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            width: double.infinity,
                            height: 292,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  'https://images.unsplash.com/photo-1523240795612-9a054b0db644?auto=format&fit=crop&w=1200&q=90',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF4F46E5),
                                          Color(0xFF7C3AED),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                                ),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF312E81).withValues(alpha: 0.72),
                                        const Color(0xFF4F46E5).withValues(alpha: 0.48),
                                        Colors.black.withValues(alpha: 0.55),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 78,
                                        height: 78,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.22),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.45),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.school_rounded,
                                          color: Colors.white,
                                          size: 44,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Student Help',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 29,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      const Text(
                                        'Community',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ==================================================
                        // WELCOME TEXT
                        // ==================================================
                        Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Login to continue learning and helping others.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.60,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // ==================================================
                        // EMAIL
                        // ==================================================
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Email Address',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: _inputDecoration(
                            label: 'Email',
                            hint: 'Enter your email',
                            icon: Icons.email_outlined,
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';

                            if (email.isEmpty) {
                              return 'Please enter your email';
                            }

                            if (!email.contains('@') || !email.contains('.')) {
                              return 'Please enter a valid email';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // ==================================================
                        // PASSWORD
                        // ==================================================
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) {
                            if (!_isLoading) {
                              _login();
                            }
                          },
                          decoration: _inputDecoration(
                            label: 'Password',
                            hint: 'Enter your password',
                            icon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }

                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 28),

                        // ==================================================
                        // LOGIN BUTTON
                        // ==================================================
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _isLoading
                                  ? const SizedBox(
                                      key: ValueKey('loading'),
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      key: ValueKey('login'),
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.login_rounded, size: 21),
                                        SizedBox(width: 10),
                                        Text(
                                          'LOGIN',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ==================================================
                        // REGISTER
                        // ==================================================
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(
                                fontSize: 15,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.pushNamed(context, '/register');
                                    },
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // ==================================================
                        // DIVIDER
                        // ==================================================
                        Row(
                          children: [
                            Expanded(child: Divider(color: theme.dividerColor)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.50,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: theme.dividerColor)),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // ADMIN LOGIN
                        // ==================================================
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _openAdminLogin,
                            icon: const Icon(
                              Icons.admin_panel_settings_outlined,
                              color: primaryColor,
                            ),
                            label: const Text(
                              'Admin Login',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'For community administrators',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.50,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // TAGLINE
                        // ==================================================
                        Text(
                          'Learn • Ask • Help • Grow',
                          style: TextStyle(
                            color: primaryColor.withValues(alpha: 0.80),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
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
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandPanel(double width) {
    final panelWidth = (width * 0.47).clamp(360.0, 620.0);
    return SizedBox(
      width: panelWidth,
      height: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(52, 20, 28, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.school_rounded, color: Color(0xFF4F46E5), size: 25),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student Help', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF18214D))),
                    Text('Community', style: TextStyle(fontSize: 12, color: Color(0xFF667085), letterSpacing: 1.3)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Learn.\nConnect.\nGrow Together.',
              style: TextStyle(fontSize: 38, height: 0.94, fontWeight: FontWeight.w900, color: Color(0xFF18214D)),
            ),
            const SizedBox(height: 12),
            const SizedBox(
              width: 390,
              child: Text(
                'A community platform where students help students. Ask, share, learn and succeed together.',
                style: TextStyle(fontSize: 15, height: 1.45, color: Color(0xFF667085)),
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureTile(Icons.forum_rounded, 'Ask Questions', 'Get help from peers', const Color(0xFF6366F1)),
            _buildFeatureTile(Icons.groups_rounded, 'Join Community', 'Connect with students', const Color(0xFFEC4899)),
            _buildFeatureTile(Icons.menu_book_rounded, 'Share Resources', 'Notes, PDFs, materials', const Color(0xFF06B6D4)),
            _buildFeatureTile(Icons.lightbulb_rounded, 'Grow Together', 'Learn. Help. Succeed.', const Color(0xFFF59E0B)),
            const SizedBox(height: 8),
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: AspectRatio(
                  aspectRatio: 2.15,
                  child: Image.network(
                    'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=900&q=85',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF818CF8), Color(0xFFF9A8D4)]),
                      ),
                      child: const Icon(Icons.diversity_3_rounded, size: 80, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF27315D))),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF667085))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.10), blurRadius: 36)],
      ),
    );
  }
}
