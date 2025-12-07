import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../services/db_admin_service.dart';
import '../services/auth_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _users = [];
  
  // Database admin state
  List<String> _tables = [];
  String? _selectedTable;
  List<Map<String, dynamic>> _tableData = [];
  List<Map<String, dynamic>> _tableColumns = [];
  Map<String, dynamic>? _dbStats;
  bool _loadingTables = false;
  bool _loadingTableData = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
    _checkAdminAndLoadDb();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAndLoadDb() async {
    final isAdmin = await AuthService.isAdmin();
    if (isAdmin) {
      _loadTables();
      _loadDatabaseStats();
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }
      final resp = await http.get(
        Uri.parse('$kBackendBaseUrl/api/admin/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          setState(() {
            _users = List<Map<String, dynamic>>.from(data['users'] ?? []);
          });
        } else {
          throw Exception(data['error'] ?? 'Failed to load users');
        }
      } else {
        final error = jsonDecode(resp.body) as Map<String, dynamic>;
        throw Exception(error['error'] ?? 'Error ${resp.statusCode}');
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

  Future<void> _loadTables() async {
    setState(() {
      _loadingTables = true;
    });
    try {
      final tables = await DbAdminService.getTables();
      setState(() {
        _tables = tables;
        _loadingTables = false;
      });
    } catch (e) {
      setState(() {
        _loadingTables = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tables: $e')),
        );
      }
    }
  }

  Future<void> _loadTableData(String tableName) async {
    setState(() {
      _loadingTableData = true;
      _selectedTable = tableName;
    });
    try {
      final result = await DbAdminService.getTableData(tableName);
      final columns = await DbAdminService.getTableColumns(tableName);
      setState(() {
        _tableData = List<Map<String, dynamic>>.from(result['data'] ?? []);
        _tableColumns = columns;
        _loadingTableData = false;
      });
    } catch (e) {
      setState(() {
        _loadingTableData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading table data: $e')),
        );
      }
    }
  }

  Future<void> _loadDatabaseStats() async {
    try {
      final stats = await DbAdminService.getDatabaseStats();
      setState(() {
        _dbStats = stats;
      });
    } catch (e) {
      // Silently fail for stats
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.storage), text: 'Database'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildDatabaseTab(),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
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
              Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadUsers, child: const Text('Retry')),
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
              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              Text('No users found', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Seed users via the backend admin API.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12), textAlign: TextAlign.center),
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
                backgroundColor: (u['status'] == 'active' ? Colors.green : Colors.orange).withOpacity(0.2),
                child: Icon(
                  u['status'] == 'active' ? Icons.person : Icons.person_outline,
                  color: u['status'] == 'active' ? Colors.greenAccent : Colors.orangeAccent,
                ),
              ),
              title: Text(u['user_id'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Tier: ${u['tier']} • Capital: ₹${u['capital']}'),
                  const SizedBox(height: 2),
                  Text('Max trades/day: ${u['max_trades']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: (u['status'] == 'active' ? Colors.green : Colors.orange).withOpacity(0.15),
                  border: Border.all(color: u['status'] == 'active' ? Colors.greenAccent : Colors.orangeAccent),
                ),
                child: Text(
                  (u['status'] ?? '').toString().toUpperCase(),
                  style: TextStyle(
                    color: u['status'] == 'active' ? Colors.greenAccent : Colors.orangeAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User: ${u['user_id']}')));
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDatabaseTab() {
    return Column(
      children: [
        // Database Stats Card
        if (_dbStats != null)
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Database Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatItem('Users', '${_dbStats!['users'] ?? 0}')),
                      Expanded(child: _buildStatItem('Active', '${_dbStats!['active_users'] ?? 0}')),
                      Expanded(child: _buildStatItem('Admins', '${_dbStats!['admin_users'] ?? 0}')),
                    ],
                  ),
                  if (_dbStats!['database_size_mb'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Database Size: ${_dbStats!['database_size_mb']} MB', style: TextStyle(color: Colors.grey.shade600)),
                    ),
                ],
              ),
            ),
          ),
        // Tables List
        Expanded(
          child: Row(
            children: [
              // Table List Sidebar
              Container(
                width: 200,
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text('Tables', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: _loadTables,
                            tooltip: 'Refresh',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _loadingTables
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              itemCount: _tables.length,
                              itemBuilder: (context, index) {
                                final table = _tables[index];
                                final isSelected = _selectedTable == table;
                                return ListTile(
                                  selected: isSelected,
                                  title: Text(table),
                                  onTap: () => _loadTableData(table),
                                  leading: const Icon(Icons.table_chart, size: 20),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              // Table Data View
              Expanded(
                child: _selectedTable == null
                    ? const Center(child: Text('Select a table to view data'))
                    : _loadingTableData
                        ? const Center(child: CircularProgressIndicator())
                        : _tableData.isEmpty
                            ? const Center(child: Text('No data in this table'))
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    columns: _tableColumns.map((col) {
                                      return DataColumn(
                                        label: Text(col['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      );
                                    }).toList(),
                                    rows: _tableData.map((row) {
                                      return DataRow(
                                        cells: _tableColumns.map((col) {
                                          final value = row[col['name']];
                                          return DataCell(Text(value?.toString() ?? 'null', style: const TextStyle(fontSize: 12)));
                                        }).toList(),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}


