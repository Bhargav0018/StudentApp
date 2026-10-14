import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/admin_service.dart';
import '../database/database_helper.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService.instance;

  int _selectedIndex = 0;
  bool _loading = true;

  int _userCount = 0;
  int _questionCount = 0;
  int _answerCount = 0;
  int _resourceCount = 0;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _answers = [];
  List<Map<String, dynamic>> _resources = [];

  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);

    _loadDashboard();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();

    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;

    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  // ============================================================
  // MESSAGE HELPER
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? Colors.redAccent
              : Theme.of(context).colorScheme.primary,
        ),
      );
  }

  // ============================================================
  // LOAD DASHBOARD
  // ============================================================

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final userCount = await _adminService.getUserCount();
      final questionCount = await _adminService.getQuestionCount();
      final answerCount = await _adminService.getAnswerCount();
      final resourceCount = await _adminService.getResourceCount();

      // Read users directly from the SQLite database so the latest
      // reputation points are always available in the admin dashboard.
      // This keeps the existing AdminService CRUD functionality intact.
      final users = await DatabaseHelper.instance.rawQuery('''
        SELECT *
        FROM users
        ORDER BY id DESC
      ''');

      final questions = await _adminService.getAllQuestions();
      final answers = await _adminService.getAllAnswers();
      final resources = await _adminService.getAllResources();

      if (!mounted) return;

      setState(() {
        _userCount = userCount;
        _questionCount = questionCount;
        _answerCount = answerCount;
        _resourceCount = resourceCount;

        _users = users;
        _questions = questions;
        _answers = answers;
        _resources = resources;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load admin data: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // SAFE INTEGER
  // ============================================================

  int _safeInt(dynamic value) {
    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // ============================================================
  // FILTERED USERS
  // ============================================================

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _users;
    }

    return _users.where((user) {
      final name = user['name']?.toString().toLowerCase() ?? '';
      final email = user['email']?.toString().toLowerCase() ?? '';
      final course = user['course']?.toString().toLowerCase() ?? '';
      final college = user['college']?.toString().toLowerCase() ?? '';

      return name.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          course.contains(_searchQuery) ||
          college.contains(_searchQuery);
    }).toList();
  }

  // ============================================================
  // FILTERED QUESTIONS
  // ============================================================

  List<Map<String, dynamic>> get _filteredQuestions {
    if (_searchQuery.isEmpty) {
      return _questions;
    }

    return _questions.where((question) {
      final title = question['title']?.toString().toLowerCase() ?? '';

      final description =
          question['description']?.toString().toLowerCase() ?? '';

      final category = question['category']?.toString().toLowerCase() ?? '';

      final userName = question['user_name']?.toString().toLowerCase() ?? '';

      return title.contains(_searchQuery) ||
          description.contains(_searchQuery) ||
          category.contains(_searchQuery) ||
          userName.contains(_searchQuery);
    }).toList();
  }

  // ============================================================
  // FILTERED ANSWERS
  // ============================================================

  List<Map<String, dynamic>> get _filteredAnswers {
    if (_searchQuery.isEmpty) {
      return _answers;
    }

    return _answers.where((answer) {
      final answerText = answer['answer']?.toString().toLowerCase() ?? '';

      final questionTitle =
          answer['question_title']?.toString().toLowerCase() ?? '';

      final userName = answer['user_name']?.toString().toLowerCase() ?? '';

      return answerText.contains(_searchQuery) ||
          questionTitle.contains(_searchQuery) ||
          userName.contains(_searchQuery);
    }).toList();
  }

  // ============================================================
  // FILTERED RESOURCES
  // ============================================================

  List<Map<String, dynamic>> get _filteredResources {
    if (_searchQuery.isEmpty) {
      return _resources;
    }

    return _resources.where((resource) {
      final title = resource['title']?.toString().toLowerCase() ?? '';

      final description =
          resource['description']?.toString().toLowerCase() ?? '';

      final category = resource['category']?.toString().toLowerCase() ?? '';

      final userName = resource['user_name']?.toString().toLowerCase() ?? '';

      return title.contains(_searchQuery) ||
          description.contains(_searchQuery) ||
          category.contains(_searchQuery) ||
          userName.contains(_searchQuery);
    }).toList();
  }

  // ============================================================
  // SEARCH FIELD
  // ============================================================

  Widget _searchField({required String hintText, required IconData icon}) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: theme.colorScheme.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear),
                )
              : null,
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.55,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DELETE QUESTION
  // ============================================================

  Future<void> _deleteQuestion(Map<String, dynamic> question) async {
    final id = _safeInt(question['id']);

    final confirm = await _confirmDelete(
      title: 'Delete Question?',
      message:
          'This will also remove all answers associated with this question.',
    );

    if (!confirm) return;

    try {
      await _adminService.deleteQuestion(id);

      await _loadDashboard();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question deleted successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete question: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // DELETE ANSWER
  // ============================================================

  Future<void> _deleteAnswer(Map<String, dynamic> answer) async {
    final id = _safeInt(answer['id']);

    final confirm = await _confirmDelete(
      title: 'Delete Answer?',
      message: 'This answer will be permanently removed.',
    );

    if (!confirm) return;

    try {
      await _adminService.deleteAnswer(id);

      await _loadDashboard();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Answer deleted successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete answer: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // DELETE RESOURCE
  // ============================================================

  Future<void> _deleteResource(Map<String, dynamic> resource) async {
    final id = _safeInt(resource['id']);

    final confirm = await _confirmDelete(
      title: 'Delete Resource?',
      message: 'This resource will be removed from the community and saved-resource lists.',
    );

    if (!confirm) return;

    try {
      await _adminService.deleteResource(id);

      await _loadDashboard();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resource deleted successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete resource: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // DELETE USER
  // ============================================================

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final userId = _safeInt(user['id']);

    final userName = user['name']?.toString().trim().isNotEmpty == true
        ? user['name'].toString()
        : 'this user';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete User?'),
          content: Text(
            'Are you sure you want to delete "$userName"?\n\n'
            'This will also remove the user\'s questions, '
            'answers, resources, saved items and notifications.',
          ),
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
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _adminService.deleteUser(userId);

      await _loadDashboard();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$userName deleted successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete user: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // CONFIRM DELETE
  // ============================================================

  Future<bool> _confirmDelete({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout from admin dashboard?',
          ),
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

    if (confirm != true) return;

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required String title,
    required int count,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OVERVIEW
  // ============================================================

  Widget _buildOverview() {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor the Student Help Community',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 4 : 2;

              final width =
                  (constraints.maxWidth - ((columns - 1) * 16)) / columns;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: width,
                    child: _statCard(
                      title: 'Users',
                      count: _userCount,
                      icon: Icons.people_outline,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _statCard(
                      title: 'Questions',
                      count: _questionCount,
                      icon: Icons.help_outline,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _statCard(
                      title: 'Answers',
                      count: _answerCount,
                      icon: Icons.question_answer_outlined,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _statCard(
                      title: 'Resources',
                      count: _resourceCount,
                      icon: Icons.menu_book_outlined,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Access',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'As an administrator you can monitor users, '
                    'questions, answers and resources. '
                    'You can also remove irrelevant content '
                    'and manage registered users.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _quickButton('View Users', Icons.people_outline, 1),
                      _quickButton('View Questions', Icons.help_outline, 2),
                      _quickButton(
                        'View Answers',
                        Icons.question_answer_outlined,
                        3,
                      ),
                      _quickButton(
                        'View Resources',
                        Icons.menu_book_outlined,
                        4,
                      ),
                      _quickButton('Analytics', Icons.analytics_outlined, 5),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Community Summary',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _summaryRow(
                    Icons.people_outline,
                    'Registered Students',
                    _userCount,
                  ),
                  _summaryRow(
                    Icons.help_outline,
                    'Community Questions',
                    _questionCount,
                  ),
                  _summaryRow(
                    Icons.question_answer_outlined,
                    'Answers Shared',
                    _answerCount,
                  ),
                  _summaryRow(
                    Icons.menu_book_outlined,
                    'Learning Resources',
                    _resourceCount,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.emoji_events_outlined,
                      color: theme.colorScheme.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Community Reputation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Students earn reputation points by asking '
                          'questions, answering questions, sharing '
                          'resources and receiving helpful votes.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _reputationInfoChip(
                              Icons.help_outline,
                              '+2 Question',
                            ),
                            _reputationInfoChip(
                              Icons.question_answer_outlined,
                              '+5 Answer',
                            ),
                            _reputationInfoChip(
                              Icons.menu_book_outlined,
                              '+4 Resource',
                            ),
                            _reputationInfoChip(
                              Icons.thumb_up_alt_outlined,
                              '+3 Helpful',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (_users.isNotEmpty) _buildTopContributors(theme),
        ],
      ),
    );
  }

  // ============================================================
  // REPUTATION CHIP
  // ============================================================

  Widget _reputationInfoChip(IconData icon, String text) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP CONTRIBUTORS
  // ============================================================

  Widget _buildTopContributors(ThemeData theme) {
    final sortedUsers = List<Map<String, dynamic>>.from(_users);

    sortedUsers.sort((a, b) {
      final aPoints = _safeInt(a['points']);
      final bPoints = _safeInt(b['points']);

      return bPoints.compareTo(aPoints);
    });

    final topUsers = sortedUsers.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Top Contributors',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  'Top 5',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...List.generate(topUsers.length, (index) {
              final user = topUsers[index];

              final name = user['name']?.toString().trim().isNotEmpty == true
                  ? user['name'].toString()
                  : 'Unknown User';

              final points = _safeInt(user['points']);

              final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: index == 0
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _rankBadge(index + 1),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _getReputationLevel(points),
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$points',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            'points',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RANK BADGE
  // ============================================================

  Widget _rankBadge(int rank) {
    final theme = Theme.of(context);

    IconData icon;

    if (rank == 1) {
      icon = Icons.looks_one;
    } else if (rank == 2) {
      icon = Icons.looks_two;
    } else if (rank == 3) {
      icon = Icons.looks_3;
    } else {
      icon = Icons.star_outline;
    }

    return Icon(icon, size: 28, color: theme.colorScheme.primary);
  }

  // ============================================================
  // REPUTATION LEVEL
  // ============================================================

  String _getReputationLevel(int points) {
    if (points >= 100) {
      return 'Community Champion';
    }

    if (points >= 50) {
      return 'Helpful Member';
    }

    if (points >= 20) {
      return 'Active Student';
    }

    return 'New Member';
  }

  // ============================================================
  // SUMMARY ROW
  // ============================================================

  Widget _summaryRow(IconData icon, String title, int count) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 21, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK BUTTON
  // ============================================================

  Widget _quickButton(String title, IconData icon, int index) {
    return OutlinedButton.icon(
      onPressed: () {
        _clearSearch();

        setState(() {
          _selectedIndex = index;
        });
      },
      icon: Icon(icon),
      label: Text(title),
    );
  }

  // ============================================================
  // USERS
  // ============================================================

  Widget _buildUsers() {
    final users = _filteredUsers;

    return _buildDataPage(
      title: 'All Users',
      icon: Icons.people_outline,
      searchHint: 'Search by name, email, course or college...',
      child: users.isEmpty
          ? _emptyMessage(
              _searchQuery.isNotEmpty
                  ? 'No users found for "$_searchQuery".'
                  : 'No users registered yet.',
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              itemCount: users.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = users[index];

                final name = user['name']?.toString().trim().isNotEmpty == true
                    ? user['name'].toString()
                    : 'Unknown User';

                final email = user['email']?.toString() ?? '';

                final course = user['course']?.toString() ?? '';

                final college = user['college']?.toString() ?? '';

                final points = _safeInt(user['points']);

                final firstLetter = name.isNotEmpty
                    ? name[0].toUpperCase()
                    : 'U';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Text(
                                firstLetter,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.emoji_events_outlined,
                                    size: 17,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$points',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'User actions',
                              onSelected: (value) {
                                if (value == 'details') {
                                  _showUserDetails(user);
                                } else if (value == 'delete') {
                                  _deleteUser(user);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'details',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_outline),
                                      SizedBox(width: 10),
                                      Text('View Details'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Delete User',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        _userInfoRow(Icons.email_outlined, 'Email', email),
                        _userInfoRow(
                          Icons.menu_book_outlined,
                          'Course',
                          course.isEmpty ? 'Not provided' : course,
                        ),
                        _userInfoRow(
                          Icons.account_balance_outlined,
                          'College',
                          college.isEmpty ? 'Not provided' : college,
                        ),
                        _userInfoRow(
                          Icons.calendar_today_outlined,
                          'Registered',
                          _formatDate(user['created_at']),
                        ),
                        _userInfoRow(
                          Icons.emoji_events_outlined,
                          'Points',
                          '$points points',
                        ),
                        _userInfoRow(
                          Icons.workspace_premium_outlined,
                          'Level',
                          _getReputationLevel(points),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _showUserDetails(user);
                                },
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('DETAILS'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _deleteUser(user);
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'DELETE',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ============================================================
  // USER INFORMATION ROW
  // ============================================================

  Widget _userInfoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // USER DETAILS
  // ============================================================

  void _showUserDetails(Map<String, dynamic> user) {
    final name = user['name']?.toString() ?? 'Unknown User';

    final email = user['email']?.toString() ?? '';

    final course = user['course']?.toString() ?? '';

    final college = user['college']?.toString() ?? '';

    final registered = _formatDate(user['created_at']);

    final points = _safeInt(user['points']);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.person_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              const Expanded(child: Text('User Details')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _detailItem('Name', name, Icons.person),
                _detailItem('Email', email, Icons.email),
                _detailItem(
                  'Course',
                  course.isEmpty ? 'Not provided' : course,
                  Icons.menu_book,
                ),
                _detailItem(
                  'College',
                  college.isEmpty ? 'Not provided' : college,
                  Icons.account_balance,
                ),
                _detailItem('Registered', registered, Icons.calendar_today),
                _detailItem(
                  'Reputation Points',
                  '$points points',
                  Icons.emoji_events,
                ),
                _detailItem(
                  'Community Level',
                  _getReputationLevel(points),
                  Icons.workspace_premium,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DETAIL ITEM
  // ============================================================

  Widget _detailItem(String title, String value, IconData icon) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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
  // VIEW QUESTION DETAILS
  // ============================================================

  Future<void> _showQuestionDetails(Map<String, dynamic> question) async {
    final questionId = _safeInt(question['id']);
    List<Map<String, dynamic>> answers = [];

    try {
      answers = await DatabaseHelper.instance.rawQuery(
        '''
        SELECT answers.*, users.name AS user_name
        FROM answers
        LEFT JOIN users ON answers.user_id = users.id
        WHERE answers.question_id = ?
        ORDER BY answers.id DESC
        ''',
        [questionId],
      );
    } catch (_) {}

    if (!mounted) return;

    final title = question['title']?.toString().trim().isNotEmpty == true
        ? question['title'].toString().trim()
        : 'Question';
    final description = question['description']?.toString() ?? '';
    final category = question['category']?.toString() ?? 'General';
    final userName = question['user_name']?.toString() ?? 'Unknown user';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.help_outline,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Question Details')),
            ],
          ),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.category_outlined, size: 17),
                        label: Text(category),
                      ),
                      Chip(
                        avatar: const Icon(Icons.person_outline, size: 17),
                        label: Text(userName),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _detailItem(
                    'Posted',
                    _formatDate(question['created_at']),
                    Icons.calendar_today_outlined,
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Question',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      description.isEmpty
                          ? 'No description provided.'
                          : description,
                      style: const TextStyle(fontSize: 15, height: 1.55),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.question_answer_outlined, size: 21),
                      const SizedBox(width: 8),
                      Text(
                        'Answers (${answers.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (answers.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'No answers have been posted for this question yet.',
                      ),
                    )
                  else
                    ...answers.map(
                      (answer) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 17,
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.person_outline,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    answer['user_name']?.toString() ??
                                        'Unknown user',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDate(answer['created_at']),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            Text(
                              answer['answer']?.toString() ?? '',
                              style: const TextStyle(height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CLOSE'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteQuestion(question);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('DELETE'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // VIEW ANSWER DETAILS
  // ============================================================

  Future<void> _showAnswerDetails(Map<String, dynamic> answer) async {
    final questionId = _safeInt(answer['question_id']);
    Map<String, dynamic>? question;

    try {
      final rows = await DatabaseHelper.instance.rawQuery(
        '''
        SELECT questions.*, users.name AS user_name
        FROM questions
        LEFT JOIN users ON questions.user_id = users.id
        WHERE questions.id = ?
        LIMIT 1
        ''',
        [questionId],
      );
      if (rows.isNotEmpty) question = rows.first;
    } catch (_) {}

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.question_answer_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Answer Details')),
            ],
          ),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Question',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      question?['title']?.toString() ??
                          'Question not available',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _detailItem(
                    'Answered by',
                    answer['user_name']?.toString() ?? 'Unknown user',
                    Icons.person_outline,
                  ),
                  _detailItem(
                    'Posted',
                    _formatDate(answer['created_at']),
                    Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Answer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      answer['answer']?.toString() ?? '',
                      style: const TextStyle(fontSize: 15, height: 1.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CLOSE'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteAnswer(answer);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('DELETE'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // RESOURCE HELPERS
  // ============================================================

  String _resourceType(Map<String, dynamic> resource) {
    final stored = resource['resource_type']?.toString().trim().toLowerCase();
    if (stored != null && stored.isNotEmpty) return stored;

    final mime = resource['mime_type']?.toString().toLowerCase() ?? '';
    final name = resource['file_name']?.toString().toLowerCase() ?? '';
    final url = resource['resource_url']?.toString().toLowerCase() ?? '';

    if (mime.startsWith('image/') ||
        RegExp(r'\.(jpg|jpeg|png|gif|webp|bmp)$').hasMatch(name)) {
      return 'image';
    }
    if (mime == 'application/pdf' || name.endsWith('.pdf')) return 'pdf';
    if (mime.startsWith('video/') ||
        RegExp(r'\.(mp4|mov|avi|mkv|webm|3gp)$').hasMatch(name)) {
      return 'video';
    }
    if (mime.contains('word') ||
        name.endsWith('.doc') ||
        name.endsWith('.docx')) {
      return 'document';
    }
    if (url.isNotEmpty) return 'link';
    return 'file';
  }

  IconData _resourceIcon(String type) {
    switch (type) {
      case 'image':
      case 'photo':
        return Icons.image_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'video':
        return Icons.video_library_outlined;
      case 'document':
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'link':
      case 'url':
        return Icons.link_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  String _resourceTypeLabel(String type) {
    switch (type) {
      case 'image':
      case 'photo':
        return 'IMAGE';
      case 'pdf':
        return 'PDF';
      case 'video':
        return 'VIDEO';
      case 'document':
      case 'doc':
      case 'docx':
        return 'DOCUMENT';
      case 'link':
      case 'url':
        return 'LINK';
      default:
        return 'FILE';
    }
  }

  Uint8List? _resourceBytes(Map<String, dynamic> resource) {
    final data = resource['file_data'];
    if (data == null) return null;
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    if (data is List) return Uint8List.fromList(List<int>.from(data));
    return null;
  }

  bool _isTextResource(Map<String, dynamic> resource, String type) {
    final mime = resource['mime_type']?.toString().toLowerCase() ?? '';
    final name = resource['file_name']?.toString().toLowerCase() ?? '';
    return type == 'text' ||
        mime.startsWith('text/') ||
        mime.contains('json') ||
        mime.contains('xml') ||
        name.endsWith('.txt') ||
        name.endsWith('.md') ||
        name.endsWith('.csv') ||
        name.endsWith('.json') ||
        name.endsWith('.xml') ||
        name.endsWith('.html');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _openResourceExternal(Map<String, dynamic> resource) async {
    final url = resource['resource_url']?.toString().trim() ?? '';

    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      if (mounted) {
        _showMessage('Unable to open this resource URL.', isError: true);
      }
      return;
    }

    final bytes = _resourceBytes(resource);
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        _showMessage(
          'This resource does not contain an openable file.',
          isError: true,
        );
      }
      return;
    }

    final mime = resource['mime_type']?.toString().trim().isNotEmpty == true
        ? resource['mime_type'].toString().trim()
        : 'application/octet-stream';

    try {
      final dataUri = Uri.dataFromBytes(bytes, mimeType: mime);
      if (await canLaunchUrl(dataUri)) {
        await launchUrl(dataUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    if (mounted) {
      _showMessage(
        'The stored file could not be opened externally on this device.',
        isError: true,
      );
    }
  }

  // ============================================================
  // VIEW RESOURCE DETAILS
  // ============================================================

  Future<void> _showResourceDetails(Map<String, dynamic> resource) async {
    final type = _resourceType(resource);
    final bytes = _resourceBytes(resource);
    final url = resource['resource_url']?.toString().trim() ?? '';
    final fileName = resource['file_name']?.toString().trim() ?? '';
    final mime = resource['mime_type']?.toString().trim() ?? '';

    String? textPreview;
    if (bytes != null && bytes.isNotEmpty && _isTextResource(resource, type)) {
      try {
        textPreview = utf8.decode(bytes, allowMalformed: true);
      } catch (_) {
        textPreview = 'Unable to decode this document as text.';
      }
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final isImage =
            (type == 'image' || type == 'photo') &&
            bytes != null &&
            bytes.isNotEmpty;

        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  _resourceIcon(type),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(child: Text('Resource Details')),
            ],
          ),
          content: SizedBox(
            width: 680,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource['title']?.toString() ?? 'Resource',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: Icon(_resourceIcon(type), size: 17),
                        label: Text(_resourceTypeLabel(type)),
                      ),
                      Chip(
                        avatar: const Icon(Icons.category_outlined, size: 17),
                        label: Text(
                          resource['category']?.toString() ?? 'General',
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.person_outline, size: 17),
                        label: Text(
                          resource['user_name']?.toString() ?? 'Unknown user',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if ((resource['description']?.toString() ?? '')
                      .trim()
                      .isNotEmpty)
                    Text(
                      resource['description'].toString(),
                      style: const TextStyle(height: 1.5),
                    ),
                  const SizedBox(height: 15),
                  if (isImage)
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 420),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: InteractiveViewer(
                          child: Image.memory(
                            bytes ?? Uint8List(0),
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Center(
                              child: Text('Unable to preview this image.'),
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (textPreview != null)
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 360),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          textPreview,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _resourceIcon(type),
                            size: 58,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _resourceTypeLabel(type) == 'PDF'
                                ? 'PDF document'
                                : _resourceTypeLabel(type) == 'VIDEO'
                                ? 'Video file'
                                : 'Stored file',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            fileName.isNotEmpty
                                ? fileName
                                : 'File stored in SQLite',
                            textAlign: TextAlign.center,
                          ),
                          if (mime.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              mime,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (bytes != null && bytes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'File size: ${_formatFileSize(bytes.length)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (url.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        url,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    'Posted: ${_formatDate(resource['created_at'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (url.isNotEmpty || (bytes != null && bytes.isNotEmpty))
              OutlinedButton.icon(
                onPressed: () => _openResourceExternal(resource),
                icon: const Icon(Icons.open_in_new),
                label: Text(url.isNotEmpty ? 'OPEN LINK' : 'OPEN FILE'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CLOSE'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteResource(resource);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('DELETE'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // QUESTIONS
  // ============================================================

  Widget _buildQuestions() {
    final questions = _filteredQuestions;

    return _buildDataPage(
      title: 'All Questions',
      icon: Icons.help_outline,
      searchHint: 'Search by title, description, category or user...',
      child: questions.isEmpty
          ? _emptyMessage(
              _searchQuery.isNotEmpty
                  ? 'No questions found for "$_searchQuery".'
                  : 'No questions available.',
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              itemCount: questions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final question = questions[index];
                return Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 23,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Icon(
                                Icons.help_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                question['title']?.toString() ?? 'Question',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          question['description']?.toString() ?? '',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(height: 1.45),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              avatar: const Icon(
                                Icons.category_outlined,
                                size: 18,
                              ),
                              label: Text(
                                question['category']?.toString() ?? 'General',
                              ),
                            ),
                            Chip(
                              avatar: const Icon(
                                Icons.person_outline,
                                size: 18,
                              ),
                              label: Text(
                                question['user_name']?.toString() ??
                                    'Unknown user',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Posted: ${_formatDate(question['created_at'])}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showQuestionDetails(question),
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('VIEW QUESTION'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              tooltip: 'Delete question',
                              onPressed: () => _deleteQuestion(question),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ============================================================
  // ANSWERS
  // ============================================================

  Widget _buildAnswers() {
    final answers = _filteredAnswers;

    return _buildDataPage(
      title: 'All Answers',
      icon: Icons.question_answer_outlined,
      searchHint: 'Search by answer, question title or user...',
      child: answers.isEmpty
          ? _emptyMessage(
              _searchQuery.isNotEmpty
                  ? 'No answers found for "$_searchQuery".'
                  : 'No answers available.',
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              itemCount: answers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final answer = answers[index];
                return Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 23,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Icon(
                                Icons.question_answer_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                answer['question_title']?.toString() ??
                                    'Question',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            answer['answer']?.toString() ?? '',
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Answered by: ${answer['user_name'] ?? 'Unknown user'}',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Posted: ${_formatDate(answer['created_at'])}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showAnswerDetails(answer),
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('VIEW ANSWER'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              tooltip: 'Delete answer',
                              onPressed: () => _deleteAnswer(answer),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ============================================================
  // RESOURCES
  // ============================================================

  Widget _buildResources() {
    final resources = _filteredResources;

    return _buildDataPage(
      title: 'All Resources',
      icon: Icons.menu_book_outlined,
      searchHint: 'Search by title, description, category or user...',
      child: resources.isEmpty
          ? _emptyMessage(
              _searchQuery.isNotEmpty
                  ? 'No resources found for "$_searchQuery".'
                  : 'No resources available.',
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              itemCount: resources.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final resource = resources[index];
                final type = _resourceType(resource);
                final bytes = _resourceBytes(resource);
                final url = resource['resource_url']?.toString().trim() ?? '';
                final fileName = resource['file_name']?.toString().trim() ?? '';

                return Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 52,
                              width: 52,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                _resourceIcon(type),
                                color: Theme.of(context).colorScheme.primary,
                                size: 27,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resource['title']?.toString() ?? 'Resource',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    fileName.isNotEmpty
                                        ? fileName
                                        : _resourceTypeLabel(type),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _resourceTypeLabel(type),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 13),
                        Text(
                          resource['description']?.toString() ?? '',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(height: 1.45),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text(
                                resource['category']?.toString() ?? 'General',
                              ),
                            ),
                            Chip(
                              avatar: const Icon(
                                Icons.person_outline,
                                size: 18,
                              ),
                              label: Text(
                                resource['user_name']?.toString() ?? 'Unknown',
                              ),
                            ),
                            if (bytes != null && bytes.isNotEmpty)
                              Chip(
                                avatar: const Icon(
                                  Icons.data_object_outlined,
                                  size: 17,
                                ),
                                label: Text(_formatFileSize(bytes.length)),
                              ),
                          ],
                        ),
                        if (url.isNotEmpty) ...[
                          const SizedBox(height: 9),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              url,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Posted: ${_formatDate(resource['created_at'])}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showResourceDetails(resource),
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('VIEW RESOURCE'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              tooltip: 'Delete resource',
                              onPressed: () => _deleteResource(resource),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ============================================================
  // ANALYTICS
  // ============================================================

  Widget _buildAnalytics() {
    final theme = Theme.of(context);

    final questionCategories = _categoryCounts(_questions, 'category');

    final resourceCategories = _categoryCounts(_resources, 'category');

    final reputation = _reputationDistribution();

    final monthlyUsers = _monthlyUserCounts();

    final topUsers = _sortedUsersByPoints();

    final activeUsers = _activeUserCount();

    final inactiveUsers = _inactiveUserCount();

    final averageAnswers = _averageAnswersPerQuestion();

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: theme.colorScheme.primary,
                size: 30,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Advanced Analytics',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Refresh analytics',
                onPressed: _loadDashboard,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Insights generated from the current SQLite community data.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),

          const SizedBox(height: 24),

          // ======================================================
          // MAIN STATISTICS
          // ======================================================
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1000
                  ? 4
                  : constraints.maxWidth >= 600
                  ? 2
                  : 1;

              final width =
                  (constraints.maxWidth - ((columns - 1) * 14)) / columns;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: width,
                    child: _analyticsMetric(
                      'Total Users',
                      _userCount,
                      Icons.people_outline,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _analyticsMetric(
                      'Questions',
                      _questionCount,
                      Icons.help_outline,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _analyticsMetric(
                      'Answers',
                      _answerCount,
                      Icons.question_answer_outlined,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _analyticsMetric(
                      'Resources',
                      _resourceCount,
                      Icons.menu_book_outlined,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // ======================================================
          // NEW: USER ACTIVITY + AVERAGE ANSWERS
          // ======================================================
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 800 ? 3 : 1;

              final width =
                  (constraints.maxWidth - ((columns - 1) * 14)) / columns;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: width,
                    child: _analyticsMetric(
                      'Active Users',
                      activeUsers,
                      Icons.person_outline,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _analyticsMetric(
                      'Inactive Users',
                      inactiveUsers,
                      Icons.person_off_outlined,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _analyticsMetricDouble(
                      'Avg Answers / Question',
                      averageAnswers,
                      Icons.forum_outlined,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // ======================================================
          // USER ACTIVITY
          // ======================================================
          _analyticsCard(
            title: 'User Activity Overview',
            icon: Icons.people_alt_outlined,
            child: _buildUserActivityOverview(activeUsers, inactiveUsers),
          ),

          const SizedBox(height: 20),

          // ======================================================
          // QUESTIONS VS ANSWERS
          // ======================================================
          _analyticsCard(
            title: 'Questions vs Answers',
            icon: Icons.compare_arrows_outlined,
            child: _buildComparisonChart(),
          ),

          const SizedBox(height: 20),

          // ======================================================
          // USER GROWTH
          // ======================================================
          _analyticsCard(
            title: 'User Growth - Last 6 Months',
            icon: Icons.trending_up_outlined,
            child: _buildUserGrowthChart(monthlyUsers),
          ),

          const SizedBox(height: 20),

          // ======================================================
          // RESOURCE STATISTICS
          // ======================================================
          _analyticsCard(
            title: 'Resources Statistics',
            icon: Icons.library_books_outlined,
            child: _buildResourceStatistics(),
          ),

          const SizedBox(height: 20),

          // ======================================================
          // TOP CONTRIBUTORS
          // ======================================================
          _analyticsCard(
            title: 'Top Contributors',
            icon: Icons.emoji_events_outlined,
            child: _buildAnalyticsTopContributors(topUsers),
          ),

          const SizedBox(height: 20),

          // ======================================================
          // REPUTATION
          // ======================================================
          _analyticsCard(
            title: 'Reputation Distribution',
            icon: Icons.workspace_premium_outlined,
            child: _buildReputationChart(reputation),
          ),

          const SizedBox(height: 20),

          // ======================================================
          // COMBINED CATEGORY ANALYSIS
          // ======================================================
          _analyticsCard(
            title: 'Combined Category Analysis',
            icon: Icons.category_outlined,
            child: _buildCombinedCategoryChart(
              questionCategories,
              resourceCategories,
            ),
          ),

          const SizedBox(height: 20),

          // ======================================================
          // QUESTIONS CATEGORY
          // ======================================================
          _analyticsCard(
            title: 'Category-wise Questions',
            icon: Icons.help_outline,
            child: _buildCategoryChart(
              questionCategories,
              emptyText: 'No question categories available.',
            ),
          ),

          const SizedBox(height: 20),

          // ======================================================
          // RESOURCE CATEGORY
          // ======================================================
          _analyticsCard(
            title: 'Category-wise Resources',
            icon: Icons.folder_outlined,
            child: _buildCategoryChart(
              resourceCategories,
              emptyText: 'No resource categories available.',
            ),
          ),

          const SizedBox(height: 20),

          // ======================================================
          // CONTENT SUMMARY
          // ======================================================
          _analyticsCard(
            title: 'Community Content Summary',
            icon: Icons.insights_outlined,
            child: _buildContentSummary(),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ============================================================
  // ANALYTICS METRIC
  // ============================================================

  Widget _analyticsMetric(String title, int value, IconData icon) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DOUBLE ANALYTICS METRIC
  // ============================================================

  Widget _analyticsMetricDouble(String title, double value, IconData icon) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ANALYTICS CARD
  // ============================================================

  Widget _analyticsCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  // ============================================================
  // USER ACTIVITY COUNT
  // ============================================================

  // ============================================================
  // USER ACTIVITY - LAST 30 DAYS
  // ============================================================
  //
  // Active User:
  // At least one question, answer, or resource created in the
  // last 30 days.
  //
  // Inactive User:
  // No question, answer, or resource created in the last 30 days.
  //
  // IMPORTANT:
  // Reputation points are NOT used for Active/Inactive status.
  // ============================================================

  bool _isWithinLast30Days(dynamic value) {
    if (value == null) return false;

    try {
      final date = DateTime.parse(value.toString());
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(days: 30));

      return !date.isBefore(cutoff) && !date.isAfter(now);
    } catch (_) {
      return false;
    }
  }

  bool _isUserActiveLast30Days(Map<String, dynamic> user) {
    final userId = _safeInt(user['id']);

    if (userId <= 0) return false;

    final hasRecentQuestion = _questions.any((question) {
      return _safeInt(question['user_id']) == userId &&
          _isWithinLast30Days(question['created_at']);
    });

    if (hasRecentQuestion) return true;

    final hasRecentAnswer = _answers.any((answer) {
      return _safeInt(answer['user_id']) == userId &&
          _isWithinLast30Days(answer['created_at']);
    });

    if (hasRecentAnswer) return true;

    final hasRecentResource = _resources.any((resource) {
      return _safeInt(resource['user_id']) == userId &&
          _isWithinLast30Days(resource['created_at']);
    });

    return hasRecentResource;
  }

  int _activeUserCount() {
    return _users.where(_isUserActiveLast30Days).length;
  }

  int _inactiveUserCount() {
    return _users.where((user) => !_isUserActiveLast30Days(user)).length;
  }

  String _getUserActivityStatus(Map<String, dynamic> user) {
    return _isUserActiveLast30Days(user) ? 'Active' : 'Inactive';
  }

  String _getUserActivityDescription(Map<String, dynamic> user) {
    if (_isUserActiveLast30Days(user)) {
      return 'Contributed within the last 30 days';
    }

    return 'No contribution in the last 30 days';
  }

  // ============================================================
  // USER ACTIVITY OVERVIEW
  // ============================================================

  Widget _buildUserActivityOverview(int activeUsers, int inactiveUsers) {
    final total = activeUsers + inactiveUsers;

    if (total == 0) {
      return _smallEmpty('No users available for activity analysis.');
    }

    final activePercentage = activeUsers / total * 100;

    final inactivePercentage = inactiveUsers / total * 100;

    return Column(
      children: [
        _percentageRow(
          'Active Users',
          activeUsers,
          activePercentage.toStringAsFixed(1),
          Icons.person_outline,
        ),
        const SizedBox(height: 14),
        _percentageRow(
          'Inactive Users',
          inactiveUsers,
          inactivePercentage.toStringAsFixed(1),
          Icons.person_off_outlined,
        ),
        const SizedBox(height: 20),
        _barRow('Active', activeUsers, total, Icons.check_circle_outline),
        const SizedBox(height: 16),
        _barRow('Inactive', inactiveUsers, total, Icons.remove_circle_outline),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'Active = created at least one question, answer, or resource '
            'during the last 30 days. Inactive = no contribution during '
            'the last 30 days. Login activity and reputation points are '
            'not used for this classification.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // AVERAGE ANSWERS PER QUESTION
  // ============================================================

  double _averageAnswersPerQuestion() {
    if (_questionCount == 0) {
      return 0;
    }

    return _answerCount / _questionCount;
  }

  // ============================================================
  // QUESTIONS VS ANSWERS CHART
  // ============================================================

  Widget _buildComparisonChart() {
    final theme = Theme.of(context);

    final maximum = [
      _questionCount,
      _answerCount,
    ].reduce((a, b) => a > b ? a : b);

    if (maximum == 0) {
      return _smallEmpty('No questions or answers available.');
    }

    return Column(
      children: [
        _barRow('Questions', _questionCount, maximum, Icons.help_outline),
        const SizedBox(height: 18),
        _barRow(
          'Answers',
          _answerCount,
          maximum,
          Icons.question_answer_outlined,
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            _answerCount >= _questionCount
                ? 'The community currently has more answers than questions.'
                : 'The community currently has more questions than answers.',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // GENERIC BAR
  // ============================================================

  Widget _barRow(String label, int value, int maximum, IconData icon) {
    final theme = Theme.of(context);

    final ratio = maximum == 0 ? 0.0 : value / maximum;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 19, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 11,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LAST 6 MONTHS USER GROWTH
  // ============================================================

  Map<String, int> _monthlyUserCounts() {
    final now = DateTime.now();

    final Map<String, int> result = {};

    // Create exactly last 6 months.
    for (int offset = 5; offset >= 0; offset--) {
      final date = DateTime(now.year, now.month - offset, 1);

      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      result[key] = 0;
    }

    for (final user in _users) {
      final raw = user['created_at'];

      if (raw == null) continue;

      try {
        final date = DateTime.parse(raw.toString());

        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';

        if (result.containsKey(key)) {
          result[key] = result[key]! + 1;
        }
      } catch (_) {}
    }

    return result;
  }

  Widget _buildUserGrowthChart(Map<String, int> data) {
    if (data.isEmpty) {
      return _smallEmpty('No registration data available.');
    }

    final maximum = data.values.isEmpty
        ? 0
        : data.values.reduce((a, b) => a > b ? a : b);

    final chartMaximum = maximum == 0 ? 1 : maximum;

    return Column(
      children: [
        ...data.entries.map((entry) {
          final parts = entry.key.split('-');

          final year = parts[0];

          final month = parts.length > 1
              ? _monthName(int.tryParse(parts[1]) ?? 1)
              : '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _barRow(
              '$month $year',
              entry.value,
              chartMaximum,
              Icons.person_add_alt_1_outlined,
            ),
          );
        }),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Showing registrations for the latest six calendar months.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }

  // ============================================================
  // RESOURCE STATISTICS
  // ============================================================

  Widget _buildResourceStatistics() {
    final categories = _categoryCounts(_resources, 'category');

    if (_resourceCount == 0) {
      return _smallEmpty('No resources have been shared yet.');
    }

    return Column(
      children: [
        _barRow(
          'Total Resources',
          _resourceCount,
          _resourceCount,
          Icons.library_books_outlined,
        ),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Resources by category',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...categories.entries.map((entry) {
            final maximum = categories.values.reduce((a, b) => a > b ? a : b);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _barRow(
                entry.key,
                entry.value,
                maximum,
                Icons.folder_outlined,
              ),
            );
          }),
        ],
      ],
    );
  }

  // ============================================================
  // CATEGORY COUNTS
  // ============================================================

  Map<String, int> _categoryCounts(
    List<Map<String, dynamic>> items,
    String field,
  ) {
    final Map<String, int> counts = {};

    for (final item in items) {
      final value = item[field]?.toString().trim();

      final category = value == null || value.isEmpty ? 'General' : value;

      counts[category] = (counts[category] ?? 0) + 1;
    }

    final entries = counts.entries.toList();

    entries.sort((a, b) => b.value.compareTo(a.value));

    return {for (final entry in entries) entry.key: entry.value};
  }

  // ============================================================
  // COMBINED CATEGORY ANALYSIS
  // ============================================================

  Widget _buildCombinedCategoryChart(
    Map<String, int> questionCategories,
    Map<String, int> resourceCategories,
  ) {
    final Set<String> categorySet = {
      ...questionCategories.keys,
      ...resourceCategories.keys,
    };

    if (categorySet.isEmpty) {
      return _smallEmpty('No category data available.');
    }

    final List<Map<String, dynamic>> combined = [];

    for (final category in categorySet) {
      final questions = questionCategories[category] ?? 0;

      final resources = resourceCategories[category] ?? 0;

      combined.add({
        'category': category,
        'questions': questions,
        'resources': resources,
        'total': questions + resources,
      });
    }

    combined.sort(
      (a, b) => _safeInt(b['total']).compareTo(_safeInt(a['total'])),
    );

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 19,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Questions and resources are compared within each category.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ...combined.map((item) {
          final category = item['category'].toString();

          final questions = _safeInt(item['questions']);

          final resources = _safeInt(item['resources']);

          final total = questions + resources;

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '$total total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _barRow(
                  'Questions',
                  questions,
                  total == 0 ? 1 : total,
                  Icons.help_outline,
                ),
                const SizedBox(height: 10),
                _barRow(
                  'Resources',
                  resources,
                  total == 0 ? 1 : total,
                  Icons.menu_book_outlined,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ============================================================
  // CATEGORY CHART
  // ============================================================

  Widget _buildCategoryChart(
    Map<String, int> categories, {
    required String emptyText,
  }) {
    if (categories.isEmpty) {
      return _smallEmpty(emptyText);
    }

    final maximum = categories.values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: categories.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _barRow(
            entry.key,
            entry.value,
            maximum,
            Icons.category_outlined,
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // TOP CONTRIBUTORS ANALYTICS
  // ============================================================

  List<Map<String, dynamic>> _sortedUsersByPoints() {
    final users = List<Map<String, dynamic>>.from(_users);

    users.sort((a, b) {
      final aPoints = _safeInt(a['points']);

      final bPoints = _safeInt(b['points']);

      final pointComparison = bPoints.compareTo(aPoints);

      if (pointComparison != 0) {
        return pointComparison;
      }

      final aName = a['name']?.toString().toLowerCase() ?? '';

      final bName = b['name']?.toString().toLowerCase() ?? '';

      return aName.compareTo(bName);
    });

    return users.take(5).toList();
  }

  Widget _buildAnalyticsTopContributors(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return _smallEmpty('No contributors available.');
    }

    final maximum = users
        .map((e) => _safeInt(e['points']))
        .fold<int>(0, (a, b) => a > b ? a : b);

    return Column(
      children: List.generate(users.length, (index) {
        final user = users[index];

        final name = user['name']?.toString().trim().isNotEmpty == true
            ? user['name'].toString()
            : 'Unknown User';

        final points = _safeInt(user['points']);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              Row(
                children: [
                  _rankBadge(index + 1),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '$points pts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: maximum == 0 ? 0 : (points / maximum).clamp(0.0, 1.0),
                minHeight: 8,
                borderRadius: BorderRadius.circular(20),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ============================================================
  // REPUTATION DISTRIBUTION
  // ============================================================

  Map<String, int> _reputationDistribution() {
    final result = {
      'New Member': 0,
      'Active Student': 0,
      'Helpful Member': 0,
      'Community Champion': 0,
    };

    for (final user in _users) {
      final points = _safeInt(user['points']);

      final level = _getReputationLevel(points);

      result[level] = (result[level] ?? 0) + 1;
    }

    return result;
  }

  Widget _buildReputationChart(Map<String, int> distribution) {
    final total = distribution.values.fold<int>(0, (sum, value) => sum + value);

    if (total == 0) {
      return _smallEmpty('No reputation data available.');
    }

    final icons = {
      'New Member': Icons.person_outline,
      'Active Student': Icons.school_outlined,
      'Helpful Member': Icons.volunteer_activism_outlined,
      'Community Champion': Icons.emoji_events_outlined,
    };

    return Column(
      children: distribution.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _barRow(
            '${entry.key} (${entry.value})',
            entry.value,
            total,
            icons[entry.key] ?? Icons.person_outline,
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // CONTENT SUMMARY
  // ============================================================

  Widget _buildContentSummary() {
    final totalContent = _questionCount + _answerCount + _resourceCount;

    if (totalContent == 0) {
      return _smallEmpty('No community content available.');
    }

    final questionPercent = (_questionCount / totalContent * 100)
        .toStringAsFixed(1);

    final answerPercent = (_answerCount / totalContent * 100).toStringAsFixed(
      1,
    );

    final resourcePercent = (_resourceCount / totalContent * 100)
        .toStringAsFixed(1);

    return Column(
      children: [
        _percentageRow(
          'Questions',
          _questionCount,
          questionPercent,
          Icons.help_outline,
        ),
        const SizedBox(height: 14),
        _percentageRow(
          'Answers',
          _answerCount,
          answerPercent,
          Icons.question_answer_outlined,
        ),
        const SizedBox(height: 14),
        _percentageRow(
          'Resources',
          _resourceCount,
          resourcePercent,
          Icons.menu_book_outlined,
        ),
      ],
    );
  }

  Widget _percentageRow(
    String title,
    int value,
    String percentage,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        SizedBox(
          width: 55,
          child: Text(
            '$percentage%',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SMALL EMPTY
  // ============================================================

  Widget _smallEmpty(String text) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 42,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMMON DATA PAGE
  // ============================================================

  Widget _buildDataPage({
    required String title,
    required IconData icon,
    required String searchHint,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loadDashboard,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        _searchField(hintText: searchHint, icon: Icons.search),
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
            child: Row(
              children: [
                Icon(
                  Icons.filter_alt_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Showing filtered results',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }

  // ============================================================
  // EMPTY MESSAGE
  // ============================================================

  Widget _emptyMessage(String message) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 150),
        Icon(
          Icons.inbox_outlined,
          size: 65,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 15),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null) {
      return '';
    }

    try {
      final date = DateTime.parse(value.toString());

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ========================================================
      // DRAWER
      // ========================================================
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      height: 72,
                      width: 72,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Administrator',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AdminService.adminEmail,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              _drawerItem(
                icon: Icons.dashboard_outlined,
                title: 'Dashboard',
                index: 0,
              ),

              _drawerItem(icon: Icons.people_outline, title: 'Users', index: 1),

              _drawerItem(
                icon: Icons.help_outline,
                title: 'Questions',
                index: 2,
              ),

              _drawerItem(
                icon: Icons.question_answer_outlined,
                title: 'Answers',
                index: 3,
              ),

              _drawerItem(
                icon: Icons.menu_book_outlined,
                title: 'Resources',
                index: 4,
              ),

              _drawerItem(
                icon: Icons.analytics_outlined,
                title: 'Analytics',
                index: 5,
              ),

              const Spacer(),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout'),
                onTap: _logout,
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildOverview(),
                _buildUsers(),
                _buildQuestions(),
                _buildAnswers(),
                _buildResources(),
                _buildAnalytics(),
              ],
            ),
    );
  }

  // ============================================================
  // DRAWER ITEM
  // ============================================================

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final selected = _selectedIndex == index;

    final theme = Theme.of(context);

    return ListTile(
      selected: selected,
      selectedTileColor: theme.colorScheme.primaryContainer.withValues(
        alpha: 0.45,
      ),
      leading: Icon(icon, color: selected ? theme.colorScheme.primary : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? theme.colorScheme.primary : null,
        ),
      ),
      onTap: () {
        _clearSearch();

        setState(() {
          _selectedIndex = index;
        });

        Navigator.pop(context);
      },
    );
  }
}
