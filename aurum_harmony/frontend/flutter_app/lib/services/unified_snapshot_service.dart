/// Unified Snapshot Service
///
/// Fetches aggregated data from all trading engines (HDFC Sky NSE/BSE, Kotak Neo NSE/BSE, Paper, Backtest)
/// and provides a unified view for the frontend.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'auth_service.dart';

class UnifiedSnapshotService {
  /// Fetch unified snapshot from all engines
  static Future<Map<String, dynamic>> getUnifiedSnapshot() async {
    try {
      final token = await AuthService.getValidToken();
      final response = await http.get(
        Uri.parse('$kBackendBaseUrl/api/unified-snapshot'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'snapshot': data['snapshot'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch unified snapshot: ${response.statusCode}',
          'snapshot': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'snapshot': null,
      };
    }
  }

  /// Get aggregated positions from all engines
  static Future<List<Map<String, dynamic>>> getAggregatedPositions() async {
    final result = await getUnifiedSnapshot();
    if (result['success'] == true && result['snapshot'] != null) {
      final snapshot = result['snapshot'] as Map<String, dynamic>;
      final positions = snapshot['all_positions'] as List? ?? [];
      return positions.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Get aggregated balance from all engines
  static Future<Map<String, dynamic>?> getAggregatedBalance() async {
    final result = await getUnifiedSnapshot();
    if (result['success'] == true && result['snapshot'] != null) {
      final snapshot = result['snapshot'] as Map<String, dynamic>;
      return snapshot['aggregated_balance'] as Map<String, dynamic>?;
    }
    return null;
  }

  /// Get engine-specific snapshots
  static Future<Map<String, dynamic>> getEngineSnapshots() async {
    final result = await getUnifiedSnapshot();
    if (result['success'] == true && result['snapshot'] != null) {
      final snapshot = result['snapshot'] as Map<String, dynamic>;
      return snapshot['engine_snapshots'] as Map<String, dynamic>? ?? {};
    }
    return {};
  }

  /// Get summary statistics
  static Future<Map<String, dynamic>> getSummary() async {
    final result = await getUnifiedSnapshot();
    if (result['success'] == true && result['snapshot'] != null) {
      final snapshot = result['snapshot'] as Map<String, dynamic>;
      final balance = snapshot['aggregated_balance'] as Map<String, dynamic>?;
      final positions = snapshot['all_positions'] as List? ?? [];
      
      // Calculate totals
      double totalPnL = 0.0;
      double totalUnrealizedPnL = 0.0;
      for (var pos in positions) {
        totalUnrealizedPnL += (pos['unrealized_pnl'] as num?)?.toDouble() ?? 0.0;
      }
      
      return {
        'total_engines': snapshot['total_engines'] ?? 0,
        'available_engines': snapshot['available_engines'] ?? 0,
        'total_positions': positions.length,
        'total_balance': balance?['available'] ?? 0.0,
        'total_equity': balance?['total_equity'] ?? 0.0,
        'total_unrealized_pnl': totalUnrealizedPnL,
        'total_realized_pnl': balance?['realized_pnl'] ?? 0.0,
        'margin_used': balance?['margin_used'] ?? 0.0,
      };
    }
    return {
      'total_engines': 0,
      'available_engines': 0,
      'total_positions': 0,
      'total_balance': 0.0,
      'total_equity': 0.0,
      'total_unrealized_pnl': 0.0,
      'total_realized_pnl': 0.0,
      'margin_used': 0.0,
    };
  }
}

