import '../database/database_helper.dart';

class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // ============================================================
  // GET SETTINGS
  // ============================================================

  Future<Map<String, dynamic>> getSettings(int userId) async {
    final result = await _db.queryWhere('settings', 'user_id = ?', [userId]);

    if (result.isEmpty) {
      await _createDefaultSettings(userId);

      return {'user_id': userId, 'dark_mode': 0, 'notifications_enabled': 1};
    }

    return result.first;
  }

  // ============================================================
  // CREATE DEFAULT SETTINGS
  // ============================================================

  Future<void> _createDefaultSettings(int userId) async {
    await _db.insert('settings', {
      'user_id': userId,
      'dark_mode': 0,
      'notifications_enabled': 1,
    });
  }

  // ============================================================
  // DARK MODE
  // ============================================================

  Future<bool> isDarkMode(int userId) async {
    final settings = await getSettings(userId);

    return settings['dark_mode'] == 1;
  }

  Future<void> setDarkMode(int userId, bool enabled) async {
    await getSettings(userId);

    await _db.update(
      'settings',
      {'dark_mode': enabled ? 1 : 0},
      'user_id = ?',
      [userId],
    );
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Future<bool> areNotificationsEnabled(int userId) async {
    final settings = await getSettings(userId);

    return settings['notifications_enabled'] == 1;
  }

  Future<void> setNotificationsEnabled(int userId, bool enabled) async {
    await getSettings(userId);

    await _db.update(
      'settings',
      {'notifications_enabled': enabled ? 1 : 0},
      'user_id = ?',
      [userId],
    );
  }

  // ============================================================
  // RESET SETTINGS
  // ============================================================

  Future<void> resetSettings(int userId) async {
    await getSettings(userId);

    await _db.update(
      'settings',
      {'dark_mode': 0, 'notifications_enabled': 1},
      'user_id = ?',
      [userId],
    );
  }
}
