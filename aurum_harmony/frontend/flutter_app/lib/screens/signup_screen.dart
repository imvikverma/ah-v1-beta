import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback? onSignUpSuccess;
  
  const SignUpScreen({super.key, this.onSignUpSuccess});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final phone = _phoneController.text.trim();
      await AuthService.register(
        email: _emailController.text.trim(),
        phone: phone.isNotEmpty ? phone : null,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (mounted) {
        widget.onSignUpSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText('Sign up failed: $e'),
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
                            height: 120,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.account_balance_wallet,
                                size: 80,
                                color: colors.primary,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Create Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Join AurumHarmony v1.0 Beta',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email *',
                              hintText: 'user@domain.com',
                              prefixIcon: const Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Phone (optional)
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone (Optional)',
                              hintText: '+91-XXXXXXXXXX',
                              prefixIcon: const Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                final phone = value.replaceAll(RegExp(r'[^\d+]'), '');
                                if (phone.length < 10) {
                                  return 'Please enter a valid phone number';
                                }
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
                              labelText: 'Password *',
                              hintText: 'At least 6 characters',
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
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password *',
                              hintText: 'Re-enter your password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 32),

                          // Sign Up Button
                          Center(
                            child: Builder(
                              builder: (context) {
                                final screenWidth = MediaQuery.of(context).size.width;
                                return SizedBox(
                                  width: screenWidth > 600 ? 300 : double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleSignUp,
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
                                            'Sign Up',
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

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: colors.onSurface.withOpacity(0.7),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => LoginScreen(
                                        onLoginSuccess: widget.onSignUpSuccess,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Login'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Patent text
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

