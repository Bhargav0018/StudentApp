import '../database/database_helper.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // ============================================================
  // CREATE NOTIFICATION
  // ============================================================

  Future<void> createNotification({
    required int userId,
    required String title,
    required String message,
  }) async {
    final settings = await _db.rawQuery(
      '''
      SELECT notifications_enabled
      FROM settings
      WHERE user_id = ?
      ''',
      [userId],
    );

    bool enabled = true;

    if (settings.isNotEmpty) {
      enabled = settings.first['notifications_enabled'] == 1;
    }

    if (!enabled) {
      return;
    }

    await _db.insert('notifications', {
      'user_id': userId,
      'title': title,
      'message': message,
      'is_read': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ============================================================
  // GET NOTIFICATIONS
  // ============================================================

  Future<List<Map<String, dynamic>>> getNotifications(int userId) async {
    return await _db.queryWhere('notifications', 'user_id = ?', [userId]);
  }

  // ============================================================
  // UNREAD COUNT
  // ============================================================

  Future<int> getUnreadCount(int userId) async {
    final result = await _db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM notifications
      WHERE user_id = ?
      AND is_read = 0
      ''',
      [userId],
    );

    return (result.first['count'] as num).toInt();
  }

  // ============================================================
  // MARK AS READ
  // ============================================================

  Future<void> markAsRead(int notificationId) async {
    await _db.update(
      'notifications',
      {'is_read': 1},
      'id = ?',
      [notificationId],
    );
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  Future<void> markAllAsRead(int userId) async {
    await _db.update('notifications', {'is_read': 1}, 'user_id = ?', [userId]);
  }

  // ============================================================
  // DELETE NOTIFICATION
  // ============================================================

  Future<void> deleteNotification(int notificationId) async {
    await _db.delete('notifications', 'id = ?', [notificationId]);
  }

  // ============================================================
  // CLEAR ALL
  // ============================================================

  Future<void> clearAll(int userId) async {
    await _db.delete('notifications', 'user_id = ?', [userId]);
  }
}
