import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class NotificationsService {
  final String baseUrl = 'http://localhost:5000/api';

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final notifications = data['notifications'] as List? ?? [];

        // Convert to our expected format
        return notifications.map((n) => {
          'id': n['id']?.toString() ?? '',
          'title': n['title'] ?? 'Notification',
          'message': n['message'] ?? '',
          'timestamp': DateTime.tryParse(n['timestamp'] ?? '') ?? DateTime.now(),
          'read': n['read'] ?? false,
          'type': n['type'] ?? 'general',
          'priority': n['priority'] ?? 'normal',
        }).toList();
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      // Return empty list - UI will show mock data
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      // Don't throw - allow offline functionality
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/mark-all-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark all notifications as read');
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      // Don't throw - allow offline functionality
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final notifications = await getNotifications();
      return notifications.where((n) => !(n['read'] ?? false)).length;
    } catch (e) {
      return 0;
    }
  }
}
