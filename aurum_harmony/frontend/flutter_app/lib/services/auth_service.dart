import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple authentication service using SharedPreferences
/// In production, this would connect to a real auth backend
class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyApiKey = 'api_key';
  static const String _keyApiSecret = 'api_secret';
  static const String _keyUserId = 'user_id';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<void> login({
    required String userId,
    required String apiKey,
    required String apiSecret,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyApiKey, apiKey);
    await prefs.setString(_keyApiSecret, apiSecret);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyApiKey);
    await prefs.remove(_keyApiSecret);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

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

