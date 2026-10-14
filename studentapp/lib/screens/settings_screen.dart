import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../theme_controller.dart';
import '../widgets/student_navigation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService.instance;
  final SettingsService _settings = SettingsService.instance;

  bool _darkMode = false;
  bool _notifications = true;
  bool _loading = true;

  bool _savingDarkMode = false;
  bool _savingNotifications = false;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ============================================================
  // LOAD SETTINGS
  // ============================================================

  Future<void> _loadSettings() async {
    final userId = _auth.currentUserId;

    if (userId == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      return;
    }

    try {
      final data = await _settings.getSettings(userId);

      if (!mounted) return;

      final bool darkMode = data['dark_mode'] == 1;
      final bool notifications = data['notifications_enabled'] == 1;

      setState(() {
        _darkMode = darkMode;
        _notifications = notifications;
        _loading = false;
      });

      // Apply saved theme globally
      ThemeController.instance.setDarkMode(darkMode);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage('Unable to load settings.', isError: true);
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF4F46E5),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // DARK MODE
  // ============================================================

  Future<void> _toggleDarkMode(bool value) async {
    final userId = _auth.currentUserId;

    if (userId == null) return;

    // Save previous value in case database update fails
    final bool previousValue = _darkMode;

    // Apply UI immediately
    setState(() {
      _darkMode = value;
      _savingDarkMode = true;
    });

    // Apply theme to entire application immediately
    ThemeController.instance.setDarkMode(value);

    try {
      // Save to database
      await _settings.setDarkMode(userId, value);

      if (!mounted) return;

      setState(() {
        _savingDarkMode = false;
      });

      _showMessage(value ? 'Dark Mode enabled' : 'Light Mode enabled');
    } catch (e) {
      if (!mounted) return;

      // Restore previous value
      setState(() {
        _darkMode = previousValue;
        _savingDarkMode = false;
      });

      ThemeController.instance.setDarkMode(previousValue);

      _showMessage('Unable to update Dark Mode.', isError: true);
    }
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Future<void> _toggleNotifications(bool value) async {
    final userId = _auth.currentUserId;

    if (userId == null) return;

    final bool previousValue = _notifications;

    setState(() {
      _notifications = value;
      _savingNotifications = true;
    });

    try {
      await _settings.setNotificationsEnabled(userId, value);

      if (!mounted) return;

      setState(() {
        _savingNotifications = false;
      });

      _showMessage(value ? 'Notifications enabled' : 'Notifications disabled');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _notifications = previousValue;
        _savingNotifications = false;
      });

      _showMessage('Unable to update notifications.', isError: true);
    }
  }

  // ============================================================
  // RESET SETTINGS
  // ============================================================

  Future<void> _resetSettings() async {
    final userId = _auth.currentUserId;

    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.restart_alt, color: Color(0xFF4F46E5)),
              SizedBox(width: 10),
              Text('Reset Settings'),
            ],
          ),
          content: const Text(
            'This will restore Dark Mode and Notification '
            'settings to their default values.\n\n'
            'Dark Mode → OFF\n'
            'Notifications → ON\n\n'
            'Do you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('RESET'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    if (mounted) {
      setState(() {
        _resetting = true;
      });
    }

    try {
      // Reset database settings
      await _settings.resetSettings(userId);

      if (!mounted) return;

      setState(() {
        _darkMode = false;
        _notifications = true;
        _resetting = false;
      });

      // Reset application theme globally
      ThemeController.instance.setDarkMode(false);

      _showMessage('Settings reset successfully.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _resetting = false;
      });

      _showMessage('Unable to reset settings.', isError: true);
    }
  }

  // ============================================================
  // ABOUT APP
  // ============================================================

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Student Help Community',
      applicationVersion: 'Version 1.0.0',
      applicationIcon: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFFDFF7F3),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.school, size: 32, color: Color(0xFF4F46E5)),
      ),
      children: const [
        SizedBox(height: 10),
        Text(
          'Student Help Community is a student-focused platform '
          'where students can ask questions, share answers, '
          'discover useful learning resources and help each other.',
        ),
        SizedBox(height: 15),
        Text('Built with Flutter, Dart and SQLite.'),
        SizedBox(height: 10),
        Text(
          'Learn • Help • Grow',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  void _navigateFromShell(int index) {
    if (index == 7) return;
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }
    Navigator.pushNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 15),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.all(16),

              children: [
                // =================================================
                // SETTINGS HEADER
                // =================================================

                _buildHeader(isDark),

                const SizedBox(height: 24),

                // =================================================
                // APPEARANCE
                // =================================================
                _sectionTitle('Appearance', Icons.palette_outlined),

                Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile(
                    // ✅ ONLY ONE secondary
                    secondary: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF123E3A)
                            : const Color(0xFFDFF7F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _darkMode ? Icons.dark_mode : Icons.light_mode_outlined,
                        color: isDark
                            ? const Color(0xFF99F6E4)
                            : const Color(0xFF4F46E5),
                      ),
                    ),

                    title: const Text(
                      'Dark Mode',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    subtitle: Text(
                      _darkMode ? 'Dark theme enabled' : 'Light theme enabled',
                    ),

                    value: _darkMode,

                    onChanged: _savingDarkMode ? null : _toggleDarkMode,
                  ),
                ),

                const SizedBox(height: 22),

                // =================================================
                // NOTIFICATIONS
                // =================================================
                _sectionTitle('Notifications', Icons.notifications_outlined),

                Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile(
                    secondary: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF263A32)
                            : const Color(0xFFEAF8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _notifications
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_off_outlined,
                        color: _notifications ? Colors.green : Colors.grey,
                      ),
                    ),

                    title: const Text(
                      'Notifications',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    subtitle: Text(
                      _notifications
                          ? 'You will receive activity notifications'
                          : 'Notifications are disabled',
                    ),

                    value: _notifications,

                    onChanged: _savingNotifications
                        ? null
                        : _toggleNotifications,
                  ),
                ),

                const SizedBox(height: 22),

                // =================================================
                // GENERAL
                // =================================================
                _sectionTitle('General', Icons.settings_outlined),

                Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // -------------------------------------------
                      // RESET SETTINGS
                      // -------------------------------------------

                      ListTile(
                        leading: _buildTileIcon(Icons.restart_alt, isDark),

                        title: const Text(
                          'Reset Settings',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),

                        subtitle: const Text('Restore default settings'),

                        trailing: _resetting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 16),

                        onTap: _resetting ? null : _resetSettings,
                      ),

                      const Divider(height: 1, indent: 65),

                      // -------------------------------------------
                      // ABOUT APP
                      // -------------------------------------------
                      ListTile(
                        leading: _buildTileIcon(Icons.info_outline, isDark),

                        title: const Text(
                          'About App',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),

                        subtitle: const Text(
                          'Learn more about Student Help Community',
                        ),

                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),

                        onTap: _showAbout,
                      ),

                      const Divider(height: 1, indent: 65),

                      // -------------------------------------------
                      // VERSION
                      // -------------------------------------------
                      const ListTile(
                        leading: Icon(Icons.verified_outlined),

                        title: Text(
                          'Version',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),

                        subtitle: Text('1.0.0'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // =================================================
                // APP FOOTER
                // =================================================
                Center(
                  child: Text(
                    'Student Help Community',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Center(
                  child: Text(
                    'Learn • Help • Grow',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                    ),
                  ),
                ),

                const SizedBox(height: 25),
              ],
            ),
        bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
            ? StudentBottomNavigation(selectedIndex: 4, onSelected: _navigateFromShell)
            : null,
    );
  }

  // ============================================================
  // SETTINGS HEADER
  // ============================================================

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.20),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,

            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),

            child: const Icon(Icons.settings, color: Colors.white, size: 30),
          ),

          const SizedBox(width: 15),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Customize your Student Help Community experience.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4F46E5)),

          const SizedBox(width: 8),

          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TILE ICON
  // ============================================================

  Widget _buildTileIcon(IconData icon, bool isDark) {
    return Container(
      width: 42,
      height: 42,

      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F2FF),
        borderRadius: BorderRadius.circular(12),
      ),

      child: Icon(
        icon,
        color: isDark ? const Color(0xFF99F6E4) : const Color(0xFF4F46E5),
      ),
    );
  }
}
