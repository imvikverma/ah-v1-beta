import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Global utility for showing error dialogs that stay until dismissed
/// All errors are copyable with SelectableText
class ErrorDialog {
  /// Show an error dialog that must be dismissed by clicking the button
  /// Cannot be dismissed by tapping outside
  static Future<void> show(
    BuildContext context, {
    required String message,
    String title = 'Error',
    bool isWarning = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false, // MUST click Dismiss
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.error_outline,
              color: isWarning ? Colors.orange : Theme.of(context).colorScheme.error,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              message,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            // Copy button
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: message));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error message copied to clipboard'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy Error'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            label: const Text('Dismiss'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isWarning ? Colors.orange : Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Show a success dialog
  static Future<void> showSuccess(
    BuildContext context, {
    required String message,
    String title = 'Success',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true, // Can dismiss success messages
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show a confirmation dialog
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String message,
    String title = 'Confirm',
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

