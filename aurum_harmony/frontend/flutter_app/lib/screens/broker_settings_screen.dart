import 'package:flutter/material.dart';
import '../services/broker_service.dart';
import '../widgets/broker_connection_dialog.dart';

/// Screen for managing broker connections
class BrokerSettingsScreen extends StatefulWidget {
  const BrokerSettingsScreen({super.key});

  @override
  State<BrokerSettingsScreen> createState() => _BrokerSettingsScreenState();
}

class _BrokerSettingsScreenState extends State<BrokerSettingsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _connectedBrokers = [];
  List<String> _availableBrokers = [];

  @override
  void initState() {
    super.initState();
    _loadBrokers();
  }

  Future<void> _loadBrokers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await BrokerService.getBrokers();
      setState(() {
        _connectedBrokers = List<Map<String, dynamic>>.from(
          data['brokers'] ?? [],
        );
        _availableBrokers = List<String>.from(
          data['available_brokers'] ?? [],
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText(
              'Error loading brokers: $e',
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

  Future<void> _showConnectDialog({String? broker}) async {
    final result = await showDialog(
      context: context,
      builder: (context) => BrokerConnectionDialog(initialBroker: broker),
    );
    
    if (result == true) {
      _loadBrokers(); // Refresh list
    }
  }

  Future<void> _handleDisconnect(String brokerName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff11172b),
        title: const Text('Disconnect Broker'),
        content: Text('Are you sure you want to disconnect $brokerName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await BrokerService.disconnectBroker(brokerName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$brokerName disconnected successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 12),
          ),
        );
        _loadBrokers(); // Refresh list
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
    }
  }

  String _getBrokerDisplayName(String brokerName) {
    final names = {
      'HDFC_SKY': 'HDFC Sky',
      'KOTAK_NEO': 'Kotak Neo',
      'MANGAL_KESHAV': 'Mangal Keshav',
    };
    return names[brokerName] ?? brokerName;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: const Color(0xff050816),
      appBar: AppBar(
        title: const Text('Broker Settings'),
        backgroundColor: const Color(0xff11172b),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBrokers,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(Icons.account_balance, color: colors.primary),
                        const SizedBox(width: 12),
                        const Text(
                          'Connected Brokers',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _showConnectDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Connect'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Connected Brokers List
                    if (_connectedBrokers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance_outlined,
                              size: 64,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No brokers connected',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Connect a broker to start trading',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _showConnectDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Connect Broker'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._connectedBrokers.map((broker) {
                        final brokerName = broker['broker_name'] as String? ?? '';
                        final isActive = broker['is_active'] as bool? ?? false;
                        
                        return Card(
                          color: const Color(0xff11172b),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isActive
                                  ? Colors.green.shade700
                                  : Colors.grey.shade700,
                              child: Icon(
                                Icons.account_balance,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              _getBrokerDisplayName(brokerName),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              isActive ? 'Connected' : 'Disconnected',
                              style: TextStyle(
                                color: isActive
                                    ? Colors.green.shade300
                                    : Colors.grey.shade400,
                              ),
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: const Row(
                                    children: [
                                      Icon(Icons.refresh, size: 20),
                                      SizedBox(width: 8),
                                      Text('Refresh Status'),
                                    ],
                                  ),
                                  onTap: () async {
                                    await Future.delayed(
                                      const Duration(milliseconds: 100),
                                    );
                                    try {
                                      await BrokerService.getBrokerStatus(brokerName);
                                      _loadBrokers();
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            duration: const Duration(seconds: 12),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                PopupMenuItem(
                                  child: const Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Reconnect'),
                                    ],
                                  ),
                                  onTap: () async {
                                    await Future.delayed(
                                      const Duration(milliseconds: 100),
                                    );
                                    _showConnectDialog(broker: brokerName);
                                  },
                                ),
                                PopupMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(Icons.link_off, size: 20, color: Colors.red),
                                      const SizedBox(width: 8),
                                      const Text('Disconnect'),
                                    ],
                                  ),
                                  onTap: () async {
                                    await Future.delayed(
                                      const Duration(milliseconds: 100),
                                    );
                                    _handleDisconnect(brokerName);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 24),

                    // Available Brokers Section
                    const Text(
                      'Available Brokers',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._availableBrokers.map((broker) {
                      final isConnected = _connectedBrokers.any(
                        (b) => b['broker_name'] == broker && b['is_active'] == true,
                      );
                      
                      return Card(
                        color: const Color(0xff11172b),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.account_balance_outlined,
                            color: isConnected
                                ? Colors.green.shade300
                                : Colors.grey.shade400,
                          ),
                          title: Text(_getBrokerDisplayName(broker)),
                          subtitle: Text(
                            isConnected ? 'Already connected' : 'Not connected',
                          ),
                          trailing: isConnected
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : ElevatedButton(
                                  onPressed: () => _showConnectDialog(broker: broker),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.primary,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text('Connect'),
                                ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }
}

