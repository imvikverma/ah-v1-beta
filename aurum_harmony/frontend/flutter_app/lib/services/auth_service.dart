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

  /// Validate and refresh token if needed
  static Future<String?> getValidToken() async {
    final token = await getToken();
    if (token == null) return null;
    
    // Try to validate token by calling /api/auth/me
    try {
      final response = await http.get(
        Uri.parse('$kBackendBaseUrl/api/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return token; // Token is valid
      } else if (response.statusCode == 401) {
        // Token expired, try fallback
        try {
          final fallbackResponse = await http.get(
            Uri.parse('$kBackendBaseUrlFallback/api/auth/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ).timeout(const Duration(seconds: 5));
          
          if (fallbackResponse.statusCode == 200) {
            return token; // Valid on fallback
          }
        } catch (e) {
          // Fallback failed
        }
        
        // Token expired, clear it
        await logout();
        return null;
      }
    } catch (e) {
      // Network error, return token anyway (might work)
      return token;
    }
    
    return token;
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

    // Try production API first, fallback to localhost if it fails
    String? apiUrl = kBackendBaseUrl;
    Exception? lastError;
    
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (email != null && email.isNotEmpty) 'email': email.trim(),
          if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

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
        return; // Success!
      } else if (response.statusCode == 501) {
        // Worker returns 501 for bcrypt hashes or unmigrated endpoints - trigger fallback
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final status = errorData['status']?.toString() ?? '';
        if (status == 'bcrypt_not_supported') {
          // bcrypt hash detected - automatically fallback to Flask
          throw Exception('BCRYPT_FALLBACK');
        } else {
          throw Exception('ENDPOINT_NOT_MIGRATED');
        }
      } else if (response.statusCode == 503) {
        // Service unavailable - try fallback
        throw Exception('SERVICE_UNAVAILABLE');
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?.toString() ?? 'Login failed');
      }
    } catch (e) {
      lastError = e is Exception ? e : Exception('Network error: $e');
      
      // If production API failed and we're not already on localhost, ALWAYS try localhost fallback
      // This ensures we try Flask backend even if error detection isn't perfect
      if (apiUrl != kBackendBaseUrlFallback) {
        try {
          final response = await http.post(
            Uri.parse('$kBackendBaseUrlFallback/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (email != null && email.isNotEmpty) 'email': email.trim(),
              if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
              'password': password,
            }),
          ).timeout(const Duration(seconds: 5));

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
            final isAdmin = user['is_admin'] == true || user['isAdmin'] == true;
            await prefs.setBool(_keyIsAdmin, isAdmin);
            // Success with fallback - login worked, no error message needed
            return;
          } else {
            final error = jsonDecode(response.body) as Map<String, dynamic>;
            throw Exception(error['error']?.toString() ?? 'Login failed');
          }
        } catch (fallbackError) {
          // Both production API and localhost fallback failed
          final isProduction = apiUrl.contains('saffronbolt.in') || apiUrl.contains('pages.dev');
          if (isProduction) {
            throw Exception('Cannot connect to Cloudflare Worker API (https://api.ah.saffronbolt.in).\n\nEmergency troubleshooting:\n1. Check if Cloudflare Worker is deployed and running\n2. Verify DNS records for api.ah.saffronbolt.in\n3. For local testing, run backend locally (Option 1 in start-all.ps1) and access app from http://localhost');
          } else {
            throw Exception('Cannot connect to backend API. Please ensure the Flask backend is running on localhost:5000.\n\nStart it with: Option 1 in start-all.ps1');
          }
        }
      }
      
      // Re-throw if not a network error or fallback already tried
      throw lastError ?? Exception('Login error: $e');
    }
  }

  /// Logout and clear stored credentials
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyPhone);
      await prefs.remove(_keyIsAdmin);
      await prefs.remove(_keyIndemnityAccepted);
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

  /// Register a new user
  static Future<void> register({
    required String email,
    String? phone,
    String? username,
    required String password,
    required String confirmPassword,
    String? profilePictureUrl,
    required bool termsAccepted,
  }) async {
    if (email.isEmpty) {
      throw Exception('Email is required');
    }

    if (password.isEmpty || password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    if (password != confirmPassword) {
      throw Exception('Passwords do not match');
    }

    if (!termsAccepted) {
      throw Exception('You must accept the Terms & Conditions');
    }

    // Try production API first, fallback to localhost if it fails
    String? apiUrl = kBackendBaseUrl;
    Exception? lastError;
    
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
          if (username != null && username.isNotEmpty) 'username': username.trim(),
          'password': password,
          if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
          'terms_accepted': termsAccepted,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>;
        
        // Auto-login after successful registration (login has its own fallback)
        await login(
          email: email,
          phone: phone,
          password: password,
        );
        return; // Success!
      } else if (response.statusCode == 501) {
        // Worker returns 501 for unmigrated endpoints - trigger fallback
        throw Exception('ENDPOINT_NOT_MIGRATED');
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?.toString() ?? 'Registration failed');
      }
    } catch (e) {
      lastError = e is Exception ? e : Exception('Network error: $e');
      
      // If production API failed (network error, 501, or timeout) and we're not already on localhost, try localhost
      final shouldFallbackReg = apiUrl != kBackendBaseUrlFallback && 
          (e.toString().contains('NetworkError') || 
           e.toString().contains('Failed host lookup') ||
           e.toString().contains('timeout') ||
           e.toString().contains('ENDPOINT_NOT_MIGRATED') ||
           e.toString().contains('SocketException'));
      
      if (shouldFallbackReg) {
        try {
          final response = await http.post(
            Uri.parse('$kBackendBaseUrlFallback/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim(),
              if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
              if (username != null && username.isNotEmpty) 'username': username.trim(),
              'password': password,
              if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
              'terms_accepted': termsAccepted,
            }),
            ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 201) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final user = data['user'] as Map<String, dynamic>;
            
            // Auto-login after successful registration
            await login(
              email: email,
              phone: phone,
              password: password,
            );
            return; // Success with fallback!
          } else {
            final error = jsonDecode(response.body) as Map<String, dynamic>;
            throw Exception(error['error']?.toString() ?? 'Registration failed');
          }
        } catch (fallbackError) {
          // Both production API and localhost fallback failed
          final isProduction = apiUrl.contains('saffronbolt.in') || apiUrl.contains('pages.dev');
          if (isProduction) {
            throw Exception('Cannot connect to Cloudflare Worker API (https://api.ah.saffronbolt.in).\n\nEmergency troubleshooting:\n1. Check if Cloudflare Worker is deployed and running\n2. Verify DNS records for api.ah.saffronbolt.in\n3. For local testing, run backend locally (Option 1 in start-all.ps1) and access app from http://localhost');
          } else {
            throw Exception('Cannot connect to backend API. Please ensure the Flask backend is running on localhost:5000.\n\nStart it with: Option 1 in start-all.ps1');
          }
        }
      }
      
      // Re-throw if not a network error or fallback already tried
      throw lastError ?? Exception('Registration error: $e');
    }
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

  /// Check if user is admin
  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsAdmin) ?? false;
  }

  /// Check if user has accepted indemnity
  static Future<bool> hasAcceptedIndemnity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIndemnityAccepted) ?? false;
  }

  /// Accept indemnity
  static Future<void> acceptIndemnity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIndemnityAccepted, true);
  }
}
