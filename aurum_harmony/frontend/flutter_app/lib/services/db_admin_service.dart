import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'auth_service.dart';

class DbAdminService {
  static Future<Map<String, dynamic>> _get(String path) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final uri = Uri.parse('$kBackendBaseUrl$path');
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error'] ?? 'Failed to fetch data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final uri = Uri.parse('$kBackendBaseUrl$path');
      final response = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error'] ?? 'Failed to execute query');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<List<String>> getTables() async {
    final result = await _get('/api/admin/db/tables');
    if (result['success'] == true) {
      return List<String>.from(result['tables'] ?? []);
    }
    throw Exception(result['error'] ?? 'Failed to get tables');
  }

  static Future<Map<String, dynamic>> getTableData(String tableName, {int page = 1, int perPage = 50}) async {
    final result = await _get('/api/admin/db/tables/$tableName?page=$page&per_page=$perPage');
    if (result['success'] == true) {
      return result;
    }
    throw Exception(result['error'] ?? 'Failed to get table data');
  }

  static Future<List<Map<String, dynamic>>> getTableColumns(String tableName) async {
    final result = await _get('/api/admin/db/tables/$tableName/columns');
    if (result['success'] == true) {
      return List<Map<String, dynamic>>.from(result['columns'] ?? []);
    }
    throw Exception(result['error'] ?? 'Failed to get columns');
  }

  static Future<Map<String, dynamic>> executeQuery(String query) async {
    final result = await _post('/api/admin/db/query', {'query': query});
    if (result['success'] == true) {
      return result;
    }
    throw Exception(result['error'] ?? 'Query execution failed');
  }

  static Future<Map<String, dynamic>> getDatabaseStats() async {
    final result = await _get('/api/admin/db/stats');
    if (result['success'] == true) {
      return result['stats'] as Map<String, dynamic>;
    }
    throw Exception(result['error'] ?? 'Failed to get stats');
  }
}

