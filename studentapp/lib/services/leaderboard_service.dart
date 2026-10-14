import '../database/database_helper.dart';

class LeaderboardService {
  LeaderboardService._();

  static final LeaderboardService instance = LeaderboardService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // ============================================================
  // GET LEADERBOARD
  // ============================================================

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    return await _db.rawQuery('''
      SELECT
        id,
        name,
        email,
        course,
        college,
        points,
        created_at
      FROM users
      ORDER BY points DESC, name ASC
    ''');
  }

  // ============================================================
  // GET TOP USERS
  // ============================================================

  Future<List<Map<String, dynamic>>> getTopUsers(int limit) async {
    return await _db.rawQuery(
      '''
      SELECT
        id,
        name,
        email,
        course,
        college,
        points,
        created_at
      FROM users
      ORDER BY points DESC, name ASC
      LIMIT ?
      ''',
      [limit],
    );
  }

  // ============================================================
  // GET USER RANK
  // ============================================================

  Future<int> getUserRank(int userId) async {
    final userResult = await _db.queryWhere('users', 'id = ?', [userId]);

    if (userResult.isEmpty) {
      return 0;
    }

    final value = userResult.first['points'];

    int points = 0;

    if (value is int) {
      points = value;
    } else if (value is num) {
      points = value.toInt();
    }

    final result = await _db.rawQuery(
      '''
      SELECT COUNT(*) AS rank
      FROM users
      WHERE points > ?
      ''',
      [points],
    );

    final higherUsers = (result.first['rank'] as num).toInt();

    return higherUsers + 1;
  }
}
