import 'package:flutter/material.dart';

class PositionProgressCard extends StatelessWidget {
  final Map<String, dynamic> position;
  final VoidCallback? onClose;

  const PositionProgressCard({
    super.key,
    required this.position,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    // Extract position data
    final symbol = position['symbol'] as String? ?? 'N/A';
    final side = position['side'] as String? ?? 'BUY';
    final quantity = (position['quantity'] as num?)?.toDouble() ?? 0.0;
    final avgPrice = (position['avg_price'] as num?)?.toDouble() ?? 0.0;
    final currentPrice = (position['current_price'] as num?)?.toDouble() ?? avgPrice;
    final unrealizedPnl = (position['unrealized_pnl'] as num?)?.toDouble() ?? 0.0;
    final pnlPercent = avgPrice > 0 ? ((currentPrice - avgPrice) / avgPrice * 100) : 0.0;
    
    // Calculate target and stop loss (dummy values for now, should come from backend)
    final target = side == 'BUY' ? avgPrice * 1.02 : avgPrice * 0.98;
    final stopLoss = side == 'BUY' ? avgPrice * 0.98 : avgPrice * 1.02;
    
    // Calculate progress (0 to 1) - from entry to current
    final range = side == 'BUY' ? (target - stopLoss) : (stopLoss - target);
    final progress = range > 0 
        ? ((currentPrice - stopLoss) / range).clamp(0.0, 1.0)
        : 0.5;
    
    final isProfit = unrealizedPnl >= 0;
    final isBuy = side == 'BUY';
    
    // Time in trade (dummy for now)
    final openedAt = position['opened_at'] as String?;
    String timeInTrade = 'Today';
    if (openedAt != null) {
      try {
        final openTime = DateTime.parse(openedAt);
        final duration = DateTime.now().difference(openTime);
        if (duration.inDays > 0) {
          timeInTrade = '${duration.inDays}d ${duration.inHours % 24}h';
        } else if (duration.inHours > 0) {
          timeInTrade = '${duration.inHours}h ${duration.inMinutes % 60}m';
        } else {
          timeInTrade = '${duration.inMinutes}m';
        }
      } catch (e) {
        timeInTrade = 'Today';
      }
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Symbol & Side Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isBuy ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBuy ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: isBuy ? Colors.greenAccent : Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        side,
                        style: TextStyle(
                          color: isBuy ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        symbol,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Qty: ${quantity.abs().toStringAsFixed(0)} • $timeInTrade',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // P&L Display
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${unrealizedPnl.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isProfit ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isProfit ? Colors.green : Colors.red).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${pnlPercent >= 0 ? '+' : ''}${pnlPercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: isProfit ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Price Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Labels Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPriceLabel('Stop Loss', stopLoss, Colors.redAccent),
                    _buildPriceLabel('Entry', avgPrice, Colors.blueAccent),
                    _buildPriceLabel('Target', target, Colors.greenAccent),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Progress Bar
                Stack(
                  children: [
                    // Background bar
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0.3),
                            Colors.orange.withOpacity(0.3),
                            Colors.green.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                    // Progress indicator
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: [
                              Colors.red,
                              Colors.orange,
                              Colors.green,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Current price marker
                    Positioned(
                      left: (MediaQuery.of(context).size.width - 80) * progress,
                      top: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isProfit ? Colors.greenAccent : Colors.orangeAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: (isProfit ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Current Price Display
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isProfit ? Colors.greenAccent : Colors.orangeAccent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 16,
                          color: isProfit ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Current: ₹${currentPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isProfit ? Colors.greenAccent : Colors.orangeAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Close Button
            if (onClose != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Close Position'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPriceLabel(String label, double price, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '₹${price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 11,
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

