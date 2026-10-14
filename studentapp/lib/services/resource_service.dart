import 'dart:typed_data';

import '../database/database_helper.dart';
import 'auth_service.dart';

class ResourceService {
  ResourceService._();

  static final ResourceService instance = ResourceService._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final AuthService _authService = AuthService.instance;

  // ============================================================
  // ADD RESOURCE
  // ============================================================

  Future<int> addResource({
    required int userId,
    required String title,
    required String description,
    required String category,
    String url = '',
    String resourceType = 'link',
    String? fileName,
    String? mimeType,
    Uint8List? fileBytes,
  }) async {
    final resourceId = await _db.insert('resources', {
      'user_id': userId,
      'title': title.trim(),
      'description': description.trim(),
      'resource_url': url.trim().isEmpty ? null : url.trim(),
      'category': category,
      'resource_type': resourceType,
      'file_name': fileName,
      'mime_type': mimeType,
      'file_data': fileBytes,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Reputation points
    await _authService.addPoints(userId, AuthService.resourcePoints);

    return resourceId;
  }

  // ============================================================
  // GET ALL RESOURCES
  // ============================================================

  Future<List<Map<String, dynamic>>> getResources() async {
    return await _db.rawQuery('''
      SELECT
        resources.id,
        resources.user_id,
        resources.title,
        resources.description,
        resources.resource_url,
        resources.category,
        resources.resource_type,
        resources.file_name,
        resources.mime_type,
        resources.file_data,
        resources.created_at,
        users.name AS user_name
      FROM resources
      LEFT JOIN users
        ON resources.user_id = users.id
      ORDER BY resources.id DESC
    ''');
  }

  // ============================================================
  // SEARCH RESOURCES
  // ============================================================

  Future<List<Map<String, dynamic>>> searchResources(String query) async {
    return await _db.rawQuery(
      '''
      SELECT
        resources.id,
        resources.user_id,
        resources.title,
        resources.description,
        resources.resource_url,
        resources.category,
        resources.resource_type,
        resources.file_name,
        resources.mime_type,
        resources.file_data,
        resources.created_at,
        users.name AS user_name
      FROM resources
      LEFT JOIN users
        ON resources.user_id = users.id
      WHERE
        resources.title LIKE ?
        OR resources.description LIKE ?
        OR resources.category LIKE ?
        OR resources.file_name LIKE ?
      ORDER BY resources.id DESC
      ''',
      ['%$query%', '%$query%', '%$query%', '%$query%'],
    );
  }

  // ============================================================
  // SAVE RESOURCE
  // ============================================================

  Future<void> saveResource({
    required int userId,
    required int resourceId,
  }) async {
    try {
      await _db.insert('saved_resources', {
        'user_id': userId,
        'resource_id': resourceId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Already saved
    }
  }

  // ============================================================
  // UNSAVE RESOURCE
  // ============================================================

  Future<void> unsaveResource({
    required int userId,
    required int resourceId,
  }) async {
    await _db.delete('saved_resources', 'user_id = ? AND resource_id = ?', [
      userId,
      resourceId,
    ]);
  }

  // ============================================================
  // CHECK SAVED
  // ============================================================

  Future<bool> isResourceSaved({
    required int userId,
    required int resourceId,
  }) async {
    final result = await _db.queryWhere(
      'saved_resources',
      'user_id = ? AND resource_id = ?',
      [userId, resourceId],
    );

    return result.isNotEmpty;
  }

  // ============================================================
  // GET SAVED RESOURCES
  // ============================================================

  Future<List<Map<String, dynamic>>> getSavedResources(int userId) async {
    return await _db.rawQuery(
      '''
      SELECT
        resources.*,
        users.name AS user_name,
        saved_resources.created_at AS saved_at
      FROM saved_resources
      INNER JOIN resources
        ON saved_resources.resource_id = resources.id
      LEFT JOIN users
        ON resources.user_id = users.id
      WHERE saved_resources.user_id = ?
      ORDER BY saved_resources.id DESC
      ''',
      [userId],
    );
  }

  // ============================================================
  // SAVED RESOURCE COUNT
  // ============================================================

  Future<int> getSavedResourceCount(int userId) async {
    final result = await _db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM saved_resources
      WHERE user_id = ?
      ''',
      [userId],
    );

    return (result.first['count'] as num).toInt();
  }

  // ============================================================
  // RESOURCE COUNT
  // ============================================================

  Future<int> getUserResourceCount(int userId) async {
    final result = await _db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM resources
      WHERE user_id = ?
      ''',
      [userId],
    );

    return (result.first['count'] as num).toInt();
  }
}
