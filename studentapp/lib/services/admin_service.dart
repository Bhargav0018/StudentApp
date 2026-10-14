import '../database/database_helper.dart';

class AdminService {
  AdminService._();

  static final AdminService instance = AdminService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // ============================================================
  // ADMIN CREDENTIALS
  // ============================================================

  static const String adminEmail = 'admin@studenthelp.com';
  static const String adminPassword = 'Admin@123';

  // ============================================================
  // LOGIN
  // ============================================================

  bool login({required String email, required String password}) {
    return email.trim().toLowerCase() == adminEmail &&
        password == adminPassword;
  }

  // ============================================================
  // DASHBOARD COUNTS
  // ============================================================

  Future<int> getUserCount() async {
    final result = await _db.rawQuery('SELECT COUNT(*) AS count FROM users');

    return (result.first['count'] as num).toInt();
  }

  Future<int> getQuestionCount() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) AS count FROM questions',
    );

    return (result.first['count'] as num).toInt();
  }

  Future<int> getAnswerCount() async {
    final result = await _db.rawQuery('SELECT COUNT(*) AS count FROM answers');

    return (result.first['count'] as num).toInt();
  }

  Future<int> getResourceCount() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) AS count FROM resources',
    );

    return (result.first['count'] as num).toInt();
  }

  // ============================================================
  // GET ALL USERS
  // ============================================================

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return await _db.rawQuery('''
      SELECT
        id,
        name,
        email,
        course,
        college,
        created_at
      FROM users
      ORDER BY id DESC
    ''');
  }

  // ============================================================
  // GET ALL QUESTIONS
  // ============================================================

  Future<List<Map<String, dynamic>>> getAllQuestions() async {
    return await _db.rawQuery('''
      SELECT
        questions.*,
        users.name AS user_name,
        users.email AS user_email
      FROM questions
      LEFT JOIN users
        ON questions.user_id = users.id
      ORDER BY questions.id DESC
    ''');
  }

  // ============================================================
  // GET ALL ANSWERS
  // ============================================================

  Future<List<Map<String, dynamic>>> getAllAnswers() async {
    return await _db.rawQuery('''
      SELECT
        answers.*,
        users.name AS user_name,
        users.email AS user_email,
        questions.title AS question_title
      FROM answers
      LEFT JOIN users
        ON answers.user_id = users.id
      LEFT JOIN questions
        ON answers.question_id = questions.id
      ORDER BY answers.id DESC
    ''');
  }

  // ============================================================
  // GET ALL RESOURCES
  // ============================================================

  Future<List<Map<String, dynamic>>> getAllResources() async {
    return await _db.rawQuery('''
      SELECT
        resources.*,
        users.name AS user_name,
        users.email AS user_email
      FROM resources
      LEFT JOIN users
        ON resources.user_id = users.id
      ORDER BY resources.id DESC
    ''');
  }

  // ============================================================
  // DELETE QUESTION
  // ============================================================

  Future<void> deleteQuestion(int questionId) async {
    // Remove answers belonging to this question.
    await _db.delete('answers', 'question_id = ?', [questionId]);

    // Remove saved-question records.
    await _db.delete('saved_questions', 'question_id = ?', [questionId]);

    // Remove the question itself.
    await _db.delete('questions', 'id = ?', [questionId]);
  }

  // ============================================================
  // DELETE ANSWER
  // ============================================================

  Future<void> deleteAnswer(int answerId) async {
    await _db.delete('answers', 'id = ?', [answerId]);
  }

  // ============================================================
  // DELETE RESOURCE
  // ============================================================

  Future<void> deleteResource(int resourceId) async {
    // Remove saved-resource records first.
    await _db.delete('saved_resources', 'resource_id = ?', [resourceId]);

    // Delete resource.
    await _db.delete('resources', 'id = ?', [resourceId]);
  }

  // ============================================================
  // DELETE USER
  // ============================================================
  //
  // Removes user-related data before deleting the user.
  //
  // This keeps SQLite data clean because the current schema
  // does not use foreign-key cascade rules.
  //
  // ============================================================

  Future<void> deleteUser(int userId) async {
    // Get questions created by the user.
    final questions = await _db.queryWhere('questions', 'user_id = ?', [
      userId,
    ]);

    // Remove answers and saved-question records
    // related to each question created by this user.
    for (final question in questions) {
      final questionId = (question['id'] as num).toInt();

      await _db.delete('answers', 'question_id = ?', [questionId]);

      await _db.delete('saved_questions', 'question_id = ?', [questionId]);
    }

    // Delete questions created by the user.
    await _db.delete('questions', 'user_id = ?', [userId]);

    // Delete answers written by the user.
    await _db.delete('answers', 'user_id = ?', [userId]);

    // Get resources created by the user.
    final resources = await _db.queryWhere('resources', 'user_id = ?', [
      userId,
    ]);

    // Remove saved-resource records for those resources.
    for (final resource in resources) {
      final resourceId = (resource['id'] as num).toInt();

      await _db.delete('saved_resources', 'resource_id = ?', [resourceId]);
    }

    // Delete resources created by the user.
    await _db.delete('resources', 'user_id = ?', [userId]);

    // Remove saved questions created/saved by this user.
    await _db.delete('saved_questions', 'user_id = ?', [userId]);

    // Remove saved resources created/saved by this user.
    await _db.delete('saved_resources', 'user_id = ?', [userId]);

    // Remove notifications belonging to the user.
    await _db.delete('notifications', 'user_id = ?', [userId]);

    // Remove user settings.
    await _db.delete('settings', 'user_id = ?', [userId]);

    // Finally delete the user.
    await _db.delete('users', 'id = ?', [userId]);
  }
}
