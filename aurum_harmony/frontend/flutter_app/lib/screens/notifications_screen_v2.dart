import 'package:flutter/material.dart';
import 'dart:math' as math;

class NotificationsScreenV2 extends StatefulWidget {
  const NotificationsScreenV2({super.key});

  @override
  State<NotificationsScreenV2> createState() => _NotificationsScreenV2State();
}

class _NotificationsScreenV2State extends State<NotificationsScreenV2> {
  // Mock notifications with categories and status
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'title': 'Trade Executed',
      'message': 'NIFTY50 BUY order filled at ₹21,450',
      'category': 'trade',
      'severity': 'success',
      'value': 0.85, // For meter dial
      'read': false,
      'timestamp': '2 min ago',
    },
    {
      'id': 2,
      'title': 'Risk Alert',
      'message': 'Portfolio volatility increased to 18%',
      'category': 'risk',
      'severity': 'warning',
      'value': 0.72,
      'read': false,
      'timestamp': '15 min ago',
    },
    {
      'id': 3,
      'title': 'AI Signal',
      'message': 'New bullish signal detected for BANKNIFTY',
      'category': 'signal',
      'severity': 'info',
      'value': 0.92,
      'read': false,
      'timestamp': '1 hour ago',
    },
    {
      'id': 4,
      'title': 'Profit Target',
      'message': 'Position reached 5% profit target',
      'category': 'profit',
      'severity': 'success',
      'value': 0.95,
      'read': true,
      'timestamp': '3 hours ago',
    },
    {
      'id': 5,
      'title': 'System Update',
      'message': 'Predictive AI engine calibrated',
      'category': 'system',
      'severity': 'info',
      'value': 0.88,
      'read': true,
      'timestamp': 'Yesterday',
    },
  ];

  void _markAsRead(int id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notifications[index]['read'] = true;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked as read: ${_notifications.firstWhere((n) => n['id'] == id)['title']}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'trade':
        return Colors.blue;
      case 'risk':
        return Colors.orange;
      case 'signal':
        return Colors.purple;
      case 'profit':
        return Colors.green;
      case 'system':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'trade':
        return Icons.swap_horiz;
      case 'risk':
        return Icons.warning_amber_rounded;
      case 'signal':
        return Icons.trending_up;
      case 'profit':
        return Icons.monetization_on;
      case 'system':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = _notifications.where((n) => !n['read']).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Badge(
                  label: Text('$unreadCount'),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.notifications_active),
                ),
              ),
            ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final category = notification['category'] as String;
          final categoryColor = _getCategoryColor(category);
          final isRead = notification['read'] as bool;
          final value = notification['value'] as double;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: isRead ? 1 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isRead ? Colors.transparent : categoryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () => _markAsRead(notification['id']),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Color Meter Dial
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background circle
                            CustomPaint(
                              size: const Size(80, 80),
                              painter: _MeterDialPainter(
                                value: value,
                                color: categoryColor,
                                backgroundColor: theme.colorScheme.surfaceVariant,
                              ),
                            ),
                            // Icon in center
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getCategoryIcon(category),
                                color: categoryColor,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification['title'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                      color: isRead ? theme.colorScheme.onSurface.withOpacity(0.7) : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: categoryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification['message'],
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  notification['timestamp'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                                const Spacer(),
                                Chip(
                                  label: Text(
                                    category.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: categoryColor,
                                    ),
                                  ),
                                  backgroundColor: categoryColor.withOpacity(0.1),
                                  side: BorderSide.none,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom painter for the meter dial
class _MeterDialPainter extends CustomPainter {
  final double value; // 0.0 to 1.0
  final Color color;
  final Color backgroundColor;

  _MeterDialPainter({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 6.0;

    // Draw background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    // Draw value arc
    final valuePaint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withOpacity(0.3),
          color,
        ],
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + (2 * math.pi * value),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      sweepAngle,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(_MeterDialPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

