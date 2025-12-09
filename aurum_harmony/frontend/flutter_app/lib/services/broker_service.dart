import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'auth_service.dart';

/// Service for managing broker connections (HDFC Sky, Kotak Neo, etc.)
class BrokerService {
  static const Duration timeout = Duration(seconds: 15);

  /// Get list of available brokers and user's connected brokers
  static Future<Map<String, dynamic>> getBrokers() async {
    try {
      final userId = await AuthService.getUserId() ?? 'user001';
      final token = await _getAuthToken();
      
      final response = await http.get(
        Uri.parse('$kBackendBaseUrl/api/brokers/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load brokers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching brokers: $e');
    }
  }

  /// Connect a broker with manual credentials
  static Future<Map<String, dynamic>> connectBroker({
    required String brokerName,
    required String apiKey,
    required String apiSecret,
    String? tokenId,
  }) async {
    try {
      final token = await _getAuthToken();
      
      final response = await http.post(
        Uri.parse('$kBackendBaseUrl/api/brokers/connect'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'broker_name': brokerName,
          'oauth': false, // HDFC Sky doesn't support OAuth
          'api_key': apiKey,
          'api_secret': apiSecret,
          if (tokenId != null && tokenId.isNotEmpty) 'token_id': tokenId,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to connect broker: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting broker: $e');
    }
  }

  /// Disconnect a broker
  static Future<void> disconnectBroker(String brokerName) async {
    try {
      final token = await _getAuthToken();
      
      final response = await http.post(
        Uri.parse('$kBackendBaseUrl/api/brokers/disconnect'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'broker_name': brokerName,
        }),
      ).timeout(timeout);

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to disconnect broker');
      }
    } catch (e) {
      throw Exception('Error disconnecting broker: $e');
    }
  }

  /// Check broker connection status
  static Future<Map<String, dynamic>> getBrokerStatus(String brokerName) async {
    try {
      final token = await _getAuthToken();
      
      final response = await http.get(
        Uri.parse('$kBackendBaseUrl/api/brokers/$brokerName/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get broker status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking broker status: $e');
    }
  }

  /// Kotak Neo TOTP Login (Step 1)
  static Future<bool> loginKotakTOTP({
    required String userId,
    required String totp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$kBackendBaseUrl/api/brokers/kotak/login/totp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'totp': totp,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('TOTP login error: $e');
    }
  }

  /// Kotak Neo MPIN Validation (Step 2)
  static Future<bool> validateKotakMPIN({
    required String userId,
    required String mpin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$kBackendBaseUrl/api/brokers/kotak/login/mpin'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'mpin': mpin,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('MPIN validation error: $e');
    }
  }

  /// Check if Kotak Neo is authenticated (has stored tokens)
  static Future<bool> isKotakAuthenticated(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$kBackendBaseUrl/api/brokers/kotak/status?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['authenticated'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get authentication token from AuthService
  static Future<String> _getAuthToken() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Not authenticated. Please login first.');
    }
    return token;
  }
}

