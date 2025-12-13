import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// AurumHarmony Footer Widget
/// Displays "Patent Pending © 2025 SaffronBolt Pvt Ltd | Visit www.saffronbolt.in"
class AurumFooter extends StatelessWidget {
  const AurumFooter({super.key});

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://www.saffronbolt.in');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Silently fail if can't launch
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.shade100,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Patent Pending
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Patent Pending',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Copyright
          Text(
            '© 2025 SaffronBolt Pvt Ltd',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          // Website Link
          GestureDetector(
            onTap: _launchURL,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Visit ',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  'www.saffronbolt.in',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.open_in_new,
                  size: 12,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simplified footer for minimal screens
class AurumFooterCompact extends StatelessWidget {
  const AurumFooterCompact({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        'Patent Pending © 2025 SaffronBolt | saffronbolt.in',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
}

