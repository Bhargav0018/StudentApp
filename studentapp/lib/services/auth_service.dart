import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // =====================================================
  // CURRENT USER
  // =====================================================

  static Map<String, dynamic>? currentUser;

  // =====================================================
  // REPUTATION POINTS
  // =====================================================

  static const int questionPoints = 2;
  static const int answerPoints = 5;
  static const int resourcePoints = 4;
  static const int helpfulAnswerPoints = 3;

  // =====================================================
  // REGISTER
  // =====================================================

  Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
    required String course,
    required String college,
  }) async {
    try {
      final cleanEmail = email.trim().toLowerCase();

      final existingUser = await _db.queryWhere('users', 'email = ?', [
        cleanEmail,
      ]);

      if (existingUser.isNotEmpty) {
        return false;
      }

      await _db.insert('users', {
        'name': name.trim(),
        'email': cleanEmail,
        'password': password,
        'course': course.trim(),
        'college': college.trim(),
        'points': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Registration Error: $e');
      return false;
    }
  }

  // =====================================================
  // LOGIN
  // =====================================================

  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final cleanEmail = email.trim().toLowerCase();

      final users = await _db.queryWhere(
        'users',
        'email = ? AND password = ?',
        [cleanEmail, password],
      );

      if (users.isEmpty) {
        return false;
      }

      currentUser = Map<String, dynamic>.from(users.first);

      return true;
    } catch (e) {
      debugPrint('Login Error: $e');
      return false;
    }
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  void logout() {
    currentUser = null;
  }

  // =====================================================
  // LOGIN STATUS
  // =====================================================

  bool get isLoggedIn {
    return currentUser != null;
  }

  // =====================================================
  // USER ID
  // =====================================================

  int? get currentUserId {
    final value = currentUser?['id'];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return null;
  }

  // =====================================================
  // USER NAME
  // =====================================================

  String get currentUserName {
    return currentUser?['name']?.toString() ?? 'Student';
  }

  // =====================================================
  // USER EMAIL
  // =====================================================

  String get currentUserEmail {
    return currentUser?['email']?.toString() ?? '';
  }

  // =====================================================
  // USER COURSE
  // =====================================================

  String get currentUserCourse {
    return currentUser?['course']?.toString() ?? '';
  }

  // =====================================================
  // USER COLLEGE
  // =====================================================

  String get currentUserCollege {
    return currentUser?['college']?.toString() ?? '';
  }

  // =====================================================
  // GET CURRENT USER POINTS
  // =====================================================

  int get currentUserPoints {
    final value = currentUser?['points'];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  // =====================================================
  // GET USER POINTS
  // =====================================================

  Future<int> getUserPoints(int userId) async {
    try {
      final result = await _db.queryWhere('users', 'id = ?', [userId]);

      if (result.isEmpty) {
        return 0;
      }

      final value = result.first['points'];

      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }

      return 0;
    } catch (e) {
      debugPrint('Get User Points Error: $e');
      return 0;
    }
  }

  // =====================================================
  // ADD POINTS
  // =====================================================

  Future<bool> addPoints(int userId, int points) async {
    try {
      if (points <= 0) {
        return false;
      }

      final currentPoints = await getUserPoints(userId);

      final newPoints = currentPoints + points;

      await _db.update('users', {'points': newPoints}, 'id = ?', [userId]);

      // Update currently logged-in user's local data.
      if (currentUserId == userId && currentUser != null) {
        currentUser = {...currentUser!, 'points': newPoints};
      }

      return true;
    } catch (e) {
      debugPrint('Add Points Error: $e');
      return false;
    }
  }

  // =====================================================
  // REMOVE POINTS
  // =====================================================

  Future<bool> removePoints(int userId, int points) async {
    try {
      if (points <= 0) {
        return false;
      }

      final currentPoints = await getUserPoints(userId);

      final newPoints = currentPoints - points;

      // Points should never become negative.
      final finalPoints = newPoints < 0 ? 0 : newPoints;

      await _db.update('users', {'points': finalPoints}, 'id = ?', [userId]);

      if (currentUserId == userId && currentUser != null) {
        currentUser = {...currentUser!, 'points': finalPoints};
      }

      return true;
    } catch (e) {
      debugPrint('Remove Points Error: $e');
      return false;
    }
  }

  // =====================================================
  // REFRESH CURRENT USER
  // =====================================================

  Future<void> refreshCurrentUser() async {
    final userId = currentUserId;

    if (userId == null) {
      return;
    }

    try {
      final users = await _db.queryWhere('users', 'id = ?', [userId]);

      if (users.isNotEmpty) {
        currentUser = Map<String, dynamic>.from(users.first);
      }
    } catch (e) {
      debugPrint('Refresh Current User Error: $e');
    }
  }

  // =====================================================
  // UPDATE PROFILE
  // =====================================================

  Future<void> updateProfile({
    required int userId,
    required String name,
    required String course,
    required String college,
  }) async {
    await _db.update(
      'users',
      {'name': name.trim(), 'course': course.trim(), 'college': college.trim()},
      'id = ?',
      [userId],
    );

    if (currentUser != null) {
      currentUser = {
        ...currentUser!,
        'name': name.trim(),
        'course': course.trim(),
        'college': college.trim(),
      };
    }
  }
}
