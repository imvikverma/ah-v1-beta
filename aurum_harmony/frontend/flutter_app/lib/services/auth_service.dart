import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

/// Authentication service using backend API
class AuthService {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyEmail = 'user_email';
  static const String _keyPhone = 'user_phone';
  static const String _keyIsAdmin = 'user_is_admin';
  static const String _keyIndemnityAccepted = 'indemnity_accepted';
  static const String _keyApiKey = 'api_key'; // Legacy support
  static const String _keyApiSecret = 'api_secret'; // Legacy support

  /// Check if user is logged in by verifying token
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      if (token == null || token.isEmpty) {
        return false;
      }

      // Verify token with backend (optional - can be done on app start)
      // For now, just check if token exists
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Login with email/phone and password
  static Future<void> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    if ((email == null || email.isEmpty) && (phone == null || phone.isEmpty)) {
      throw Exception('Email or phone is required');
    }

    if (password.isEmpty) {
      throw Exception('Password is required');
    }

    try {
      final response = await http.post(
        Uri.parse('$kBackendBaseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (email != null && email.isNotEmpty) 'email': email.trim(),
          if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String;
        final user = data['user'] as Map<String, dynamic>;

        // Store token and user info
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, token);
        await prefs.setString(_keyUserId, user['id']?.toString() ?? '');
        if (user['email'] != null) {
          await prefs.setString(_keyEmail, user['email'].toString());
        }
        if (user['phone'] != null) {
          await prefs.setString(_keyPhone, user['phone'].toString());
        }
        // Store admin status
        final isAdmin = user['is_admin'] == true || user['isAdmin'] == true;
        await prefs.setBool(_keyIsAdmin, isAdmin);
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?.toString() ?? 'Login failed');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Login error: $e');
    }
  }

  /// Logout user
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);

      // Call backend logout if token exists
      if (token != null && token.isNotEmpty) {
        try {
          await http.post(
            Uri.parse('$kBackendBaseUrl/api/auth/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        } catch (e) {
          // Ignore logout errors - clear local storage anyway
        }
      }

      // Clear local storage
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyPhone);
      await prefs.remove(_keyIsAdmin);
      await prefs.remove(_keyIndemnityAccepted);
    } catch (e) {
      // Clear local storage even if logout fails
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyPhone);
      await prefs.remove(_keyIsAdmin);
      await prefs.remove(_keyIndemnityAccepted);
    }
  }

  /// Check if current user is admin
  static Future<bool> isAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsAdmin) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has accepted indemnity
  static Future<bool> hasAcceptedIndemnity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIndemnityAccepted) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark indemnity as accepted
  static Future<void> acceptIndemnity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIndemnityAccepted, true);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Get current user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// Get auth token for API calls
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Get user email
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  /// Get user phone
  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhone);
  }

  /// Legacy methods for backward compatibility
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiKey);
  }

  static Future<String?> getApiSecret() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiSecret);
  }

  static Future<Map<String, String?>> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'user_id': prefs.getString(_keyUserId),
      'api_key': prefs.getString(_keyApiKey),
      'api_secret': prefs.getString(_keyApiSecret),
    };
  }
}

