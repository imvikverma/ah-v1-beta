import 'dart:html' as html;

/// Backend API base URLs
/// Uses Cloudflare Worker API in production, localhost for local development
String get kBackendBaseUrl {
  final hostname = html.window.location.hostname;
  
  // Use production Cloudflare Worker API for production domains
  if (hostname != null && 
      (hostname.contains('saffronbolt.in') || 
       hostname.contains('aurumharmony-v1-beta.pages.dev'))) {
    return 'https://api.ah.saffronbolt.in';
  }
  
  // Use localhost for local development
  return 'http://localhost:5000';
}

/// Fallback API URL if production API is not available
String get kBackendBaseUrlFallback {
  return 'http://localhost:5000';
}

const String kAdminBaseUrl = 'http://localhost:5001';

