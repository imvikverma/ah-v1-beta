import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/broker_service.dart';

/// Kotak Neo Authentication Dialog
/// 
/// One-time setup dialog for TOTP and MPIN authentication.
/// After successful authentication, tokens are stored for future use.
class KotakAuthDialog extends StatefulWidget {
  final String userId;
  final Function(bool success)? onComplete;

  const KotakAuthDialog({
    Key? key,
    required this.userId,
    this.onComplete,
  }) : super(key: key);

  @override
  State<KotakAuthDialog> createState() => _KotakAuthDialogState();
}

class _KotakAuthDialogState extends State<KotakAuthDialog> {
  final _totpController = TextEditingController();
  final _mpinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showMpinStep = false;
  bool _totpSuccess = false;

  @override
  void dispose() {
    _totpController.dispose();
    _mpinController.dispose();
    super.dispose();
  }

  Future<void> _submitTOTP() async {
    if (_totpController.text.length != 6) {
      setState(() {
        _errorMessage = "TOTP must be 6 digits";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await BrokerService.loginKotakTOTP(
        userId: widget.userId,
        totp: _totpController.text,
      );

      if (success) {
        setState(() {
          _totpSuccess = true;
          _showMpinStep = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "TOTP login failed. Please check your code.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  Future<void> _submitMPIN() async {
    if (_mpinController.text.length != 6) {
      setState(() {
        _errorMessage = "MPIN must be 6 digits";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await BrokerService.validateKotakMPIN(
        userId: widget.userId,
        mpin: _mpinController.text,
      );

      if (success) {
        // Success! Tokens are now stored
        if (widget.onComplete != null) {
          widget.onComplete!(true);
        }
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = "MPIN validation failed. Please try again.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kotak Neo Authentication'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_showMpinStep) ...[
              const Text(
                'Step 1: Enter TOTP Code',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Open your authenticator app (Google/Microsoft Authenticator) and enter the 6-digit TOTP code.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _totpController,
                decoration: const InputDecoration(
                  labelText: 'TOTP Code',
                  hintText: '123456',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                onSubmitted: (_) => _submitTOTP(),
              ),
            ] else ...[
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Step 2: Enter MPIN',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your 6-digit trading MPIN (not your login password).',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _mpinController,
                decoration: const InputDecoration(
                  labelText: 'MPIN',
                  hintText: '123456',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                maxLength: 6,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                onSubmitted: (_) => _submitMPIN(),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_showMpinStep) ...[
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitTOTP,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue'),
          ),
        ] else ...[
          TextButton(
            onPressed: _isLoading ? null : () {
              setState(() {
                _showMpinStep = false;
                _mpinController.clear();
                _errorMessage = null;
              });
            },
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitMPIN,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Complete Setup'),
          ),
        ],
      ],
    );
  }
}

