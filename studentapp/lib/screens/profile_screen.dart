import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../services/auth_service.dart';
import '../services/question_service.dart';
import '../services/resource_service.dart';
import '../widgets/student_navigation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService auth = AuthService.instance;

  late TextEditingController nameController;
  late TextEditingController courseController;
  late TextEditingController collegeController;

  int questionCount = 0;
  int answerCount = 0;
  int savedQuestionCount = 0;
  int savedResourceCount = 0;

  // Contribution score + leaderboard
  int contributionScore = 0;
  int currentRank = 0;
  List<Map<String, dynamic>> leaderboardUsers = [];

  bool loadingStats = true;
  bool savingProfile = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: auth.currentUserName);

    courseController = TextEditingController(text: auth.currentUserCourse);

    collegeController = TextEditingController(text: auth.currentUserCollege);

    loadStatistics();
  }

  @override
  void dispose() {
    nameController.dispose();
    courseController.dispose();
    collegeController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD PROFILE STATISTICS
  // ============================================================

  Future<void> loadStatistics() async {
    final userId = auth.currentUserId;

    if (userId == null) {
      if (mounted) {
        setState(() {
          loadingStats = false;
          contributionScore = 0;
          currentRank = 0;
          leaderboardUsers = [];
        });
      }
      return;
    }

    try {
      final questionResult = await QuestionService.instance
          .getUserQuestionCount(userId);
      final answerResult = await QuestionService.instance.getUserAnswerCount(
        userId,
      );
      final savedQuestionsResult = await QuestionService.instance
          .getSavedQuestions(userId);
      final savedResourcesResult = await ResourceService.instance
          .getSavedResourceCount(userId);

      int points = 0;
      List<Map<String, dynamic>> users = [];

      try {
        final pointRows = await DatabaseHelper.instance.rawQuery(
          '''
          SELECT COALESCE(points, 0) AS points
          FROM users
          WHERE id = ?
          LIMIT 1
          ''',
          [userId],
        );

        if (pointRows.isNotEmpty) {
          final value = pointRows.first['points'];
          points = value is num
              ? value.toInt()
              : int.tryParse(value?.toString() ?? '') ?? 0;
        }
      } catch (e) {
        debugPrint('Contribution score load error: $e');
      }

      try {
        users = await DatabaseHelper.instance.rawQuery('''
          SELECT
            id,
            name,
            email,
            course,
            college,
            COALESCE(points, 0) AS points
          FROM users
          ORDER BY COALESCE(points, 0) DESC, name COLLATE NOCASE ASC
          ''');
      } catch (e) {
        debugPrint('Leaderboard load error: $e');
      }

      int rank = 0;
      for (int i = 0; i < users.length; i++) {
        if (_safeInt(users[i]['id']) == userId) {
          rank = i + 1;
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        questionCount = questionResult;
        answerCount = answerResult;
        savedQuestionCount =
            (savedQuestionsResult as List<Map<String, dynamic>>).length;
        savedResourceCount = savedResourcesResult;
        contributionScore = points;
        currentRank = rank;
        leaderboardUsers = users;
        loadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingStats = false;
      });

      debugPrint('Profile statistics error: $e');
    }
  }

  int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _getReputationLevel(int points) {
    if (points >= 100) return 'Community Champion';
    if (points >= 50) return 'Helpful Member';
    if (points >= 20) return 'Active Student';
    return 'New Member';
  }

  Widget _rankBadge(int rank) {
    final theme = Theme.of(context);

    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: rank <= 3
            ? theme.colorScheme.primary
            : theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: rank <= 3
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    final theme = Theme.of(context);

    if (leaderboardUsers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 10),
              const Text(
                'No leaderboard data yet',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                'Start asking, answering and sharing resources to earn points.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final visibleUsers = leaderboardUsers.length > 5
        ? leaderboardUsers.take(5).toList()
        : leaderboardUsers;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
        child: Column(
          children: [
            ...List.generate(visibleUsers.length, (index) {
              final user = visibleUsers[index];
              final rank = index + 1;
              final name = user['name']?.toString().trim().isNotEmpty == true
                  ? user['name'].toString().trim()
                  : 'Unknown User';
              final points = _safeInt(user['points']);
              final isCurrentUser = _safeInt(user['id']) == auth.currentUserId;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.45,
                        ),
                  borderRadius: BorderRadius.circular(14),
                  border: isCurrentUser
                      ? Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.35,
                          ),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    _rankBadge(rank),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        name.isEmpty ? 'S' : name[0].toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCurrentUser ? '$name (You)' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getReputationLevel(points),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$points pts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (currentRank > 5) ...[
              const SizedBox(height: 6),
              Text(
                'Your rank: #$currentRank  •  $contributionScore pts',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showContributionScoreDialog() {
    final theme = Theme.of(context);

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
                      '$contributionScore points',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      currentRank > 0
                          ? 'Community Rank #$currentRank'
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
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _profilePointRule('Ask a question', '+2 points'),
              _profilePointRule('Answer a question', '+5 points'),
              _profilePointRule('Share a resource', '+4 points'),
              _profilePointRule('Helpful answer', '+3 points'),
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

  Widget _profilePointRule(String title, String points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 7, color: Color(0xFF4F46E5)),
          const SizedBox(width: 9),
          Expanded(child: Text(title)),
          const SizedBox(width: 8),
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

  void _showFullLeaderboard() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.emoji_events_outlined),
              SizedBox(width: 10),
              Text('Leaderboard'),
            ],
          ),
          content: SizedBox(
            width: 520,
            height: 500,
            child: leaderboardUsers.isEmpty
                ? const Center(child: Text('No leaderboard data available.'))
                : ListView.builder(
                    itemCount: leaderboardUsers.length,
                    itemBuilder: (context, index) {
                      final user = leaderboardUsers[index];
                      final rank = index + 1;
                      final name =
                          user['name']?.toString().trim().isNotEmpty == true
                          ? user['name'].toString().trim()
                          : 'Unknown User';
                      final points = _safeInt(user['points']);
                      final isCurrentUser =
                          _safeInt(user['id']) == auth.currentUserId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? theme.colorScheme.primaryContainer
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: _rankBadge(rank),
                          title: Text(
                            isCurrentUser ? '$name (You)' : name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(_getReputationLevel(points)),
                          trailing: Text(
                            '$points pts',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
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
  // SAVE PROFILE
  // ============================================================

  Future<void> saveProfile() async {
    final userId = auth.currentUserId;

    if (userId == null) return;

    final name = nameController.text.trim();
    final course = courseController.text.trim();
    final college = collegeController.text.trim();

    if (name.isEmpty) {
      showMessage('Please enter your name.');
      return;
    }

    if (course.isEmpty) {
      showMessage('Please enter your course.');
      return;
    }

    if (college.isEmpty) {
      showMessage('Please enter your college.');
      return;
    }

    setState(() {
      savingProfile = true;
    });

    try {
      await auth.updateProfile(
        userId: userId,
        name: name,
        course: course,
        college: college,
      );

      if (!mounted) return;

      setState(() {
        savingProfile = false;
      });

      showMessage('Profile updated successfully! 🎉');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        savingProfile = false;
      });

      showMessage('Unable to update profile.');
    }
  }

  // ============================================================
  // LOGOUT CONFIRMATION
  // ============================================================

  Future<void> logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    auth.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration decoration(String label, IconData icon) {
    final theme = Theme.of(context);

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest,
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
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget statCard({
    required BuildContext context,
    required String value,
    required String title,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(icon, color: theme.colorScheme.primary),
              ),

              const SizedBox(height: 10),

              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  void _navigateFromShell(int index) {
    if (index == 6) return;
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }
    if (index == 1) {
      Navigator.pushNamed(context, '/dashboard');
      return;
    }
    if (index == 2) {
      Navigator.pushNamed(context, '/dashboard');
      return;
    }
    Navigator.pushNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final firstLetter = auth.currentUserName.isNotEmpty
        ? auth.currentUserName[0].toUpperCase()
        : 'S';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loadStatistics,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: loadStatistics,
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                children: [
                  // ==================================================
                  // PROFILE HEADER
                  // ==================================================

                  CircleAvatar(
                    radius: 55,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    auth.currentUserName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    auth.currentUserEmail,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // ACTIVITY TITLE
                  // ==================================================
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Your Activity',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ==================================================
                  // STATISTICS ROW 1
                  // ==================================================
                  Row(
                    children: [
                      statCard(
                        context: context,
                        value: loadingStats ? '...' : questionCount.toString(),
                        title: 'Questions Asked',
                        icon: Icons.question_answer_outlined,
                      ),

                      const SizedBox(width: 10),

                      statCard(
                        context: context,
                        value: loadingStats ? '...' : answerCount.toString(),
                        title: 'Answers Given',
                        icon: Icons.forum_outlined,
                      ),
                    ],
                  ),

                  // ==================================================
                  // STATISTICS ROW 2
                  // ==================================================
                  Row(
                    children: [
                      statCard(
                        context: context,
                        value: loadingStats
                            ? '...'
                            : savedQuestionCount.toString(),
                        title: 'Saved Questions',
                        icon: Icons.bookmark_outline,
                      ),

                      const SizedBox(width: 10),

                      statCard(
                        context: context,
                        value: loadingStats
                            ? '...'
                            : savedResourceCount.toString(),
                        title: 'Saved Resources',
                        icon: Icons.library_books_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // CONTRIBUTION SCORE
                  // ==================================================
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Contribution Score',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    elevation: 1,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primaryContainer,
                            theme.colorScheme.surface,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: theme.colorScheme.primary,
                            child: Icon(
                              Icons.emoji_events_outlined,
                              color: theme.colorScheme.onPrimary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loadingStats
                                      ? 'Loading...'
                                      : '$contributionScore points',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  loadingStats
                                      ? 'Calculating your contribution'
                                      : _getReputationLevel(contributionScore),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!loadingStats && currentRank > 0)
                            Column(
                              children: [
                                Text(
                                  '#$currentRank',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  'Rank',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // LEADERBOARD
                  // ==================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Leaderboard',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: loadingStats ? null : _showFullLeaderboard,
                        child: const Text('View All'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _buildLeaderboardSection(),

                  const SizedBox(height: 18),

                  // ==================================================
                  // COMMUNITY OPTIONS
                  // ==================================================
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.emoji_events_outlined,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: const Text(
                            'Contribution Score',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            loadingStats
                                ? 'Loading score...'
                                : '$contributionScore points • Rank #$currentRank',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 15,
                          ),
                          onTap: () {
                            if (loadingStats) return;
                            _showContributionScoreDialog();
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.leaderboard_outlined,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: const Text(
                            'Leaderboard',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text(
                            'See community rankings and top contributors',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 15,
                          ),
                          onTap: loadingStats ? null : _showFullLeaderboard,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // ACCOUNT INFORMATION
                  // ==================================================
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Account Information',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // NAME
                          TextField(
                            controller: nameController,
                            decoration: decoration('Full Name', Icons.person),
                          ),

                          const SizedBox(height: 15),

                          // EMAIL
                          TextField(
                            enabled: false,
                            controller: TextEditingController(
                              text: auth.currentUserEmail,
                            ),
                            decoration: decoration('Email', Icons.email),
                          ),

                          const SizedBox(height: 15),

                          // COURSE
                          TextField(
                            controller: courseController,
                            decoration: decoration('Course', Icons.menu_book),
                          ),

                          const SizedBox(height: 15),

                          // COLLEGE
                          TextField(
                            controller: collegeController,
                            decoration: decoration(
                              'College',
                              Icons.account_balance,
                            ),
                          ),

                          const SizedBox(height: 22),

                          // SAVE
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: savingProfile ? null : saveProfile,
                              icon: savingProfile
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                savingProfile ? 'SAVING...' : 'SAVE CHANGES',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // LOGOUT
                  // ==================================================
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('LOGOUT'),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
          ? StudentBottomNavigation(selectedIndex: 4, onSelected: _navigateFromShell)
          : null,
    );
  }
}
