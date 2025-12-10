import 'package:flutter/services.dart';

/// Phone number formatter for Indian phone numbers
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Handle +91 prefix
    if (text.startsWith('+91')) {
      final digits = text.substring(3);
      if (digits.length <= 10) {
        final formatted = '+91 ${_formatDigits(digits)}';
        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    } else if (text.startsWith('91') && text.length > 2) {
      final digits = text.substring(2);
      if (digits.length <= 10) {
        final formatted = '+91 ${_formatDigits(digits)}';
        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    } else if (text.length <= 10) {
      // Indian number without country code
      final formatted = _formatDigits(text);
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    
    return oldValue;
  }
  
  String _formatDigits(String digits) {
    if (digits.isEmpty) return '';
    if (digits.length <= 5) {
      return digits;
    } else if (digits.length <= 10) {
      return '${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return digits.substring(0, 10);
  }
}

