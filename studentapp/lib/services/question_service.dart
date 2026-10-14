import '../database/database_helper.dart';
import 'auth_service.dart';

class QuestionService {
  QuestionService._();

  static final QuestionService instance = QuestionService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // ============================================================
  // ADD QUESTION
  // ============================================================

  Future<int> addQuestion({
    required int userId,
    required String title,
    required String description,
    required String category,
  }) async {
    final questionId = await _db.insert('questions', {
      'user_id': userId,
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Award contribution points for asking a question.
    await AuthService.instance.addPoints(userId, AuthService.questionPoints);

    return questionId;
  }

  // ============================================================
  // GET ALL QUESTIONS
  // ============================================================

  Future<List<Map<String, dynamic>>> getQuestions() async {
    return await _db.rawQuery('''
      SELECT
        questions.*,
        users.name AS user_name
      FROM questions
      LEFT JOIN users
        ON questions.user_id = users.id
      ORDER BY questions.id DESC
    ''');
  }

  // ============================================================
  // GET QUESTION
  // ============================================================

  Future<Map<String, dynamic>?> getQuestion(int questionId) async {
    final result = await _db.rawQuery(
      '''
      SELECT
        questions.*,
        users.name AS user_name
      FROM questions
      LEFT JOIN users
        ON questions.user_id = users.id
      WHERE questions.id = ?
      ''',
      [questionId],
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  // ============================================================
  // ADD ANSWER
  //
  // IMPORTANT:
  // When another student answers a question,
  // the question owner gets a notification.
  // ============================================================

  Future<int> addAnswer({
    required int questionId,
    required int userId,
    required String answer,
  }) async {
    // ----------------------------------------------------------
    // 1. Get question details
    // ----------------------------------------------------------

    final question = await getQuestion(questionId);

    if (question == null) {
      throw Exception('Question not found');
    }

    // ----------------------------------------------------------
    // 2. Insert answer
    // ----------------------------------------------------------

    final answerId = await _db.insert('answers', {
      'question_id': questionId,
      'user_id': userId,
      'answer': answer.trim(),
      'is_helpful': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Award contribution points for answering.
    await AuthService.instance.addPoints(userId, AuthService.answerPoints);

    // ----------------------------------------------------------
    // 3. Get question owner
    // ----------------------------------------------------------

    final questionOwnerId = (question['user_id'] as num).toInt();

    // ----------------------------------------------------------
    // 4. Don't notify if user answered their own question
    // ----------------------------------------------------------

    if (questionOwnerId != userId) {
      // --------------------------------------------------------
      // 5. Check notification setting
      // --------------------------------------------------------

      bool notificationsEnabled = true;

      try {
        final setting = await _db.rawQuery(
          '''
          SELECT notifications_enabled
          FROM settings
          WHERE user_id = ?
          ''',
          [questionOwnerId],
        );

        if (setting.isNotEmpty) {
          final value = setting.first['notifications_enabled'];

          if (value is int) {
            notificationsEnabled = value == 1;
          } else if (value is bool) {
            notificationsEnabled = value;
          }
        }
      } catch (_) {
        // If settings table is unavailable,
        // notifications remain enabled by default.
        notificationsEnabled = true;
      }

      // --------------------------------------------------------
      // 6. Create notification
      // --------------------------------------------------------

      if (notificationsEnabled) {
        String answererName = 'A student';

        try {
          final answerer = await _db.rawQuery(
            '''
            SELECT name
            FROM users
            WHERE id = ?
            ''',
            [userId],
          );

          if (answerer.isNotEmpty) {
            answererName = answerer.first['name']?.toString() ?? 'A student';
          }
        } catch (_) {
          answererName = 'A student';
        }

        await _db.insert('notifications', {
          'user_id': questionOwnerId,
          'title': 'New Answer',
          'message':
              '$answererName answered your question: "${question['title']}"',
          'is_read': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }

    return answerId;
  }

  // ============================================================
  // GET ANSWERS
  // ============================================================

  Future<List<Map<String, dynamic>>> getAnswers(int questionId) async {
    return await _db.rawQuery(
      '''
      SELECT
        answers.*,
        users.name AS user_name
      FROM answers
      LEFT JOIN users
        ON answers.user_id = users.id
      WHERE answers.question_id = ?
      ORDER BY answers.id DESC
      ''',
      [questionId],
    );
  }

  // ============================================================
  // MARK ANSWER HELPFUL
  // ============================================================

  Future<void> toggleAnswerHelpful(int answerId) async {
    final result = await _db.queryWhere('answers', 'id = ?', [answerId]);

    if (result.isEmpty) {
      return;
    }

    final currentValue = result.first['is_helpful'];

    final currentHelpful = currentValue is int ? currentValue == 1 : false;

    await _db.update(
      'answers',
      {'is_helpful': currentHelpful ? 0 : 1},
      'id = ?',
      [answerId],
    );
  }
  // ============================================================
  // SEARCH QUESTIONS
  // ============================================================

  Future<List<Map<String, dynamic>>> searchQuestions(String query) async {
    return await _db.rawQuery(
      '''
      SELECT
        questions.*,
        users.name AS user_name
      FROM questions
      LEFT JOIN users
        ON questions.user_id = users.id
      WHERE
        questions.title LIKE ?
        OR questions.description LIKE ?
        OR questions.category LIKE ?
      ORDER BY questions.id DESC
      ''',
      ['%$query%', '%$query%', '%$query%'],
    );
  }

  // ============================================================
  // QUESTIONS BY CATEGORY
  // ============================================================

  Future<List<Map<String, dynamic>>> getQuestionsByCategory(
    String category,
  ) async {
    return await _db.rawQuery(
      '''
      SELECT
        questions.*,
        users.name AS user_name
      FROM questions
      LEFT JOIN users
        ON questions.user_id = users.id
      WHERE questions.category = ?
      ORDER BY questions.id DESC
      ''',
      [category],
    );
  }

  // ============================================================
  // SAVE QUESTION
  // ============================================================

  Future<void> saveQuestion({
    required int userId,
    required int questionId,
  }) async {
    try {
      await _db.insert('saved_questions', {
        'user_id': userId,
        'question_id': questionId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Question already saved.
    }
  }

  // ============================================================
  // UNSAVE QUESTION
  // ============================================================

  Future<void> unsaveQuestion({
    required int userId,
    required int questionId,
  }) async {
    await _db.delete('saved_questions', 'user_id = ? AND question_id = ?', [
      userId,
      questionId,
    ]);
  }

  // ============================================================
  // CHECK WHETHER QUESTION IS SAVED
  // ============================================================

  Future<bool> isQuestionSaved({
    required int userId,
    required int questionId,
  }) async {
    final result = await _db.queryWhere(
      'saved_questions',
      'user_id = ? AND question_id = ?',
      [userId, questionId],
    );

    return result.isNotEmpty;
  }

  // ============================================================
  // GET SAVED QUESTIONS
  // ============================================================

  Future<List<Map<String, dynamic>>> getSavedQuestions(int userId) async {
    return await _db.rawQuery(
      '''
      SELECT
        questions.*,
        users.name AS user_name
      FROM saved_questions
      INNER JOIN questions
        ON saved_questions.question_id = questions.id
      LEFT JOIN users
        ON questions.user_id = users.id
      WHERE saved_questions.user_id = ?
      ORDER BY saved_questions.id DESC
      ''',
      [userId],
    );
  }

  // ============================================================
  // USER QUESTION COUNT
  // ============================================================

  Future<int> getUserQuestionCount(int userId) async {
    final result = await _db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM questions
      WHERE user_id = ?
      ''',
      [userId],
    );

    return (result.first['count'] as num).toInt();
  }

  // ============================================================
  // USER ANSWER COUNT
  // ============================================================

  Future<int> getUserAnswerCount(int userId) async {
    final result = await _db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM answers
      WHERE user_id = ?
      ''',
      [userId],
    );

    return (result.first['count'] as num).toInt();
  }

  // ============================================================
  // TOTAL QUESTIONS COUNT
  // ============================================================

  Future<int> getTotalQuestionCount() async {
    final result = await _db.rawQuery('''
      SELECT COUNT(*) AS count
      FROM questions
      ''');

    return (result.first['count'] as num).toInt();
  }

  // ============================================================
  // TOTAL ANSWERS COUNT
  // ============================================================

  Future<int> getTotalAnswerCount() async {
    final result = await _db.rawQuery('''
      SELECT COUNT(*) AS count
      FROM answers
      ''');

    return (result.first['count'] as num).toInt();
  }
}
