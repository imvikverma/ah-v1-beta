import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'auth_service.dart';

/// Paper Trading Service
/// Handles all paper trading API calls
class PaperTradingService {
  /// Get paper trading account balance
  static Future<Map<String, dynamic>> getBalance(String userId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$kBackendBaseUrl/api/paper/balance?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?.toString() ?? 'Failed to get balance');
      }
    } catch (e) {
      throw Exception('Balance error: $e');
    }
  }

  /// Get open positions
  static Future<Map<String, dynamic>> getPositions(String userId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$kBackendBaseUrl/api/paper/positions?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?.toString() ?? 'Failed to get positions');
      }
    } catch (e) {
      throw Exception('Positions error: $e');
    }
  }

  /// Get all orders
  static Future<Map<String, dynamic>> getOrders(String userId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$kBackendBaseUrl/api/paper/orders?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?.toString() ?? 'Failed to get orders');
      }
    } catch (e) {
      throw Exception('Orders error: $e');
    }
  }

  /// Get order history
  static Future<Map<String, dynamic>> getOrderHistory(String userId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$kBackendBaseUrl/api/paper/orders/history?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?.toString() ?? 'Failed to get order history');
      }
    } catch (e) {
      throw Exception('Order history error: $e');
    }
  }

  /// Place a paper trading order
  static Future<Map<String, dynamic>> placeOrder({
    required String userId,
    required String symbol,
    required String side, // 'BUY' or 'SELL'
    required double quantity,
    String orderType = 'MARKET', // 'MARKET' or 'LIMIT'
    double? limitPrice,
    String? reason,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('$kBackendBaseUrl/api/paper/orders'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'symbol': symbol,
          'side': side,
          'quantity': quantity,
          'order_type': orderType,
          if (limitPrice != null) 'limit_price': limitPrice,
          if (reason != null) 'reason': reason,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?.toString() ?? 'Failed to place order');
      }
    } catch (e) {
      throw Exception('Place order error: $e');
    }
  }

  /// Cancel an order
  static Future<bool> cancelOrder(String userId, String orderId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('$kBackendBaseUrl/api/paper/orders/$orderId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'user_id': userId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Get complete portfolio summary
  static Future<Map<String, dynamic>> getPortfolio(String userId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$kBackendBaseUrl/api/paper/portfolio?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?.toString() ?? 'Failed to get portfolio');
      }
    } catch (e) {
      throw Exception('Portfolio error: $e');
    }
  }

  /// Reset paper trading portfolio (for testing)
  static Future<bool> resetPortfolio(String userId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('$kBackendBaseUrl/api/paper/reset'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'user_id': userId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}

