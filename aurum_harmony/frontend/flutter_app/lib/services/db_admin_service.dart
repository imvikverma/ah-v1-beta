import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'auth_service.dart';

class DbAdminService {
  /// Try fallback to localhost backend (only works when already on localhost)
  static Future<Map<String, dynamic>> _tryFallback(String path, Map<String, String> headers, String method) async {
    // Only try fallback if we're already on localhost (can't access localhost from production)
    final hostname = html.window.location.hostname ?? '';
    if (hostname.contains('localhost') || hostname.contains('127.0.0.1')) {
      // Try localhost backend as fallback
      try {
        final fallbackUri = Uri.parse('$kBackendBaseUrlFallback$path');
        final response = method == 'GET'
            ? await http.get(fallbackUri, headers: headers).timeout(const Duration(seconds: 5))
            : await http.post(fallbackUri, headers: headers, body: headers['body'] ?? '').timeout(const Duration(seconds: 5));
        
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } else if (response.statusCode == 401) {
          await AuthService.logout();
          throw Exception('Session expired. Please refresh the page and login again.');
        } else {
          final error = jsonDecode(response.body) as Map<String, dynamic>;
          throw Exception(error['error'] ?? 'Failed to fetch data');
        }
      } catch (e) {
        throw Exception('API service unavailable. Please ensure the backend is running on localhost:5000.');
      }
    }
    // On production, Worker must be deployed
    throw Exception('Worker API is not accessible. Please deploy the Worker using: .\\scripts\\deploy_worker.ps1');
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final token = await AuthService.getValidToken();
    if (token == null) {
      // Token expired or invalid - ensure logout and throw clear error
      await AuthService.logout();
      throw Exception('Session expired. Please refresh the page and login again.');
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
      } else if (response.statusCode == 401) {
        // Token expired - clear it and throw error
        await AuthService.logout();
        throw Exception('Session expired. Please refresh the page and login again.');
      } else if (response.statusCode == 503 || response.statusCode == 525 || response.statusCode == 502) {
        // Server errors - Worker might be down or misconfigured
        // Try fallback to localhost backend
        return await _tryFallback(path, headers, 'GET');
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error'] ?? 'Failed to fetch data');
      }
    } catch (e) {
      // If it's already our custom exception, re-throw it
      if (e.toString().contains('Session expired')) {
        rethrow;
      }
      
      // Check if it's a network error - try fallback to localhost
      final errorStr = e.toString().toLowerCase();
      final isNetworkError = errorStr.contains('networkerror') ||
                            errorStr.contains('network error') ||
                            errorStr.contains('failed host lookup') ||
                            errorStr.contains('socketexception') ||
                            errorStr.contains('connection') ||
                            errorStr.contains('525') ||
                            errorStr.contains('502') ||
                            errorStr.contains('503');
      
      if (isNetworkError) {
        // Try fallback to localhost backend
        try {
          return await _tryFallback(path, headers, 'GET');
        } catch (fallbackError) {
          throw Exception('API service unavailable. Please ensure the backend is running on localhost:5000 or deploy the Worker.');
        }
      }
      
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final token = await AuthService.getValidToken();
    if (token == null) {
      // Token expired or invalid - ensure logout and throw clear error
      await AuthService.logout();
      throw Exception('Session expired. Please refresh the page and login again.');
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final uri = Uri.parse('$kBackendBaseUrl$path');
      final headersWithBody = Map<String, String>.from(headers);
      final response = await http.post(uri, headers: headersWithBody, body: jsonEncode(body)).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        // Token expired - clear it and throw error
        await AuthService.logout();
        throw Exception('Session expired. Please refresh the page and login again.');
      } else if (response.statusCode == 503 || response.statusCode == 525 || response.statusCode == 502) {
        // Server errors - Worker might be down or misconfigured
        // Try fallback to localhost backend
        headersWithBody['body'] = jsonEncode(body);
        return await _tryFallback(path, headersWithBody, 'POST');
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error'] ?? 'Failed to execute query');
      }
    } catch (e) {
      // If it's already our custom exception, re-throw it
      if (e.toString().contains('Session expired')) {
        rethrow;
      }
      
      // Check if it's a network error - try fallback to localhost
      final errorStr = e.toString().toLowerCase();
      final isNetworkError = errorStr.contains('networkerror') ||
                            errorStr.contains('network error') ||
                            errorStr.contains('failed host lookup') ||
                            errorStr.contains('socketexception') ||
                            errorStr.contains('connection') ||
                            errorStr.contains('525') ||
                            errorStr.contains('502') ||
                            errorStr.contains('503');
      
      if (isNetworkError) {
        // Try fallback to localhost backend
        try {
          final headersWithBody = Map<String, String>.from(headers);
          headersWithBody['body'] = jsonEncode(body);
          return await _tryFallback(path, headersWithBody, 'POST');
        } catch (fallbackError) {
          throw Exception('API service unavailable. Please ensure the backend is running on localhost:5000 or deploy the Worker.');
        }
      }
      
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

