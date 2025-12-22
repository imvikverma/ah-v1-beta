import 'package:flutter/material.dart';

class NetworkLogo extends StatelessWidget {
  final String providerName;
  final double size;
  final bool showBorder;

  const NetworkLogo({
    Key? key,
    required this.providerName,
    this.size = 40,
    this.showBorder = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Map provider names to their display properties
    final providerData = _getProviderData(providerName);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: providerData['backgroundColor'],
        shape: BoxShape.circle,
        border: showBorder ? Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          providerData['initial'],
          style: TextStyle(
            color: providerData['textColor'],
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getProviderData(String providerName) {
    // Normalize provider name for matching
    final normalizedName = providerName.toLowerCase().trim();

    switch (normalizedName) {
      case 'kotak neo':
      case 'kotak_neo':
        return {
          'initial': 'K',
          'backgroundColor': Color(0xFF003366), // Kotak Blue
          'textColor': Colors.white,
        };

      case 'hdfc sky':
      case 'hdfc_sky':
        return {
          'initial': 'H',
          'backgroundColor': Color(0xFF004B8D), // HDFC Blue
          'textColor': Colors.white,
        };

      case 'icici direct breeze':
      case 'icici_breeze':
        return {
          'initial': 'I',
          'backgroundColor': Color(0xFF751C24), // ICICI Red
          'textColor': Colors.white,
        };

      case 'axis':
        return {
          'initial': 'A',
          'backgroundColor': Color(0xFFA52A2A), // Axis Maroon
          'textColor': Colors.white,
        };

      case 'nse':
        return {
          'initial': 'N',
          'backgroundColor': Color(0xFF1E3A8A), // NSE Blue
          'textColor': Colors.white,
        };

      case 'bse':
        return {
          'initial': 'B',
          'backgroundColor': Color(0xFF059669), // BSE Green
          'textColor': Colors.white,
        };

      case 'angel one':
      case 'angel_one':
        return {
          'initial': 'A',
          'backgroundColor': Color(0xFF7C3AED), // Purple
          'textColor': Colors.white,
        };

      case 'choice broking':
      case 'choice':
        return {
          'initial': 'C',
          'backgroundColor': Color(0xFFDC2626), // Red
          'textColor': Colors.white,
        };

      case 'mangal keshav':
      case 'mangal_keshav':
      case 'mangalkeshav securities':
        return {
          'initial': 'M',
          'backgroundColor': Color(0xFFEA580C), // Orange
          'textColor': Colors.white,
        };

      default:
        // Generic broker logo
        return {
          'initial': providerName.isNotEmpty ? providerName[0].toUpperCase() : '?',
          'backgroundColor': Theme.of(context as BuildContext).primaryColor,
          'textColor': Colors.white,
        };
    }
  }
}