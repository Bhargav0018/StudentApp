import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../database/database_helper.dart';
import '../services/question_service.dart';
import '../services/resource_service.dart';
import '../services/notification_service.dart';

import 'ask_question_screen.dart';
import 'questions_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'saved_resources_screen.dart';
import 'resources_screen.dart';
import 'settings_screen.dart';
import '../widgets/premium_ui.dart';
import '../widgets/student_navigation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _auth = AuthService.instance;

  int _questionCount = 0;
  int _answerCount = 0;
  int _savedResourceCount = 0;
  int _resourceCount = 0;
  int _notificationCount = 0;

  // Contribution score + leaderboard
  int _contributionScore = 0;
  int _currentRank = 0;
  List<Map<String, dynamic>> _leaderboardUsers = [];

  bool _loading = true;

  List<Map<String, dynamic>> _recentQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // ============================================================
  // LOAD DASHBOARD DATA
  // ============================================================

  Future<void> _loadDashboardData() async {
    final int? userId = _auth.currentUserId;

    if (userId == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      return;
    }

    try {
      final results = await Future.wait([
        QuestionService.instance.getUserQuestionCount(userId),
        QuestionService.instance.getUserAnswerCount(userId),
        ResourceService.instance.getSavedResourceCount(userId),
        DatabaseHelper.instance.rawQuery(
          'SELECT COUNT(*) AS count FROM resources WHERE user_id = ?',
          [userId],
        ),
        NotificationService.instance.getUnreadCount(userId),
        QuestionService.instance.getQuestions(),

        // Current user's contribution score.
        DatabaseHelper.instance.rawQuery(
          '''
          SELECT COALESCE(points, 0) AS points
          FROM users
          WHERE id = ?
          LIMIT 1
          ''',
          [userId],
        ),

        // Community leaderboard.
        DatabaseHelper.instance.rawQuery('''
          SELECT id, name, course, COALESCE(points, 0) AS points
          FROM users
          ORDER BY COALESCE(points, 0) DESC, name COLLATE NOCASE ASC
          '''),
      ]);

      if (!mounted) return;

      setState(() {
        _questionCount = results[0] as int;
        _answerCount = results[1] as int;
        _savedResourceCount = results[2] as int;
        _resourceCount =
            ((results[3] as List<Map<String, dynamic>>).first['count'] as num)
                .toInt();
        _notificationCount = results[4] as int;

        _recentQuestions = results[5] as List<Map<String, dynamic>>;

        final pointRows = results[6] as List<Map<String, dynamic>>;
        _contributionScore = pointRows.isNotEmpty
            ? _safeInt(pointRows.first['points'])
            : 0;

        _leaderboardUsers = results[7] as List<Map<String, dynamic>>;

        _currentRank = 0;
        for (int i = 0; i < _leaderboardUsers.length; i++) {
          if (_safeInt(_leaderboardUsers[i]['id']) == userId) {
            _currentRank = i + 1;
            break;
          }
        }

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage('Unable to load dashboard data.', isError: true);
    }
  }

  int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _reputationLevel(int points) {
    if (points >= 100) return 'Community Champion';
    if (points >= 50) return 'Helpful Member';
    if (points >= 20) return 'Active Student';
    return 'New Member';
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
      ),
    );
  }

  // ============================================================
  // QUESTIONS
  // ============================================================

  Future<void> _openQuestions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuestionsScreen()),
    );

    _loadDashboardData();
  }

  // ============================================================
  // ASK QUESTION
  // ============================================================

  Future<void> _openAskQuestion() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AskQuestionScreen()),
    );

    _loadDashboardData();
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );

    _loadDashboardData();
  }

  // ============================================================
  // PROFILE
  // ============================================================

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );

    _loadDashboardData();
  }

  // ============================================================
  // SAVED RESOURCES
  // ============================================================

  Future<void> _openSavedResources() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedResourcesScreen()),
    );

    _loadDashboardData();
  }

  // ============================================================
  // RESOURCES
  // ============================================================

  Future<void> _openResources() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ResourcesScreen()),
    );

    _loadDashboardData();
  }

  // ============================================================
  // SETTINGS
  // ============================================================

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );

    _loadDashboardData();
  }

  // ============================================================
  // PROFILE POPUP
  // RESPONSIVE - MOBILE + CHROME
  // ============================================================

  void _showProfilePopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) {
        final screenHeight = MediaQuery.of(sheetContext).size.height;

        final maxHeight = screenHeight < 600 ? screenHeight * 0.90 : 600.0;

        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(sheetContext).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // =================================================
                    // DRAG HANDLE
                    // =================================================

                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // =================================================
                    // PROFILE AVATAR
                    // =================================================
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: isDark
                          ? const Color(0xFF123E3A)
                          : const Color(0xFFDFF7F3),
                      child: Text(
                        _userInitial,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF99F6E4)
                              : const Color(0xFF4F46E5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // =================================================
                    // NAME
                    // =================================================
                    Text(
                      _auth.currentUserName.isEmpty
                          ? 'Student'
                          : _auth.currentUserName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),

                    // =================================================
                    // EMAIL
                    // =================================================
                    if (_auth.currentUserEmail.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _auth.currentUserEmail,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    const SizedBox(height: 18),

                    // =================================================
                    // MY PROFILE
                    // =================================================
                    _buildPopupItem(
                      icon: Icons.person_outline,
                      title: 'My Profile',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _openProfile();
                      },
                    ),

                    // =================================================
                    // RESOURCES
                    // =================================================
                    _buildPopupItem(
                      icon: Icons.library_books_outlined,
                      title: 'Resources',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _openResources();
                      },
                    ),

                    // =================================================
                    // SAVED RESOURCES
                    // =================================================
                    _buildPopupItem(
                      icon: Icons.bookmark_outline,
                      title: 'Saved Resources',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _openSavedResources();
                      },
                    ),

                    // =================================================
                    // CONTRIBUTION SCORE
                    // =================================================
                    _buildPopupItem(
                      icon: Icons.emoji_events_outlined,
                      title: 'Contribution Score',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showContributionScore();
                      },
                    ),

                    // =================================================
                    // LEADERBOARD
                    // =================================================
                    _buildPopupItem(
                      icon: Icons.leaderboard_outlined,
                      title: 'Leaderboard',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showLeaderboard();
                      },
                    ),

                    // =================================================
                    // SETTINGS
                    // =================================================
                    _buildPopupItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _openSettings();
                      },
                    ),

                    const SizedBox(height: 4),

                    Divider(height: 16, color: isDark ? Colors.white12 : null),

                    // =================================================
                    // LOGOUT
                    // =================================================
                    _buildPopupItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      iconColor: Colors.redAccent,
                      textColor: Colors.redAccent,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _logout();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // POPUP ITEM
  // ============================================================

  Widget _buildPopupItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color:
                      iconColor ??
                      (isDark
                          ? const Color(0xFF99F6E4)
                          : const Color(0xFF4F46E5)),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          textColor ??
                          (isDark ? Colors.white : const Color(0xFF1E293B)),
                    ),
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void _logout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 42, height: 5, decoration: BoxDecoration(color: scheme.outlineVariant, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 22),
              CircleAvatar(
                radius: 31,
                backgroundColor: const Color(0xFFFEE2E2),
                child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 29),
              ),
              const SizedBox(height: 14),
              const Text('Leaving already?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              Text('You can always come back to your student community.', textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('Stay'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _auth.logout();
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // USER INITIAL
  // ============================================================

  String get _userInitial {
    if (_auth.currentUserName.trim().isEmpty) {
      return 'S';
    }

    return _auth.currentUserName.trim().substring(0, 1).toUpperCase();
  }

  void _navigateFromShell(int index) {
    switch (index) {
      case 0:
        return;
      case 1:
        _openQuestions();
      case 2:
        _openAskQuestion();
      case 3:
        _openResources();
      case 4:
      case 6:
        _openProfile();
      case 5:
        _openNotifications();
      case 7:
        _openSettings();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,

        title: const Text(
          'Student Help Community',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),

        actions: [
          // ----------------------------------------------------
          // NOTIFICATIONS
          // ----------------------------------------------------

          Stack(
            children: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: _openNotifications,
                icon: const Icon(Icons.notifications_outlined),
              ),

              if (_notificationCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _notificationCount > 99 ? '99+' : '$_notificationCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ----------------------------------------------------
          // PROFILE
          // ----------------------------------------------------
          IconButton(
            tooltip: 'Account',
            onPressed: _showProfilePopup,
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4F46E5),
              child: Text(
                _userInitial,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final content = RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildDashboard(),
          );

          if (!isDesktop) return content;

          return Row(
            children: [
              StudentNavigation(
                selectedIndex: 0,
                onSelected: _navigateFromShell,
                userName: _auth.currentUserName,
                userInitial: _userInitial,
                notificationCount: _notificationCount,
              ),
              Expanded(child: content),
            ],
          );
        },
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
          ? StudentBottomNavigation(selectedIndex: 0, onSelected: _navigateFromShell)
          : null,

      // ========================================================
      // ASK QUESTION BUTTON
      // ========================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAskQuestion,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Ask Question',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Widget _buildDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),

      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // WELCOME
              // ------------------------------------------------

              _buildHeroWelcomeCard(),

              const SizedBox(height: 25),

              // ------------------------------------------------
              // CONTRIBUTION SCORE + LEADERBOARD
              // ------------------------------------------------
              Text(
                'Your Contribution',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),

              const SizedBox(height: 14),

              _buildContributionCard(),

              const SizedBox(height: 18),

              const SizedBox(height: 25),

              // ------------------------------------------------
              // ACTIVITY
              // ------------------------------------------------
              Text(
                'Your Activity',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),

              const SizedBox(height: 14),

              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  int columns = 1;

                  if (width >= 1100) {
                    columns = 5;
                  } else if (width >= 850) {
                    columns = 4;
                  } else if (width >= 550) {
                    columns = 2;
                  }

                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: columns == 1
                        ? 3.3
                        : (columns == 5 ? 1.25 : 1.45),
                    children: [
                      _buildStatCard(
                        icon: Icons.question_answer_outlined,
                        title: 'Questions',
                        value: '$_questionCount',
                        onTap: _openQuestions,
                      ),

                      _buildStatCard(
                        icon: Icons.forum_outlined,
                        title: 'Answers',
                        value: '$_answerCount',
                        onTap: _openQuestions,
                      ),

                      _buildStatCard(
                        icon: Icons.library_books_outlined,
                        title: 'Resources Shared',
                        value: '$_resourceCount',
                        onTap: _openResources,
                      ),

                      _buildStatCard(
                        icon: Icons.bookmark_outline,
                        title: 'Saved Resources',
                        value: '$_savedResourceCount',
                        onTap: _openSavedResources,
                      ),

                      _buildStatCard(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        value: '$_notificationCount',
                        onTap: _openNotifications,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              const SizedBox(height: 28),

              // ------------------------------------------------
              // QUICK ACTIONS
              // ------------------------------------------------
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),

              const SizedBox(height: 14),

              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  int columns = 1;

                  if (width >= 850) {
                    columns = 3;
                  } else if (width >= 550) {
                    columns = 2;
                  }

                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: columns == 1 ? 4 : 2.1,
                    children: [
                      _buildActionCard(
                        icon: Icons.add_circle_outline,
                        title: 'Ask a Question',
                        subtitle: 'Get help from fellow students',
                        onTap: _openAskQuestion,
                      ),

                      _buildActionCard(
                        icon: Icons.search,
                        title: 'Browse Questions',
                        subtitle: 'Find answers and discussions',
                        onTap: _openQuestions,
                      ),

                      // =================================================
                      // RESOURCES - NEW
                      // =================================================
                      _buildActionCard(
                        icon: Icons.library_books_outlined,
                        title: 'Resources',
                        subtitle: 'Browse and share useful learning resources',
                        onTap: _openResources,
                      ),

                      _buildActionCard(
                        icon: Icons.bookmark_outline,
                        title: 'Saved Resources',
                        subtitle: 'Access your saved learning resources',
                        onTap: _openSavedResources,
                      ),

                      _buildActionCard(
                        icon: Icons.notifications_active_outlined,
                        title: 'Notifications',
                        subtitle: 'View your latest updates',
                        onTap: _openNotifications,
                      ),

                      _buildActionCard(
                        icon: Icons.person_outline,
                        title: 'My Profile',
                        subtitle: 'View and manage your profile',
                        onTap: _openProfile,
                      ),

                      _buildActionCard(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        subtitle: 'Manage app preferences',
                        onTap: _openSettings,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Leaderboard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _showLeaderboard,
                    child: const Text('View All'),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              _buildLeaderboardPreview(),

              const SizedBox(height: 28),

              // ------------------------------------------------
              // RECENT QUESTIONS
              // ------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Recent Questions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: _openQuestions,
                    child: const Text('View All'),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              _buildRecentQuestions(),

              const SizedBox(height: 28),

              // ------------------------------------------------
              // COMMUNITY
              // ------------------------------------------------
              _buildCommunityCard(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONTRIBUTION CARD
  // ============================================================

  Widget _buildContributionCard() {
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
            color: const Color(0xFF4F46E5).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contribution Score',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  '$_contributionScore points',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentRank > 0
                      ? '#$_currentRank in community • ${_reputationLevel(_contributionScore)}'
                      : _reputationLevel(_contributionScore),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_currentRank > 0)
            Column(
              children: [
                const Text(
                  'RANK',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '#$_currentRank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // LEADERBOARD PREVIEW
  // ============================================================

  Widget _buildLeaderboardPreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topUsers = _leaderboardUsers.length > 3
        ? _leaderboardUsers.take(3).toList()
        : _leaderboardUsers;

    if (topUsers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isDark
              ? Border.all(color: const Color(0xFF34395A))
              : Border.all(color: const Color(0xFFE8EAF0)),
        ),
        child: const Text(
          'No leaderboard data available yet.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: List.generate(topUsers.length, (index) {
        final user = topUsers[index];
        final rank = index + 1;
        final name = user['name']?.toString().trim().isNotEmpty == true
            ? user['name'].toString().trim()
            : 'Unknown User';
        final points = _safeInt(user['points']);
        final isMe = _safeInt(user['id']) == _auth.currentUserId;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isMe
                  ? const Color(0xFF4F46E5).withValues(alpha: 0.55)
                  : (isDark
                        ? const Color(0xFF34395A)
                        : const Color(0xFFE8EAF0)),
              width: isMe ? 1.4 : 1,
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rank <= 3
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFFDFF7F3),
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.white : const Color(0xFF4F46E5),
                ),
              ),
            ),
            title: Text(
              isMe ? '$name (You)' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            subtitle: Text(
              _reputationLevel(points),
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey,
                fontSize: 12,
              ),
            ),
            trailing: Text(
              '$points pts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4F46E5),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ============================================================
  // CONTRIBUTION SCORE DIALOG
  // ============================================================

  void _showContributionScore() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.emoji_events_outlined),
              SizedBox(width: 10),
              Expanded(child: Text('Contribution Score')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_contributionScore points',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _currentRank > 0
                          ? 'Community Rank #$_currentRank'
                          : 'Community Rank not available',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'How to earn points',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildPointRule('Ask a question', '+2 points'),
              _buildPointRule('Answer a question', '+5 points'),
              _buildPointRule('Share a resource', '+4 points'),
              _buildPointRule('Helpful answer', '+3 points'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPointRule(String title, String points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 7, color: Color(0xFF4F46E5)),
          const SizedBox(width: 9),
          Expanded(child: Text(title)),
          Text(
            points,
            style: const TextStyle(
              color: Color(0xFF4F46E5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FULL LEADERBOARD DIALOG
  // ============================================================

  void _showLeaderboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.emoji_events_outlined),
              SizedBox(width: 10),
              Text('Community Leaderboard'),
            ],
          ),
          content: SizedBox(
            width: 520,
            height: 500,
            child: _leaderboardUsers.isEmpty
                ? const Center(child: Text('No leaderboard data available.'))
                : ListView.builder(
                    itemCount: _leaderboardUsers.length,
                    itemBuilder: (context, index) {
                      final user = _leaderboardUsers[index];
                      final rank = index + 1;
                      final name =
                          user['name']?.toString().trim().isNotEmpty == true
                          ? user['name'].toString().trim()
                          : 'Unknown User';
                      final points = _safeInt(user['points']);
                      final isMe = _safeInt(user['id']) == _auth.currentUserId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isMe
                              ? (isDark
                                    ? const Color(0xFF123E3A)
                                    : const Color(0xFFDFF7F3))
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: rank <= 3
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFFDFF7F3),
                            child: Text(
                              '$rank',
                              style: TextStyle(
                                color: rank <= 3
                                    ? Colors.white
                                    : const Color(0xFF4F46E5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            isMe ? '$name (You)' : name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(_reputationLevel(points)),
                          trailing: Text(
                            '$points pts',
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // WELCOME CARD
  // ============================================================

  Widget _buildHeroWelcomeCard() {
    final scheme = Theme.of(context).colorScheme;
    final isSmall = MediaQuery.sizeOf(context).width < 650;

    return AnimatedReveal(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 245),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.28),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -44,
              top: -58,
              child: _buildOrb(190, Colors.white.withValues(alpha: 0.10)),
            ),
            Positioned(
              right: 100,
              bottom: -70,
              child: _buildOrb(150, const Color(0xFF06B6D4).withValues(alpha: 0.25)),
            ),
            Positioned(
              left: -48,
              bottom: -78,
              child: _buildOrb(170, const Color(0xFFF97316).withValues(alpha: 0.22)),
            ),
            Padding(
              padding: const EdgeInsets.all(26),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'YOUR COMMUNITY SPACE',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Welcome back,\n${_auth.currentUserName.isEmpty ? 'Student' : _auth.currentUserName}!',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 29, height: 1.08, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Learn together. Share boldly.\nGrow with your people.',
                          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.35),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildHeroBadge(Icons.bolt_rounded, 'Keep going'),
                            if (_currentRank > 0) _buildHeroBadge(Icons.emoji_events_rounded, 'Rank #$_currentRank'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isSmall) ...[
                    const SizedBox(width: 18),
                    SizedBox(
                      width: 180,
                      height: 185,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.rotate(
                            angle: -0.10,
                            child: Container(
                              width: 145,
                              height: 165,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(70),
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 58,
                            backgroundColor: Colors.white,
                            child: Text(
                              _userInitial,
                              style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 42, fontWeight: FontWeight.w900),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 10,
                            child: _buildFloatingBadge(Icons.auto_awesome, const Color(0xFFFBBF24)),
                          ),
                          Positioned(
                            left: 3,
                            bottom: 18,
                            child: _buildFloatingBadge(Icons.school_rounded, const Color(0xFF06B6D4)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }

  Widget _buildHeroBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 15), const SizedBox(width: 5), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))]),
    );
  }

  Widget _buildFloatingBadge(IconData icon, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 14)]),
      child: Icon(icon, color: Colors.white, size: 21),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 550;

          return Flex(
            direction: isSmall ? Axis.vertical : Axis.horizontal,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Expanded(
                flex: isSmall ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back 👋',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      _auth.currentUserName.isEmpty
                          ? 'Student'
                          : _auth.currentUserName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Learn together. Help others. Grow together.',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),

                    const SizedBox(height: 18),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_auth.currentUserCourse.isNotEmpty)
                          _buildInfoChip(Icons.school, _auth.currentUserCourse),

                        if (_auth.currentUserCollege.isNotEmpty)
                          _buildInfoChip(
                            Icons.account_balance,
                            _auth.currentUserCollege,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              if (!isSmall) const SizedBox(width: 25),

              if (isSmall) const SizedBox(height: 20),

              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white,
                child: Text(
                  _userInitial,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // INFO CHIP
  // ============================================================

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),

          const SizedBox(width: 6),

          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = switch (title) {
      'Questions' => const Color(0xFF4F46E5),
      'Answers' => const Color(0xFF2563EB),
      'Resources Shared' => const Color(0xFFD97706),
      'Saved Resources' => const Color(0xFFDB2777),
      _ => const Color(0xFF7C3AED),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,

      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.94, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,

          borderRadius: BorderRadius.circular(18),

          border: isDark ? Border.all(color: const Color(0xFF34395A)) : null,

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,

              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.22 : 0.10),

                borderRadius: BorderRadius.circular(15),
              ),

              child: Icon(icon, color: accentColor, size: 27),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),

                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  // ============================================================
  // ACTION CARD
  // ============================================================

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColors = switch (title) {
      'Ask a Question' => const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
      'Browse Questions' => const [Color(0xFF0891B2), Color(0xFF06B6D4)],
      'Resources' => const [Color(0xFFF97316), Color(0xFFFB7185)],
      'Saved Resources' => const [Color(0xFFDB2777), Color(0xFFF472B6)],
      'Notifications' => const [Color(0xFF2563EB), Color(0xFF38BDF8)],
      _ => const [Color(0xFF059669), Color(0xFF34D399)],
    };

    return _HoverActionCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,

          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: isDark ? const Color(0xFF34395A) : const Color(0xFFE8EAF0),
          ),
        ),

        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: actionColors,
                ),
                borderRadius: BorderRadius.circular(15),
              ),

              child: Icon(icon, color: Colors.white, size: 27),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: 15,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RECENT QUESTIONS
  // ============================================================

  Widget _buildRecentQuestions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_recentQuestions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),

        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,

          borderRadius: BorderRadius.circular(18),

          border: isDark ? Border.all(color: const Color(0xFF34395A)) : null,
        ),

        child: Column(
          children: [
            Icon(
              Icons.question_answer_outlined,
              size: 55,
              color: isDark ? Colors.white38 : Colors.grey,
            ),

            const SizedBox(height: 10),

            Text(
              'No questions yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : null,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Be the first student to ask a question.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
            ),

            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: _openAskQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Ask Question'),
            ),
          ],
        ),
      );
    }

    final recent = _recentQuestions.length > 5
        ? _recentQuestions.take(5).toList()
        : _recentQuestions;

    return Column(
      children: recent.map((question) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,

          color: isDark ? const Color(0xFF1E2235) : null,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),

            side: isDark
                ? const BorderSide(color: Color(0xFF34395A))
                : BorderSide.none,
          ),

          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 7,
            ),

            leading: const CircleAvatar(
              backgroundColor: Color(0xFFDFF7F3),
              child: Icon(Icons.question_mark, color: Color(0xFF4F46E5)),
            ),

            title: Text(
              question['title']?.toString() ?? 'Untitled Question',

              maxLines: 2,

              overflow: TextOverflow.ellipsis,

              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : null,
              ),
            ),

            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '${question['category'] ?? 'General'} • ${question['user_name'] ?? 'Student'}',

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(color: isDark ? Colors.white60 : null),
              ),
            ),

            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 15,
              color: isDark ? Colors.white38 : Colors.grey,
            ),

            onTap: _openQuestions,
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // COMMUNITY CARD
  // ============================================================

  Widget _buildCommunityCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF20243A) : const Color(0xFFEFF4FF),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: isDark ? const Color(0xFF34395A) : const Color(0xFFDDE5FF),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 52,
            height: 52,

            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),

              borderRadius: BorderRadius.circular(15),
            ),

            child: const Icon(
              Icons.groups_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Help Community',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Ask questions, share knowledge, discover useful resources and help other students succeed.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverActionCard extends StatefulWidget {
  const _HoverActionCard({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_HoverActionCard> createState() => _HoverActionCardState();
}

class _HoverActionCardState extends State<_HoverActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.025 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
