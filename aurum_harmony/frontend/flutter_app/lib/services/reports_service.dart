import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ReportsService {
  final String baseUrl = 'http://localhost:5000/api';

  Future<Map<String, dynamic>> getTradeReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse('$baseUrl/reports/trades?start=$startStr&end=$endStr'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'trades': data['trades'] ?? [],
          'summary': data['summary'] ?? {},
        };
      } else if (response.statusCode == 404) {
        // No trades found for the period
        return {
          'success': true,
          'trades': [],
          'summary': {
            'total_pnl': 0.0,
            'win_rate': 0.0,
            'total_trades': 0,
            'avg_trade_return': 0.0,
          },
        };
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?.toString() ?? 'Failed to load report');
      }
    } catch (e) {
      print('Error fetching trade report: $e');
      return {
        'success': false,
        'error': e.toString(),
        'trades': [],
        'summary': {},
      };
    }
  }

  Future<Map<String, dynamic>> getPerformanceMetrics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse('$baseUrl/reports/metrics?start=$startStr&end=$endStr'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'metrics': data['metrics'] ?? {},
        };
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?.toString() ?? 'Failed to load metrics');
      }
    } catch (e) {
      print('Error fetching performance metrics: $e');
      return {
        'success': false,
        'error': e.toString(),
        'metrics': {},
      };
    }
  }
}
