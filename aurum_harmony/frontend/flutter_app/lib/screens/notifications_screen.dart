import 'package:flutter/material.dart';
import '../utils/theme_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  String _filter = 'all'; // 'all', 'trade', 'risk', 'system'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // TODO: Connect to /notifications endpoint when available
    // For now, show placeholder data
    setState(() {
      _notifications = [
        {
          'id': '1',
          'type': 'trade',
          'title': 'Trade Executed',
          'message': 'Bought 10 NIFTY50 @ ₹24,500',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
          'read': false,
        },
        {
          'id': '2',
          'type': 'risk',
          'title': 'Risk Alert',
          'message': 'Drawdown approaching limit (85%)',
          'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
          'read': false,
        },
        {
          'id': '3',
          'type': 'system',
          'title': 'System Status',
          'message': 'Orchestrator running normally',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'read': true,
        },
        {
          'id': '4',
          'type': 'trade',
          'title': 'Settlement Complete',
          'message': 'Daily settlement processed for user001',
          'timestamp': DateTime.now().subtract(const Duration(days: 1)),
          'read': true,
        },
      ];
    });
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_filter == 'all') return _notifications;
    return _notifications.where((n) => n['type'] == _filter).toList();
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'trade':
        return Icons.swap_horiz;
      case 'risk':
        return Icons.warning;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    final colors = Theme.of(context).colorScheme;
    switch (type) {
      case 'trade':
        return colors.primary; // Use theme primary (saffron) for trades
      case 'risk':
        return ThemeColors.warning(context);
      case 'system':
        return ThemeColors.info(context);
      default:
        return colors.onSurface.withOpacity(0.6);
    }
  }

  String _formatTimestamp(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All', colors),
                const SizedBox(width: 8),
                _buildFilterChip('trade', 'Trades', colors),
                const SizedBox(width: 8),
                _buildFilterChip('risk', 'Risk', colors),
                const SizedBox(width: 8),
                _buildFilterChip('system', 'System', colors),
              ],
            ),
          ),
        ),
        // Notifications List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadNotifications,
            child: _filteredNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: colors.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: TextStyle(
                            color: colors.onSurface.withOpacity(0.6),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Alerts will appear here when trades execute,\n'
                          'risk limits are breached, or system events occur.',
                          style: TextStyle(
                            color: colors.onSurface.withOpacity(0.5),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notif = _filteredNotifications[index];
                      final isUnread = !(notif['read'] as bool? ?? false);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        color: isUnread
                            ? colors.surface.withOpacity(0.5)
                            : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getColorForType(
                              notif['type'] as String,
                            ).withOpacity(0.2),
                            child: Icon(
                              _getIconForType(notif['type'] as String),
                              color: _getColorForType(notif['type'] as String),
                            ),
                          ),
                          title: Text(
                            notif['title'] as String,
                            style: TextStyle(
                              fontWeight: isUnread
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(notif['message'] as String),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimestamp(
                                  notif['timestamp'] as DateTime,
                                ),
                                style: TextStyle(
                                  color: colors.onSurface.withOpacity(0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              IconButton(
                                icon: Icon(
                                  isUnread ? Icons.close : Icons.check_circle_outline,
                                  size: 20,
                                ),
                                tooltip: isUnread ? 'Mark as read' : 'Read',
                                onPressed: () {
                                  setState(() {
                                    notif['read'] = true;
                                  });
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            // Mark as read
                            setState(() {
                              notif['read'] = true;
                            });
                            // Show notification details
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(notif['message'] as String),
                                duration: const Duration(seconds: 3),
                                action: SnackBarAction(
                                  label: 'Dismiss',
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String value,
    String label,
    ColorScheme colors,
  ) {
    final isSelected = _filter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected) ...[
            Icon(
              Icons.check,
              size: 16,
              color: isSelected ? colors.primary : colors.onSurface,
            ),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = value;
        });
      },
      backgroundColor: isSelected 
          ? colors.primary.withOpacity(isDark ? 0.3 : 0.2)
          : colors.surface,
      selectedColor: colors.primary.withOpacity(isDark ? 0.3 : 0.2),
      checkmarkColor: colors.primary,
      side: BorderSide(
        color: isSelected 
            ? colors.primary 
            : (isDark ? colors.outline : colors.outline.withOpacity(0.5)),
        width: isSelected ? 1.5 : 1,
      ),
      labelStyle: TextStyle(
        color: isSelected 
            ? colors.primary 
            : colors.onSurface.withOpacity(isDark ? 0.9 : 0.7),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

