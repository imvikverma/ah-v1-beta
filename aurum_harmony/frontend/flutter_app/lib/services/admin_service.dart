import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AdminService {
  final String baseUrl = 'http://localhost:5000/api';

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final users = data['users'] as List? ?? [];

        // Convert to our expected format
        return users.map((u) => {
          'id': u['id']?.toString() ?? '',
          'email': u['email'] ?? '',
          'phone': u['phone'] ?? '',
          'user_code': u['user_code'] ?? '',
          'user_type': u['user_type'] ?? 'existing',
          'is_admin': u['is_admin'] ?? false,
          'is_active': u['is_active'] ?? true,
          'internal_capital': (u['internal_capital'] as num?)?.toDouble() ?? 0.0,
          'accumulated_profit': (u['accumulated_profit'] as num?)?.toDouble() ?? 0.0,
          'created_at': DateTime.tryParse(u['created_at'] ?? '') ?? DateTime.now(),
          'last_login': u['last_login'] != null ? DateTime.tryParse(u['last_login']) : null,
        }).toList();
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Admin privileges required.');
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      print('Error fetching users: $e');
      // Return empty list - UI will show mock data
      return [];
    }
  }

  Future<void> toggleUserStatus(String userId, bool activate) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/users/$userId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'active': activate,
        }),
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 403) {
          throw Exception('Access denied. Admin privileges required.');
        }
        throw Exception('Failed to update user status');
      }
    } catch (e) {
      print('Error updating user status: $e');
      rethrow;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updates),
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 403) {
          throw Exception('Access denied. Admin privileges required.');
        }
        throw Exception('Failed to update user');
      }
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Admin privileges required.');
      } else {
        throw Exception('Failed to load system stats');
      }
    } catch (e) {
      print('Error fetching system stats: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getAdminReports() async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/reports'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['reports'] as List?)?.map((r) => r as Map<String, dynamic>).toList() ?? [];
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Admin privileges required.');
        return [];
      } else {
        throw Exception('Failed to load admin reports');
        return [];
      }
    } catch (e) {
      print('Error fetching admin reports: $e');
      return [];
    }
  }
}
