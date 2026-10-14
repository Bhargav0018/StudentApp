import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/student_navigation.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AuthService _auth = AuthService.instance;

  final NotificationService _service = NotificationService.instance;

  List<Map<String, dynamic>> _notifications = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = _auth.currentUserId;

    if (userId == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final data = await _service.getNotifications(userId);

    if (!mounted) return;

    setState(() {
      _notifications = data;
      _loading = false;
    });
  }

  Future<void> _markRead(int id) async {
    await _service.markAsRead(id);

    await _loadNotifications();
  }

  Future<void> _markAllRead() async {
    final userId = _auth.currentUserId;

    if (userId == null) return;

    await _service.markAllAsRead(userId);

    await _loadNotifications();
  }

  Future<void> _clearAll() async {
    final userId = _auth.currentUserId;

    if (userId == null) return;

    await _service.clearAll(userId);

    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'read') {
                  _markAllRead();
                }

                if (value == 'clear') {
                  _clearAll();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'read', child: Text('Mark all as read')),
                PopupMenuItem(value: 'clear', child: Text('Clear all')),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 160),
                        Icon(
                          Icons.notifications_none,
                          size: 70,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 15),
                        Center(
                          child: Text(
                            'No notifications',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Your notifications will appear here.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final item = _notifications[index];

                        final bool isRead = item['is_read'] == 1;

                        final int id = (item['id'] as num).toInt();

                        return Card(
                          elevation: isRead ? 0 : 2,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isRead
                                  ? Colors.grey.shade200
                                  : const Color(0xFFDFF7F3),
                              child: Icon(
                                isRead
                                    ? Icons.notifications_none
                                    : Icons.notifications_active,
                                color: isRead
                                    ? Colors.grey
                                    : const Color(0xFF4F46E5),
                              ),
                            ),
                            title: Text(
                              item['title']?.toString() ?? 'Notification',
                              style: TextStyle(
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(item['message']?.toString() ?? ''),
                            ),
                            trailing: isRead
                                ? null
                                : const Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: Colors.red,
                                  ),
                            onTap: () => _markRead(id),
                          ),
                        );
                      },
                    ),
            ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
          ? StudentBottomNavigation(
              selectedIndex: 3,
              onSelected: (index) {
                if (index == 3) return;
                if (index == 0) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                } else {
                  Navigator.pushNamed(context, '/dashboard');
                }
              },
            )
          : null,
    );
  }
}
