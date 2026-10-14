import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final LeaderboardService _leaderboardService = LeaderboardService.instance;

  final AuthService _auth = AuthService.instance;

  List<Map<String, dynamic>> _users = [];

  bool _isLoading = true;
  int _currentUserRank = 0;
  int _currentUserPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  // ============================================================
  // LOAD LEADERBOARD
  // ============================================================

  Future<void> _loadLeaderboard() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.refreshCurrentUser();

      final users = await _leaderboardService.getLeaderboard();

      int rank = 0;
      int points = 0;

      final currentUserId = _auth.currentUserId;

      if (currentUserId != null) {
        rank = await _leaderboardService.getUserRank(currentUserId);
        points = await _auth.getUserPoints(currentUserId);
      }

      if (!mounted) return;

      setState(() {
        _users = users;
        _currentUserRank = rank;
        _currentUserPoints = points;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Leaderboard Error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to load leaderboard.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // ============================================================
  // SAFE INTEGER
  // ============================================================

  int _safeInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // ============================================================
  // USER NAME
  // ============================================================

  String _getUserName(Map<String, dynamic> user) {
    final name = user['name']?.toString().trim();

    if (name == null || name.isEmpty) {
      return 'Unknown User';
    }

    return name;
  }

  // ============================================================
  // USER INITIAL
  // ============================================================

  String _getInitial(String name) {
    if (name.trim().isEmpty) {
      return 'U';
    }

    return name.trim().substring(0, 1).toUpperCase();
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
  // REPUTATION ICON
  // ============================================================

  IconData _getReputationIcon(int points) {
    if (points >= 100) {
      return Icons.workspace_premium;
    }

    if (points >= 50) {
      return Icons.verified;
    }

    if (points >= 20) {
      return Icons.school;
    }

    return Icons.person_outline;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,

        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Leaderboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadLeaderboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLeaderboard,

              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // PAGE TITLE
                    // ==================================================

                    _buildPageHeader(),

                    const SizedBox(height: 24),

                    // ==================================================
                    // YOUR RANKING
                    // ==================================================
                    _buildYourRankingCard(),

                    const SizedBox(height: 38),

                    // ==================================================
                    // TOP CONTRIBUTORS
                    // ==================================================
                    _buildSectionTitle(
                      'Top Contributors',
                      Icons.emoji_events_outlined,
                    ),

                    const SizedBox(height: 16),

                    _buildTopContributors(),

                    const SizedBox(height: 38),

                    // ==================================================
                    // ALL RANKINGS
                    // ==================================================
                    _buildSectionTitle(
                      'All Rankings',
                      Icons.leaderboard_outlined,
                    ),

                    const SizedBox(height: 16),

                    _buildAllRankings(),

                    const SizedBox(height: 28),

                    // ==================================================
                    // POINT RULES
                    // ==================================================
                    _buildPointRules(),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community Leaderboard 🏆',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'See who is making the biggest contribution '
          'to the student community.',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // YOUR RANKING CARD
  // ============================================================

  Widget _buildYourRankingCard() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFFF97316)],
        ),

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Trophy
          Container(
            width: 62,
            height: 62,

            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),

            child: const Icon(
              Icons.emoji_events,
              size: 34,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 16),

          // Rank
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Ranking',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),

                const SizedBox(height: 5),

                Text(
                  _currentUserRank > 0 ? '#$_currentUserRank' : '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_currentUserPoints',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 2),

              const Text(
                'points',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP CONTRIBUTORS
  // ============================================================

  Widget _buildTopContributors() {
    if (_users.isEmpty) {
      return _buildEmptyCard('No contributors yet.', Icons.people_outline);
    }

    final topUsers = _users.take(3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 650;

        if (isSmall) {
          return Column(
            children: List.generate(topUsers.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == topUsers.length - 1 ? 0 : 14,
                ),
                child: _buildTopContributorCard(topUsers[index], index),
              );
            }),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(topUsers.length, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == topUsers.length - 1 ? 0 : 12,
                ),
                child: _buildTopContributorCard(topUsers[index], index),
              ),
            );
          }),
        );
      },
    );
  }

  // ============================================================
  // TOP CONTRIBUTOR CARD
  // ============================================================

  Widget _buildTopContributorCard(Map<String, dynamic> user, int index) {
    final theme = Theme.of(context);

    final name = _getUserName(user);
    final points = _safeInt(user['points']);

    final isCurrentUser = _safeInt(user['id']) == _auth.currentUserId;

    final trophyColor = index == 0
        ? const Color(0xFFFFC107)
        : index == 1
        ? const Color(0xFF9E9E9E)
        : const Color(0xFFCD7F32);

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: theme.cardColor,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(
          color: isCurrentUser ? theme.colorScheme.primary : theme.dividerColor,
          width: isCurrentUser ? 2 : 1,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.10 : 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: 36, color: trophyColor),

          const SizedBox(height: 14),

          CircleAvatar(
            radius: 38,

            backgroundColor: theme.colorScheme.primaryContainer,

            child: Text(
              _getInitial(name),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 4),

          if (isCurrentUser)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Text(
                'You',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            )
          else
            Text(
              _getReputationLevel(points),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, size: 20, color: theme.colorScheme.primary),

              const SizedBox(width: 6),

              Text(
                '$points pts',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ALL RANKINGS
  // ============================================================

  Widget _buildAllRankings() {
    if (_users.isEmpty) {
      return _buildEmptyCard(
        'No rankings available yet.',
        Icons.leaderboard_outlined,
      );
    }

    return Column(
      children: List.generate(_users.length, (index) {
        final user = _users[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRankingCard(user, index + 1),
        );
      }),
    );
  }

  // ============================================================
  // RANKING CARD
  // ============================================================

  Widget _buildRankingCard(Map<String, dynamic> user, int rank) {
    final theme = Theme.of(context);

    final name = _getUserName(user);
    final points = _safeInt(user['points']);

    final userId = _safeInt(user['id']);

    final isCurrentUser = userId == _auth.currentUserId;

    final course = user['course']?.toString().trim() ?? '';

    final reputation = _getReputationLevel(points);

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

      decoration: BoxDecoration(
        color: isCurrentUser
            ? theme.colorScheme.primaryContainer.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.35 : 0.45,
              )
            : theme.cardColor,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: isCurrentUser ? theme.colorScheme.primary : theme.dividerColor,
          width: isCurrentUser ? 1.8 : 1,
        ),
      ),

      // ========================================================
      // IMPORTANT:
      //
      // NO FIXED HEIGHT
      // NO OVERFLOW
      //
      // The content can grow naturally.
      // ========================================================
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ======================================================
          // RANK
          // ======================================================

          SizedBox(width: 40, child: _buildRankIcon(rank)),

          const SizedBox(width: 8),

          // ======================================================
          // AVATAR
          // ======================================================
          CircleAvatar(
            radius: 23,

            backgroundColor: theme.colorScheme.primaryContainer,

            child: Text(
              _getInitial(name),
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ======================================================
          // USER DETAILS
          // ======================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ----------------------------------------------
                // NAME + YOU
                // ----------------------------------------------

                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),

                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),

                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 4),

                // ----------------------------------------------
                // COURSE
                // ----------------------------------------------
                if (course.isNotEmpty)
                  Text(
                    course,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                const SizedBox(height: 4),

                // ----------------------------------------------
                // REPUTATION
                // ----------------------------------------------
                Row(
                  children: [
                    Icon(
                      _getReputationIcon(points),
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),

                    const SizedBox(width: 5),

                    Flexible(
                      child: Text(
                        reputation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ======================================================
          // POINTS
          // ======================================================
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.star, size: 20, color: theme.colorScheme.primary),

              const SizedBox(height: 2),

              Text(
                '$points',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),

              Text(
                'pts',
                style: TextStyle(
                  fontSize: 9,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RANK ICON
  // ============================================================

  Widget _buildRankIcon(int rank) {
    final theme = Theme.of(context);

    if (rank == 1) {
      return const Icon(Icons.emoji_events, size: 28, color: Color(0xFFFFB300));
    }

    if (rank == 2) {
      return const Icon(Icons.emoji_events, size: 27, color: Color(0xFF9E9E9E));
    }

    if (rank == 3) {
      return const Icon(Icons.emoji_events, size: 27, color: Color(0xFFCD7F32));
    }

    return Text(
      '#$rank',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  // ============================================================
  // POINT RULES
  // ============================================================

  Widget _buildPointRules() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.28 : 0.45,
        ),

        borderRadius: BorderRadius.circular(22),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // TITLE
          // ======================================================

          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 24,
                color: theme.colorScheme.primary,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  'How to earn points',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildPointRow('Ask a question', '+2 points'),

          const SizedBox(height: 10),

          _buildPointRow('Answer a question', '+5 points'),

          const SizedBox(height: 10),

          _buildPointRow('Share a resource', '+4 points'),

          const SizedBox(height: 10),

          _buildPointRow('Helpful answer', '+3 points'),
        ],
      ),
    );
  }

  // ============================================================
  // POINT ROW
  // ============================================================

  Widget _buildPointRow(String title, String points) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•',
          style: TextStyle(
            fontSize: 17,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Text(
          points,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY CARD
  // ============================================================

  Widget _buildEmptyCard(String message, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),

      child: Column(
        children: [
          Icon(icon, size: 42, color: theme.colorScheme.primary),

          const SizedBox(height: 10),

          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
