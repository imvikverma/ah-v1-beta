import 'dart:html' as html;

/// Backend API base URLs
/// Uses Cloudflare Worker API in production, localhost for local development
String get kBackendBaseUrl {
  final hostname = html.window.location.hostname;
  
  // Use production Cloudflare Worker API v2 for production domains
  if (hostname != null && 
      (hostname.contains('saffronbolt.in') || 
       hostname.contains('aurumharmony-v1-beta.pages.dev'))) {
    return 'https://api-v2.saffronbolt.in';
  }
  
  // When running on port 8080 (Docker), use empty string for same-origin requests
  if (hostname != null && html.window.location.port == '8080') {
    return '';
  }
  
  // Use localhost for local development (flutter run)
  return 'http://localhost:5000';
}

/// Fallback API URL if production API is not available
String get kBackendBaseUrlFallback {
  return 'http://localhost:5000';
}

String get kAdminBaseUrl {
  final hostname = html.window.location.hostname;
  
  // When running on port 8080 (Docker), use empty string for same-origin requests
  if (hostname != null && html.window.location.port == '8080') {
    return '';
  }
  
  return 'http://localhost:5001';
}

