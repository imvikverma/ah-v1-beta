import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await http.get(Uri.parse('$kAdminBaseUrl/admin/users'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List<dynamic>;
        setState(() {
          _users = data.cast<Map<String, dynamic>>();
        });
      } else {
        setState(() {
          _error = 'Error ${resp.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUsers,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 16),
              Text(
                'No users found',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Seed users via the backend admin API.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final u = _users[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (u['status'] == 'active'
                        ? Colors.green
                        : Colors.orange)
                    .withOpacity(0.2),
                child: Icon(
                  u['status'] == 'active'
                      ? Icons.person
                      : Icons.person_outline,
                  color: u['status'] == 'active'
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                ),
              ),
              title: Text(
                u['user_id'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Tier: ${u['tier']} • Capital: ₹${u['capital']}',
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Max trades/day: ${u['max_trades']}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: (u['status'] == 'active'
                          ? Colors.green
                          : Colors.orange)
                      .withOpacity(0.15),
                  border: Border.all(
                    color: u['status'] == 'active'
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                ),
                child: Text(
                  (u['status'] ?? '').toString().toUpperCase(),
                  style: TextStyle(
                    color: u['status'] == 'active'
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              onTap: () {
                // TODO: Navigate to user detail screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User: ${u['user_id']}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

