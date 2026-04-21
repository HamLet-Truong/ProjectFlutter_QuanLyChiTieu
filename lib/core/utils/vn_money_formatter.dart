import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class VnMoneyFormatter {
  static final NumberFormat _decimal = NumberFormat.decimalPattern('vi_VN');

  static String money(num amount) {
    return '${_decimal.format(amount.round())} đ';
  }

  static String signedMoney(num amount) {
    final prefix = amount < 0 ? '-' : '+';
    return '$prefix${money(amount.abs())}';
  }

  static int parseToInt(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.parse(digits);
  }
}

class VnMoneyInputFormatter extends TextInputFormatter {
  static final NumberFormat _decimal = NumberFormat.decimalPattern('vi_VN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final digitsBeforeCursor = _countDigitsBefore(
      newValue.text,
      newValue.selection.baseOffset,
    );

    final formatted = _decimal.format(int.parse(digits));
    final cursor = _cursorOffsetForDigits(formatted, digitsBeforeCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
      composing: TextRange.empty,
    );
  }

  int _countDigitsBefore(String text, int offset) {
    final safeOffset = math.max(0, math.min(offset, text.length));
    return RegExp(r'\d').allMatches(text.substring(0, safeOffset)).length;
  }

  int _cursorOffsetForDigits(String text, int digitCount) {
    if (digitCount <= 0) return 0;

    var seenDigits = 0;
    for (var i = 0; i < text.length; i++) {
      if (RegExp(r'\d').hasMatch(text[i])) {
        seenDigits++;
        if (seenDigits == digitCount) {
          return i + 1;
        }
      }
    }
    return text.length;
  }
}
