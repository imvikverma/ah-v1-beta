import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:vibration/vibration.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/broker_service.dart';
import '../widgets/lottie_loading.dart';
import '../widgets/success_animation.dart';
import '../constants.dart';
import 'dashboard_screen.dart';

class OnboardingWizardScreen extends StatefulWidget {
  @override
  _OnboardingWizardScreenState createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  late ConfettiController _confettiController;

  final AuthService _authService = AuthService();
  final BrokerService _brokerService = BrokerService();

  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _apiSecretController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();

  String? _selectedBroker;
  String? _selectedBank;
  bool _isExistingDemat = true;
  bool _isExistingSavings = true;

  final List<Map<String, dynamic>> _brokers = [
    {"name": "Kotak Neo", "status": "active", "code": "kotak_neo"},
    {"name": "HDFC Sky", "status": "active", "code": "hdfc_sky"},
  ];

  final List<String> _banks = ["HDFC", "Kotak", "ICICI", "Axis", "SBI"];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _testBrokerConnection() async {
    if (_selectedBroker == null || _apiKeyController.text.isEmpty || _apiSecretController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all broker details')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _brokerService.testBrokerConnection(
        brokerName: _selectedBroker!,
        apiKey: _apiKeyController.text,
        apiSecret: _apiSecretController.text,
      );

      if (success) {
        await _brokerService.saveBrokerCredentials(
          brokerName: _selectedBroker!,
          apiKey: _apiKeyController.text,
          apiSecret: _apiSecretController.text,
        );

        // Play success animation
        _confettiController.play();
        Vibration.vibrate(duration: 200);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Broker connected successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Move to next step after a delay
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            _goToNextStep();
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect. Please check your credentials.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBankAccount() async {
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a bank')),
      );
      return;
    }

    if (_isExistingSavings && (_accountNumberController.text.isEmpty || _ifscController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in account details')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _brokerService.saveBankAccount(
        bankName: _selectedBank!,
        isExistingAccount: _isExistingSavings,
        accountNumber: _isExistingSavings ? _accountNumberController.text : null,
        ifscCode: _isExistingSavings ? _ifscController.text : null,
      );

      // Play success animation
      _confettiController.play();
      Vibration.vibrate(duration: 200);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bank account saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Move to next step after a delay
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          _goToNextStep();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving bank account: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      await _authService.completeOnboarding();

      // Play final success animation
      _confettiController.play();
      Vibration.vibrate(duration: 500);

      // Show completion dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SuccessAnimation(
          message: 'Setup complete! Starting hands-free trading...',
          onComplete: () {
            Navigator.of(context).pop(); // Close dialog
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing setup: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goToNextStep() {
    if (_currentStep < _getSteps().length - 1) {
      setState(() => _currentStep++);
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  List<Step> _getSteps() {
    return [
      // Step 1: Broker Selection
      Step(
        title: Text('Broker Setup'),
        subtitle: Text('Connect your demat account'),
        content: _buildBrokerStep(),
        isActive: _currentStep >= 0,
      ),

      // Step 2: Bank Selection
      Step(
        title: Text('Bank Setup'),
        subtitle: Text('Link your savings account'),
        content: _buildBankStep(),
        isActive: _currentStep >= 1,
      ),

      // Step 3: KYC Verification
      Step(
        title: Text('KYC Verification'),
        subtitle: Text('Verify your identity'),
        content: _buildKycStep(),
        isActive: _currentStep >= 2,
      ),

      // Step 4: Review & Confirm
      Step(
        title: Text('Review'),
        subtitle: Text('Confirm your setup'),
        content: _buildReviewStep(),
        isActive: _currentStep >= 3,
      ),

      // Step 5: Complete
      Step(
        title: Text('Complete'),
        subtitle: Text('Start trading'),
        content: _buildCompleteStep(),
        isActive: _currentStep >= 4,
      ),
    ];
  }

  Widget _buildBrokerStep() {
    return Column(
      children: [
        Text(
          'Select your demat broker and enter API credentials',
          style: Theme.of(context).textTheme.bodyText1,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),

        DropdownButtonFormField<String>(
          value: _selectedBroker,
          decoration: InputDecoration(
            labelText: 'Select Broker',
            border: OutlineInputBorder(),
          ),
          items: _brokers.map((broker) => DropdownMenuItem(
            value: broker['name'],
            child: Text(broker['name']),
          )).toList(),
          onChanged: (value) => setState(() => _selectedBroker = value),
        ),

        if (_selectedBroker != null) ...[
          SizedBox(height: 16),
          TextFormField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: 'API Key',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _apiSecretController,
            decoration: InputDecoration(
              labelText: 'API Secret',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _testBrokerConnection,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Test & Connect Broker'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBankStep() {
    return Column(
      children: [
        Text(
          'Link your savings account for settlements',
          style: Theme.of(context).textTheme.bodyText1,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),

        DropdownButtonFormField<String>(
          value: _selectedBank,
          decoration: InputDecoration(
            labelText: 'Select Bank',
            border: OutlineInputBorder(),
          ),
          items: _banks.map((bank) => DropdownMenuItem(
            value: bank,
            child: Text(bank),
          )).toList(),
          onChanged: (value) => setState(() => _selectedBank = value),
        ),

        if (_selectedBank != null) ...[
          SizedBox(height: 16),
          Text('Account Type', style: Theme.of(context).textTheme.subtitle1),
          RadioListTile<bool>(
            title: Text('Existing Account'),
            subtitle: Text('Use my existing bank account'),
            value: true,
            groupValue: _isExistingSavings,
            onChanged: (value) => setState(() => _isExistingSavings = value!),
          ),
          RadioListTile<bool>(
            title: Text('Open New Account'),
            subtitle: Text('Help me open a new account'),
            value: false,
            groupValue: _isExistingSavings,
            onChanged: (value) => setState(() => _isExistingSavings = value!),
          ),

          if (_isExistingSavings) ...[
            SizedBox(height: 16),
            TextFormField(
              controller: _accountNumberController,
              decoration: InputDecoration(
                labelText: 'Account Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _ifscController,
              decoration: InputDecoration(
                labelText: 'IFSC Code',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],

          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveBankAccount,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Save Bank Account'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildKycStep() {
    return Column(
      children: [
        Text(
          'Verify your identity using DigiLocker',
          style: Theme.of(context).textTheme.bodyText1,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Securely fetch your Aadhaar and PAN documents from DigiLocker',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32),

        // DigiLocker Info Card
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.verified_user, size: 48, color: Colors.blue),
                SizedBox(height: 12),
                Text(
                  'DigiLocker Verification',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Government of India\'s secure document storage',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(child: Text('Aadhaar verification', style: Theme.of(context).textTheme.bodySmall)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(child: Text('PAN card verification', style: Theme.of(context).textTheme.bodySmall)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(child: Text('Instant KYC completion', style: Theme.of(context).textTheme.bodySmall)),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),

        // DigiLocker Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _initiateDigiLocker,
            icon: Icon(Icons.verified_user),
            label: Text('Verify with DigiLocker'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 16),
        
        // Skip Option
        TextButton(
          onPressed: _isLoading ? null : () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You can complete KYC verification later from settings'),
                duration: Duration(seconds: 3),
              ),
            );
            _goToNextStep();
          },
          child: Text('Skip for now'),
        ),
      ],
    );
  }

  Future<void> _initiateDigiLocker() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await _authService.getValidToken();
      if (token == null) {
        throw Exception('Please login first');
      }

      // Call backend to get authorization URL
      final response = await http.post(
        Uri.parse('${kBackendBaseUrl}/api/kyc/digilocker/authorize'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final authUrl = data['authorization_url'];
          
          // Open DigiLocker OAuth in browser/webview
          if (await canLaunchUrl(Uri.parse(authUrl))) {
            await launchUrl(
              Uri.parse(authUrl),
              mode: LaunchMode.externalApplication,
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Redirecting to DigiLocker...'),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            throw Exception('Could not open DigiLocker');
          }
        } else {
          throw Exception(data['error'] ?? 'Failed to initiate DigiLocker');
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to initiate DigiLocker');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildReviewStep() {
    return Column(
      children: [
        Text(
          'Review your setup before completing',
          style: Theme.of(context).textTheme.bodyText1,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),

        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Broker: ${_selectedBroker ?? "Not selected"}'),
                Text('Bank: ${_selectedBank ?? "Not selected"}'),
                Text('KYC: Completed'),
              ],
            ),
          ),
        ),

        SizedBox(height: 20),
        Text(
          'By completing setup, you agree to start automated trading based on your selections.',
          style: Theme.of(context).textTheme.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCompleteStep() {
    return Column(
      children: [
        Icon(Icons.check_circle, size: 64, color: Colors.green),
        SizedBox(height: 16),
        Text(
          'Setup Complete!',
          style: Theme.of(context).textTheme.headline5,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Starting hands-free trading...',
          style: Theme.of(context).textTheme.bodyText1,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _completeOnboarding,
          child: _isLoading
              ? CircularProgressIndicator(color: Colors.white)
              : Text('Start Trading'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Setup'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Stack(
        children: [
          Stepper(
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < _getSteps().length - 1) {
                _goToNextStep();
              } else {
                _completeOnboarding();
              }
            },
            onStepCancel: _goToPreviousStep,
            steps: _getSteps(),
            controlsBuilder: (context, details) {
              return Row(
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text('Back'),
                    ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _currentStep == _getSteps().length - 1
                        ? _completeOnboarding
                        : details.onStepContinue,
                    child: Text(_currentStep == _getSteps().length - 1 ? 'Complete Setup' : 'Next'),
                  ),
                ],
              );
            },
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: LottieLoading(message: 'Processing...'),
              ),
            ),
        ],
      ),
    );
  }
}