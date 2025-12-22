import 'package:flutter/material.dart';

/// Tier Card Widget - Displays user tier based on internal_capital
/// 
/// Tiers (from UserTierManager):
/// - Bronze: ₹5,000+ (30% fee, 1 account)
/// - Silver: ₹50,000+ (20% fee, 2 accounts)
/// - Gold: ₹1,00,000+ (12.5% fee, 6 accounts)
class TierCard extends StatelessWidget {
  final double internalCapital;
  
  const TierCard({
    Key? key,
    required this.internalCapital,
  }) : super(key: key);

  /// Calculate tier from internal capital (matches backend UserTierManager logic)
  Map<String, dynamic> _getTierInfo() {
    if (internalCapital >= 100000.0) {
      return {
        'name': 'Gold',
        'displayName': 'Gold Glide',
        'minCapital': 100000.0,
        'feeRate': 0.125,
        'maxAccounts': 6,
        'color': const Color(0xFFFFD700), // Gold
        'icon': Icons.stars,
      };
    } else if (internalCapital >= 50000.0) {
      return {
        'name': 'Silver',
        'displayName': 'Silver Surge',
        'minCapital': 50000.0,
        'feeRate': 0.20,
        'maxAccounts': 2,
        'color': const Color(0xFFC0C0C0), // Silver
        'icon': Icons.workspace_premium,
      };
    } else {
      return {
        'name': 'Bronze',
        'displayName': 'Bronze Beat',
        'minCapital': 5000.0,
        'feeRate': 0.30,
        'maxAccounts': 1,
        'color': const Color(0xFFCD7F32), // Bronze
        'icon': Icons.emoji_events,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierInfo = _getTierInfo();
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    colors.surface,
                    colors.surfaceVariant,
                  ]
                : [
                    tierInfo['color'] as Color,
                    (tierInfo['color'] as Color).withOpacity(0.7),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tier name and icon
            Row(
              children: [
                Icon(
                  tierInfo['icon'] as IconData,
                  color: isDark ? tierInfo['color'] as Color : Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  tierInfo['displayName'] as String,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? tierInfo['color'] as Color : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Capital display
            Text(
              'Capital: ₹${internalCapital.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? colors.onSurface : Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            
            // Fee rate
            Text(
              'Fee Rate: ${((tierInfo['feeRate'] as double) * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? colors.onSurface.withOpacity(0.8) : Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 4),
            
            // Max accounts
            Text(
              'Max Accounts: ${tierInfo['maxAccounts'] as int}',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? colors.onSurface.withOpacity(0.8) : Colors.white.withOpacity(0.9),
              ),
            ),
            
            // Progress to next tier (if not Gold)
            if (tierInfo['name'] != 'Gold') ...[
              const SizedBox(height: 16),
              _buildNextTierProgress(tierInfo, colors, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNextTierProgress(
    Map<String, dynamic> currentTier,
    ColorScheme colors,
    bool isDark,
  ) {
    double nextTierMin = 0.0;
    String nextTierName = '';
    
    if (currentTier['name'] == 'Bronze') {
      nextTierMin = 50000.0;
      nextTierName = 'Silver';
    } else if (currentTier['name'] == 'Silver') {
      nextTierMin = 100000.0;
      nextTierName = 'Gold';
    }
    
    if (nextTierMin == 0.0) return const SizedBox.shrink();
    
    final progress = (internalCapital / nextTierMin).clamp(0.0, 1.0);
    final remaining = nextTierMin - internalCapital;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress to $nextTierName:',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? colors.onSurface.withOpacity(0.7) : Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: isDark 
              ? colors.surfaceVariant 
              : Colors.white.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? colors.primary : Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${remaining.toStringAsFixed(0)} to unlock',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? colors.onSurface.withOpacity(0.6) : Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

