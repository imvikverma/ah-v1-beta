import 'dart:html' as html;

/// Backend API base URLs
/// Automatically detects production vs development environment
String get kBackendBaseUrl {
  // Check if running on production domain
  final hostname = html.window.location.hostname;
  if (hostname != null && 
      (hostname.contains('saffronbolt.in') || 
       hostname.contains('aurumharmony-v1-beta.pages.dev'))) {
    return 'https://api.ah.saffronbolt.in';
  }
  // Default to localhost for development
  return 'http://localhost:5000';
}

const String kAdminBaseUrl = 'http://localhost:5001';

