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
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error']?.toString() ?? 'Login failed');
      }
    } catch (e) {
      lastError = e is Exception ? e : Exception('Network error: $e');
      
      // Check if this is a 501 response or network error that should trigger fallback
      final errorString = e.toString();
      final isNetworkError = errorString.contains('NetworkError') || 
                            errorString.contains('Failed host lookup') ||
                            errorString.contains('timeout') ||
                            errorString.contains('SocketException') ||
                            errorString.contains('Connection refused') ||
                            errorString.contains('Connection closed') ||
                            errorString.contains('ENDPOINT_NOT_MIGRATED') ||
                            errorString.contains('BCRYPT_FALLBACK');
      
      // If production API failed and we're not already on localhost, try localhost
      if (apiUrl != kBackendBaseUrlFallback && isNetworkError) {
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
      final isProductionUrl = apiUrl.contains('saffronbolt.in') || apiUrl.contains('pages.dev');
      if (isProductionUrl) {
        // Check if it's a 501 (endpoint not migrated) vs actual connection failure
        if (e.toString().contains('ENDPOINT_NOT_MIGRATED') || 
            (lastError?.toString().contains('501') ?? false)) {
          throw Exception(
            'Cloudflare Worker API endpoint not yet migrated.\n\n'
            'The login endpoint (/api/auth/login) is not yet implemented in the Worker.\n'
            'Falling back to localhost backend...\n\n'
            'To use the Worker:\n'
            '• Migrate the auth endpoints to the Worker\n'
            '• Or use localhost backend: start-all.ps1 → Option 1'
          );
        } else {
          throw Exception(
            'Cannot connect to Cloudflare Worker API.\n\n'
            'The production API (https://api.ah.saffronbolt.in) is not accessible.\n'
            'This may be because:\n'
            '• Cloudflare Worker is not deployed yet\n'
            '• DNS is not configured\n'
            '• Network connectivity issues\n\n'
            'For local testing:\n'
            '• Run backend: start-all.ps1 → Option 1\n'
            '• Access app from: http://localhost:58643'
          );
        }
      } else {
        throw lastError ?? Exception('Login error: $e');
      }
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

  /// Register a new user
  static Future<void> register({
    required String email,
    String? phone,
    required String password,
    required String confirmPassword,
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
          'password': password,
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
              'password': password,
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
}

