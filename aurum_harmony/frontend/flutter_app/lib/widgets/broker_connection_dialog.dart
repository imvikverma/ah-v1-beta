import 'package:flutter/material.dart';
import '../services/broker_service.dart';

/// Dialog for connecting to a broker (HDFC Sky, Kotak Neo, etc.)
class BrokerConnectionDialog extends StatefulWidget {
  final String? initialBroker;
  
  const BrokerConnectionDialog({
    super.key,
    this.initialBroker,
  });

  @override
  State<BrokerConnectionDialog> createState() => _BrokerConnectionDialogState();
}

class _BrokerConnectionDialogState extends State<BrokerConnectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _apiSecretController = TextEditingController();
  final _tokenIdController = TextEditingController();
  
  String _selectedBroker = 'HDFC_SKY';
  bool _obscureSecret = true;
  bool _isLoading = false;
  bool _showTokenId = false;

  final List<Map<String, String>> _brokers = [
    {'name': 'HDFC_SKY', 'display': 'HDFC Sky'},
    {'name': 'KOTAK_NEO', 'display': 'Kotak Neo'},
    {'name': 'MANGAL_KESHAV', 'display': 'Mangal Keshav'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialBroker != null) {
      _selectedBroker = widget.initialBroker!;
    }
    _updateTokenIdVisibility();
  }

  void _updateTokenIdVisibility() {
    // HDFC Sky might need token_id, others don't
    setState(() {
      _showTokenId = _selectedBroker == 'HDFC_SKY';
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    _tokenIdController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await BrokerService.connectBroker(
        brokerName: _selectedBroker,
        apiKey: _apiKeyController.text.trim(),
        apiSecret: _apiSecretController.text.trim(),
        tokenId: _tokenIdController.text.trim().isEmpty 
            ? null 
            : _tokenIdController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getBrokerDisplayName(_selectedBroker)} connected successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 12),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText(
              'Error: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 12),
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

  String _getBrokerDisplayName(String brokerName) {
    return _brokers.firstWhere(
      (b) => b['name'] == brokerName,
      orElse: () => {'display': brokerName},
    )['display']!;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: const Color(0xff11172b),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.account_balance, color: colors.primary),
                    const SizedBox(width: 12),
                    const Text(
                      'Connect Broker',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Broker Selection
                DropdownButtonFormField<String>(
                  value: _selectedBroker,
                  decoration: InputDecoration(
                    labelText: 'Select Broker',
                    prefixIcon: const Icon(Icons.account_balance),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                  ),
                  items: _brokers.map((broker) {
                    return DropdownMenuItem<String>(
                      value: broker['name'],
                      child: Text(broker['display']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedBroker = value;
                      });
                      _updateTokenIdVisibility();
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Info message for HDFC Sky
                if (_selectedBroker == 'HDFC_SKY')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade700),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade300, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'HDFC Sky uses manual entry. Get your API Key and Secret from developer.hdfcsky.com',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade200,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_selectedBroker == 'HDFC_SKY') const SizedBox(height: 16),

                // API Key Field
                TextFormField(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: 'Enter your broker API key',
                    prefixIcon: const Icon(Icons.vpn_key),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your API Key';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // API Secret Field
                TextFormField(
                  controller: _apiSecretController,
                  obscureText: _obscureSecret,
                  decoration: InputDecoration(
                    labelText: 'API Secret',
                    hintText: 'Enter your broker API secret',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureSecret
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureSecret = !_obscureSecret;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your API Secret';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Token ID Field (for HDFC Sky)
                if (_showTokenId)
                  TextFormField(
                    controller: _tokenIdController,
                    decoration: InputDecoration(
                      labelText: 'Request Token (Optional)',
                      hintText: 'Enter request token if required',
                      helperText: 'Some HDFC Sky accounts require a request token',
                      prefixIcon: const Icon(Icons.token),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade900,
                    ),
                  ),
                if (_showTokenId) const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleConnect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : const Text(
                                'Connect',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

