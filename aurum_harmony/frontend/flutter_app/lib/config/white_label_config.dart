/// White Label Configuration
/// Allows co-branding of the app with different logos, colors, and company names
class WhiteLabelConfig {
  // App Identity
  final String appName;
  final String companyName;
  final String? logoPath;
  
  // Brand Colors
  final int primaryColorValue;
  final int secondaryColorValue;
  final int? accentColorValue;
  
  // Optional Customizations
  final String? supportEmail;
  final String? supportPhone;
  final String? websiteUrl;
  final Map<String, dynamic>? customMetadata;
  
  const WhiteLabelConfig({
    required this.appName,
    required this.companyName,
    this.logoPath,
    required this.primaryColorValue,
    required this.secondaryColorValue,
    this.accentColorValue,
    this.supportEmail,
    this.supportPhone,
    this.websiteUrl,
    this.customMetadata,
  });
  
  /// Default AurumHarmony configuration
  factory WhiteLabelConfig.defaultConfig() {
    return const WhiteLabelConfig(
      appName: 'AurumHarmony',
      companyName: 'ZenithPulse Tech Pvt Ltd',
      logoPath: 'assets/logo/AurumHarmony_logo.png',
      primaryColorValue: 0xfff9a826, // Saffron/Gold
      secondaryColorValue: 0xff4caf50, // Green
      accentColorValue: 0xff2196f3, // Blue
      supportEmail: 'support@aurumharmony.com',
      websiteUrl: 'https://ah.saffronbolt.in',
    );
  }
  
  /// Create from JSON map (for API/database configuration)
  factory WhiteLabelConfig.fromJson(Map<String, dynamic> json) {
    return WhiteLabelConfig(
      appName: json['app_name'] as String? ?? 'AurumHarmony',
      companyName: json['company_name'] as String? ?? 'ZenithPulse Tech Pvt Ltd',
      logoPath: json['logo_path'] as String?,
      primaryColorValue: json['primary_color'] as int? ?? 0xfff9a826,
      secondaryColorValue: json['secondary_color'] as int? ?? 0xff4caf50,
      accentColorValue: json['accent_color'] as int?,
      supportEmail: json['support_email'] as String?,
      supportPhone: json['support_phone'] as String?,
      websiteUrl: json['website_url'] as String?,
      customMetadata: json['custom_metadata'] as Map<String, dynamic>?,
    );
  }
  
  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'app_name': appName,
      'company_name': companyName,
      'logo_path': logoPath,
      'primary_color': primaryColorValue,
      'secondary_color': secondaryColorValue,
      'accent_color': accentColorValue,
      'support_email': supportEmail,
      'support_phone': supportPhone,
      'website_url': websiteUrl,
      'custom_metadata': customMetadata,
    };
  }
  
  /// Get primary color as Color object
  int get primaryColor => primaryColorValue;
  
  /// Get secondary color as Color object
  int get secondaryColor => secondaryColorValue;
  
  /// Get accent color as Color object (falls back to primary if not set)
  int get accentColor => accentColorValue ?? primaryColorValue;
}

/// White Label Service
/// Manages white label configuration and provides access throughout the app
class WhiteLabelService {
  static WhiteLabelConfig _config = WhiteLabelConfig.defaultConfig();
  
  /// Get current white label configuration
  static WhiteLabelConfig get config => _config;
  
  /// Set white label configuration
  static void setConfig(WhiteLabelConfig config) {
    _config = config;
  }
  
  /// Load configuration from JSON
  static void loadFromJson(Map<String, dynamic> json) {
    _config = WhiteLabelConfig.fromJson(json);
  }
  
  /// Reset to default configuration
  static void resetToDefault() {
    _config = WhiteLabelConfig.defaultConfig();
  }
  
  /// Check if using custom white label (not default)
  static bool get isCustomWhiteLabel {
    return _config.appName != 'AurumHarmony' ||
           _config.companyName != 'ZenithPulse Tech Pvt Ltd';
  }
}

