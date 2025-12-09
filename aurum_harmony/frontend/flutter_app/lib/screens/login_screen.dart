import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  
  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final loginId = _loginIdController.text.trim();
      
      // Determine if loginId is email or phone
      String? email;
      String? phone;
      
      if (loginId.contains('@')) {
        email = loginId;
      } else {
        phone = loginId.replaceAll(RegExp(r'[^\d+]'), '');
        if (!phone.startsWith('+')) {
          phone = '+91$phone'; // Default to India country code if not provided
        }
      }

      await AuthService.login(
        email: email,
        phone: phone,
        password: _passwordController.text,
      );

      if (mounted) {
        widget.onLoginSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText('Login failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 30), // Extended duration for copying
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    colors.background,
                    colors.surface,
                  ]
                : [
                    colors.background,
                    colors.surfaceVariant,
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Theme Toggle Button (top right) - Mobile-friendly
              Positioned(
                top: 8,
                right: 8,
                child: ListenableBuilder(
                  listenable: ThemeService.instance,
                  builder: (context, _) {
                    final themeService = ThemeService.instance;
                    final isDark = themeService.isDarkMode;
                    
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          themeService.toggleTheme();
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width > 600 ? 500 : 400,
                ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      // Logo
                      Image.asset(
                        'assets/logo/AurumHarmony_logo.png',
                        height: 180,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to icon if logo not found
                          return Icon(
                            Icons.account_balance_wallet,
                            size: 120,
                            color: colors.primary,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'v1.0 Beta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Email / Phone
                      TextFormField(
                        controller: _loginIdController,
                        decoration: InputDecoration(
                          labelText: 'Email / Phone',
                          hintText: 'user@domain.com or +91-XXXXXXXXXX',
                          prefixIcon: const Icon(Icons.person),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email or phone';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // Login / Continue Button
                      Center(
                        child: Builder(
                          builder: (context) {
                            final screenWidth = MediaQuery.of(context).size.width;
                            return SizedBox(
                              width: screenWidth > 600 ? 300 : double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: colors.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(colors.onPrimary),
                                        ),
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: colors.onSurface.withOpacity(0.7),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => SignUpScreen(
                                    onSignUpSuccess: widget.onLoginSuccess,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Sign Up'),
                          ),
                        ],
                      ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Patent text on login screen - responsive, fits in one line
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      child: Text(
                        'Patent Pending — 202521105260 — ZenithPulse Tech Pvt Ltd',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 11 : 9,
                          color: colors.onSurface.withOpacity(0.5),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

