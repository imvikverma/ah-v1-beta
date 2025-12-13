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

  // Track last login time and validation failures
  static DateTime? _lastLoginTime;
  static DateTime? _lastValidationTime;
  static int _validationFailureCount = 0;
  static const _validationGracePeriod = Duration(seconds: 15); // Don't validate for 15s after login (increased for production)
  static const _validationInterval = Duration(minutes: 2); // Only validate every 2 minutes
  static const _maxValidationFailures = 3; // Allow 3 failures before clearing token (increased for production)

  /// Validate and refresh token if needed
  static Future<String?> getValidToken() async {
    final token = await getToken();
    if (token == null) return null;
    
    // Skip validation if we just logged in (grace period)
    if (_lastLoginTime != null) {
      final timeSinceLogin = DateTime.now().difference(_lastLoginTime!);
      if (timeSinceLogin < _validationGracePeriod) {
        return token; // Trust the token, skip validation immediately after login
      }
    }
    
    // Only validate every 2 minutes (less aggressive)
    if (_lastValidationTime != null) {
      final timeSinceValidation = DateTime.now().difference(_lastValidationTime!);
      if (timeSinceValidation < _validationInterval) {
        return token; // Skip validation, use cached result
      }
    }
    
    // Try to validate token by calling /api/auth/me
    try {
      final response = await http.get(
        Uri.parse('$kBackendBaseUrl/api/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 8)); // Increased timeout for production
      
      if (response.statusCode == 200) {
        // Token is valid - reset failure count
        _validationFailureCount = 0;
        _lastValidationTime = DateTime.now();
        return token;
      } else if (response.statusCode == 401) {
        // Token expired, try fallback (for localhost)
        try {
          final fallbackResponse = await http.get(
            Uri.parse('$kBackendBaseUrlFallback/api/auth/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ).timeout(const Duration(seconds: 5));
          
          if (fallbackResponse.statusCode == 200) {
            // Valid on fallback - reset failure count
            _validationFailureCount = 0;
            _lastValidationTime = DateTime.now();
            return token;
          }
        } catch (e) {
          // Fallback failed (expected if on production)
        }
        
        // For production (Cloudflare Worker), 401 might be temporary
        // Worker uses database fallback, so session might not be ready yet
        // Don't immediately fail - give it a chance
        _validationFailureCount++;
        
        // Only clear token after multiple failures (not on first failure)
        if (_validationFailureCount >= _maxValidationFailures) {
          // Token expired after multiple failures, clear it
          await logout();
          _validationFailureCount = 0; // Reset counter
          return null;
        }
        
        // Return token anyway on first/second failure (might be temporary timing issue)
        // Production Worker uses database sessions, so token might be valid even if JWT check fails
        _lastValidationTime = DateTime.now();
        return token;
      }
    } catch (e) {
      // Network error or timeout - return token anyway (might work)
      // Don't increment failure count on network errors
      // Production might have temporary network issues
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
        
        // Record login time for grace period
        _lastLoginTime = DateTime.now();
        _validationFailureCount = 0; // Reset failure count on successful login
        
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
            
            // Record login time for grace period
            _lastLoginTime = DateTime.now();
            _validationFailureCount = 0; // Reset failure count on successful login
            
            // Success with fallback - login worked, no error message needed
            return;
          } else {
            final error = jsonDecode(response.body) as Map<String, dynamic>;
            throw Exception(error['error']?.toString() ?? 'Login failed');
          }
        } catch (fallbackError) {
          // Both production API and localhost fallback failed
          // Extract the actual error message
          String errorMessage = '';
          if (fallbackError is Exception) {
            errorMessage = fallbackError.toString();
          } else {
            errorMessage = fallbackError.toString();
          }
          
          final errorMessageLower = errorMessage.toLowerCase();
          
          // Determine the actual error type
          final isNetworkError = errorMessageLower.contains('socketexception') || 
                                 errorMessageLower.contains('failed host lookup') ||
                                 errorMessageLower.contains('connection refused') ||
                                 errorMessageLower.contains('timeout') ||
                                 errorMessageLower.contains('network') ||
                                 errorMessageLower.contains('connection failed');
          
          // Check for database errors in the error message
          final isDatabaseError = errorMessageLower.contains('database connection error') || 
                                  errorMessageLower.contains('database is locked') ||
                                  errorMessageLower.contains('remoteexception') ||
                                  errorMessageLower.contains('operationalerror') ||
                                  errorMessageLower.contains('internal server error');
          
          // Check if localhost backend is actually reachable (not a network error)
          // If it's a network error, the backend isn't running
          // If it's not a network error, the backend is running but returned an error
          if (isNetworkError) {
            // Backend is not running or not reachable
            final isProduction = apiUrl.contains('saffronbolt.in') || apiUrl.contains('pages.dev');
            if (isProduction) {
              throw Exception('Cannot connect to backend APIs.\n\nBoth production API and local backend failed:\n• Production API (https://api.ah.saffronbolt.in) is unreachable\n• Local backend (http://localhost:5000) is not running\n\nTo fix:\n1. Start Flask backend: Run Option 1 or 4 in start-all.ps1\n2. Access app from http://localhost (not production URL)');
            } else {
              throw Exception('Cannot connect to backend API. Please ensure the Flask backend is running on localhost:5000.\n\nStart it with: Option 1 or 4 in start-all.ps1');
            }
          } else if (isDatabaseError) {
            // Backend is running but has a database error
            throw Exception('Backend database error. Please try again in a moment.\n\nIf this persists:\n1. Check backend logs: _local\\logs\\backend.log\n2. Restart backend: Option 1 or 4 in start-all.ps1');
          } else {
            // Backend is running but returned another error (e.g., invalid credentials)
            // Pass through the actual error message from backend
            throw fallbackError;
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
    DateTime? dateOfBirth,
    DateTime? anniversary,
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
          if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
          if (anniversary != null) 'anniversary': anniversary.toIso8601String().split('T')[0],
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
          // Extract the actual error message
          String errorMessage = '';
          if (fallbackError is Exception) {
            errorMessage = fallbackError.toString();
          } else {
            errorMessage = fallbackError.toString();
          }
          
          final errorMessageLower = errorMessage.toLowerCase();
          
          // Determine the actual error type
          final isNetworkError = errorMessageLower.contains('socketexception') || 
                                 errorMessageLower.contains('failed host lookup') ||
                                 errorMessageLower.contains('connection refused') ||
                                 errorMessageLower.contains('timeout') ||
                                 errorMessageLower.contains('network') ||
                                 errorMessageLower.contains('connection failed');
          
          // Check for database errors in the error message
          final isDatabaseError = errorMessageLower.contains('database connection error') || 
                                  errorMessageLower.contains('database is locked') ||
                                  errorMessageLower.contains('remoteexception') ||
                                  errorMessageLower.contains('operationalerror') ||
                                  errorMessageLower.contains('internal server error');
          
          // Check if localhost backend is actually reachable (not a network error)
          // If it's a network error, the backend isn't running
          // If it's not a network error, the backend is running but returned an error
          if (isNetworkError) {
            // Backend is not running or not reachable
            final isProduction = apiUrl.contains('saffronbolt.in') || apiUrl.contains('pages.dev');
            if (isProduction) {
              throw Exception('Cannot connect to backend APIs.\n\nBoth production API and local backend failed:\n• Production API (https://api.ah.saffronbolt.in) is unreachable\n• Local backend (http://localhost:5000) is not running\n\nTo fix:\n1. Start Flask backend: Run Option 1 or 4 in start-all.ps1\n2. Access app from http://localhost (not production URL)');
            } else {
              throw Exception('Cannot connect to backend API. Please ensure the Flask backend is running on localhost:5000.\n\nStart it with: Option 1 or 4 in start-all.ps1');
            }
          } else if (isDatabaseError) {
            // Backend is running but has a database error
            throw Exception('Backend database error. Please try again in a moment.\n\nIf this persists:\n1. Check backend logs: _local\\logs\\backend.log\n2. Restart backend: Option 1 or 4 in start-all.ps1');
          } else {
            // Backend is running but returned another error (e.g., invalid credentials)
            // Pass through the actual error message from backend
            throw fallbackError;
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
