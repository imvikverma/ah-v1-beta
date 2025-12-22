import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:vibration/vibration.dart';
import '../services/auth_service.dart';
import '../constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Standalone UPI Verification Screen with engaging animations
/// Features: Lottie animations, confetti, haptic feedback, pulsing gradients
class UpiVerificationScreen extends StatefulWidget {
  final Function(bool success, String? upiId)? onVerificationComplete;
  final bool showAppBar;

  const UpiVerificationScreen({
    Key? key,
    this.onVerificationComplete,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  _UpiVerificationScreenState createState() => _UpiVerificationScreenState();
}

class _UpiVerificationScreenState extends State<UpiVerificationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _upiController = TextEditingController();
  late ConfettiController _confettiController;
  late AnimationController _pulseController;
  bool _isVerifying = false;
  bool _isSuccess = false;
  bool _isFailure = false;
  String _statusMessage = "";
  double _verificationProgress = 0.0;
  String? _bonusMessage;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _verifyUpi() async {
    if (_upiController.text.isEmpty) return;

    setState(() {
      _isVerifying = true;
      _isSuccess = false;
      _isFailure = false;
      _statusMessage = "";
      _verificationProgress = 0.0;
    });

    // Haptic feedback on start
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 50]);
    }

    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Authentication required');

      // Simulate progress animation
      for (int i = 0; i <= 100; i += 20) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() {
            _verificationProgress = i / 100;
          });
        }
      }

      // Call backend UPI verification endpoint
      final response = await http.post(
        Uri.parse('$kBackendBaseUrl/api/onboarding/upi/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'upi_id': _upiController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        setState(() {
          _isVerifying = false;
          _isSuccess = true;
          _isFailure = false;
          _verificationProgress = 1.0;
          _statusMessage = data['message'] as String? ?? "UPI Verified! Instant funding unlocked 🚀";
          _bonusMessage = data['bonus_message'] as String?;
        });

        // Play confetti and haptic feedback on success
        _confettiController.play();
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(pattern: [0, 100, 50, 100]);
        }

        // Callback
        widget.onVerificationComplete?.call(true, _upiController.text.trim());
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to verify UPI');
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _isSuccess = false;
        _isFailure = true;
        _verificationProgress = 0.0;
        _statusMessage = "Invalid UPI – Try again or link bank manually";
      });

      // Haptic feedback on failure
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 200]);
      }

      // Callback
      widget.onVerificationComplete?.call(false, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text("Link Savings – UPI Magic ✨"),
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            )
          : null,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing gradient background for futuristic feel
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFF9933)
                                  .withOpacity(0.3 + _pulseController.value * 0.2),
                              const Color(0xFFFFD700).withOpacity(0.1),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Lottie Animations
                  if (_isVerifying)
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Lottie.asset(
                        'assets/animations/loading.json',
                        fit: BoxFit.contain,
                      ),
                    )
                  else if (_isSuccess)
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Lottie.asset(
                        'assets/animations/success.json',
                        fit: BoxFit.contain,
                        repeat: false,
                      ),
                    )
                  else if (_isFailure)
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Lottie.asset(
                        'assets/animations/error.json',
                        fit: BoxFit.contain,
                        repeat: false,
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Progress indicator (only when verifying)
                  if (_isVerifying) ...[
                    LinearProgressIndicator(
                      value: _verificationProgress,
                      backgroundColor: colors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Verifying... ${(_verificationProgress * 100).toInt()}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // UPI ID Input
                  TextField(
                    controller: _upiController,
                    enabled: !_isSuccess && !_isVerifying,
                    decoration: InputDecoration(
                      labelText: "Your UPI ID (e.g., name@upi)",
                      hintText: "yourname@upi",
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: _isSuccess,
                      fillColor: _isSuccess ? Colors.green.withOpacity(0.1) : null,
                    ),
                    onChanged: (_) {
                      if (_isFailure) {
                        setState(() {
                          _isFailure = false;
                          _statusMessage = "";
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Verify Button with gold gradient
                  if (!_isSuccess)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verifyUpi,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                        ),
                        child: Text(
                          _isVerifying ? 'Verifying...' : 'Verify UPI – Instant Magic!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  // Status Message
                  if (_statusMessage.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isSuccess ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                  
                  // Bonus Message
                  if (_isSuccess && _bonusMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.celebration, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _bonusMessage!,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Confetti overlay (only on success)
          if (_isSuccess)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.2,
              ),
            ),
        ],
      ),
    );
  }
}

