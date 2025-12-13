import 'package:flutter/material.dart';

class BacktestResultsTable extends StatelessWidget {
  final Map<String, dynamic> backtestResult;

  const BacktestResultsTable({
    super.key,
    required this.backtestResult,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final type = backtestResult['type'] ?? 'unknown';
    
    // Backend returns data directly, not nested under 'result'
    // Check if data is at root level or nested
    Map<String, dynamic>? result;
    if (backtestResult.containsKey('result')) {
      result = backtestResult['result'] as Map<String, dynamic>?;
    } else {
      // Data is at root level - check if it has backtest fields
      if (backtestResult.containsKey('total_trades') || 
          backtestResult.containsKey('win_rate') ||
          backtestResult.containsKey('total_pnl')) {
        result = backtestResult;
      }
    }
    
    if (result == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade500, size: 32),
            const SizedBox(height: 8),
            Text(
              'No results available',
              style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 4),
            Text(
              'Run a backtest to see results here',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final totalTrades = result['total_trades'] as int? ?? 0;
    final winRate = (result['win_rate'] as num?)?.toDouble() ?? 0.0;
    final totalPnl = (result['total_pnl'] as num?)?.toDouble() ?? 0.0;
    final maxDrawdown = (result['max_drawdown'] as num?)?.toDouble() ?? 0.0;
    final sharpeRatio = (result['sharpe_ratio'] as num?)?.toDouble() ?? 0.0;
    final avgWin = (result['avg_win'] as num?)?.toDouble() ?? 0.0;
    final avgLoss = (result['avg_loss'] as num?)?.toDouble() ?? 0.0;
    final winningTrades = (result['winning_trades'] as int?) ?? 0;
    final losingTrades = (result['losing_trades'] as int?) ?? 0;
    final profitFactor = (result['profit_factor'] as num?)?.toDouble() ?? 0.0;
    final message = result['message'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primary.withOpacity(0.2),
                colors.secondary.withOpacity(0.1),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              Icon(
                type == 'realistic' ? Icons.trending_up : Icons.warning_amber,
                color: type == 'realistic' ? Colors.blueAccent : Colors.orangeAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                type == 'realistic' ? 'Realistic Backtest Results' : 'Edge Test Results',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Summary Cards Row
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                'Total P&L',
                '₹${totalPnl.toStringAsFixed(2)}',
                totalPnl >= 0 ? Colors.green : Colors.red,
                totalPnl >= 0 ? Icons.trending_up : Icons.trending_down,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                context,
                'Win Rate',
                '${winRate.toStringAsFixed(1)}%',
                winRate >= 60 ? Colors.green : (winRate >= 40 ? Colors.orange : Colors.red),
                Icons.percent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                context,
                'Total Trades',
                '$totalTrades',
                Colors.blueAccent,
                Icons.swap_horiz,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Detailed Metrics Table
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant.withOpacity(0.5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Metric',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: colors.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Value',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: colors.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Table Rows
              _buildTableRow(context, 'Winning Trades', '$winningTrades', Colors.greenAccent),
              _buildTableRow(context, 'Losing Trades', '$losingTrades', Colors.redAccent),
              _buildTableRow(context, 'Average Win', '₹${avgWin.toStringAsFixed(2)}', Colors.greenAccent),
              _buildTableRow(context, 'Average Loss', '₹${avgLoss.toStringAsFixed(2)}', Colors.redAccent),
              _buildTableRow(context, 'Profit Factor', profitFactor.toStringAsFixed(2), 
                  profitFactor >= 2.0 ? Colors.greenAccent : (profitFactor >= 1.0 ? Colors.orangeAccent : Colors.redAccent)),
              _buildTableRow(context, 'Max Drawdown', '₹${maxDrawdown.toStringAsFixed(2)}', Colors.orangeAccent),
              _buildTableRow(context, 'Sharpe Ratio', sharpeRatio.toStringAsFixed(2), 
                  sharpeRatio >= 1.5 ? Colors.greenAccent : (sharpeRatio >= 1.0 ? Colors.orangeAccent : Colors.redAccent)),
              
              // Risk/Reward Ratio
              if (avgLoss.abs() > 0) ...[
                _buildTableRow(
                  context,
                  'Risk/Reward Ratio',
                  '1:${(avgWin / avgLoss.abs()).toStringAsFixed(2)}',
                  Colors.blueAccent,
                ),
              ],
            ],
          ),
        ),
        
        // Message/Notes
        if (message != null && message.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blueAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurface.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Performance Rating
        const SizedBox(height: 12),
        _buildPerformanceRating(context, winRate, sharpeRatio, profitFactor),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, String label, String value, Color? valueColor) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.outline.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurface.withOpacity(0.9),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRating(
    BuildContext context,
    double winRate,
    double sharpeRatio,
    double profitFactor,
  ) {
    final colors = Theme.of(context).colorScheme;
    
    // Calculate overall rating (0-5 stars)
    int stars = 0;
    if (winRate >= 50) stars++;
    if (winRate >= 60) stars++;
    if (sharpeRatio >= 1.0) stars++;
    if (sharpeRatio >= 1.5) stars++;
    if (profitFactor >= 1.5) stars++;
    
    String rating;
    Color ratingColor;
    
    if (stars >= 4) {
      rating = 'Excellent';
      ratingColor = Colors.green;
    } else if (stars >= 3) {
      rating = 'Good';
      ratingColor = Colors.lightGreen;
    } else if (stars >= 2) {
      rating = 'Fair';
      ratingColor = Colors.orange;
    } else {
      rating = 'Needs Improvement';
      ratingColor = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ratingColor.withOpacity(0.2),
            ratingColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ratingColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Performance Rating: ',
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurface.withOpacity(0.8),
            ),
          ),
          Text(
            rating,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: ratingColor,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < stars ? Icons.star : Icons.star_border,
                color: ratingColor,
                size: 16,
              );
            }),
          ),
        ],
      ),
    );
  }
}


