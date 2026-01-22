import 'dart:math' as math;

import 'big_number.dart';

class _Unit {
  const _Unit(this.exponent, this.label);

  final int exponent;
  final String label;
}

const List<_Unit> _units = [
  _Unit(44, '载'),
  _Unit(40, '正'),
  _Unit(36, '涧'),
  _Unit(32, '沟'),
  _Unit(28, '穰'),
  _Unit(24, '秭'),
  _Unit(20, '垓'),
  _Unit(16, '京'),
  _Unit(12, '兆'),
  _Unit(8, '亿'),
  _Unit(4, '万'),
];

String formatNumber(Object value) {
  if (value is BigNumber) {
    return _formatBigNumber(value);
  }
  if (value is num) {
    return _formatDouble(value.toDouble());
  }
  return '--';
}

String _formatDouble(double value) {
  if (value.isNaN) {
    return '--';
  }
  if (value.isInfinite) {
    return value.isNegative ? '-∞' : '∞';
  }
  final absValue = value.abs();
  if (absValue < 1e4) {
    return value.toStringAsFixed(value < 10 ? 2 : 1);
  }
  for (final unit in _units) {
    final threshold = math.pow(10, unit.exponent).toDouble();
    if (absValue >= threshold) {
      return '${formatFixed(value / threshold)}${unit.label}';
    }
  }
  if (absValue >= 1e48) {
    return value.toStringAsExponential(2);
  }
  return value.toStringAsFixed(1);
}

String _formatBigNumber(BigNumber value) {
  if (value.isZero) {
    return '0';
  }
  final sign = value.mantissa < 0 ? '-' : '';
  final absValue = value.abs();
  if (absValue.exponent < 4) {
    return _formatDouble(absValue.toDouble());
  }
  if (absValue.exponent >= 48) {
    return '$sign${absValue.mantissa.toStringAsFixed(2)}e${absValue.exponent}';
  }
  for (final unit in _units) {
    if (absValue.exponent >= unit.exponent) {
      final scaled = absValue.mantissa *
          math.pow(10, absValue.exponent - unit.exponent).toDouble();
      return '$sign${formatFixed(scaled)}${unit.label}';
    }
  }
  return '$sign${absValue.mantissa.toStringAsFixed(2)}e${absValue.exponent}';
}

String formatFixed(double value) {
  final absValue = value.abs();
  final precision = absValue >= 10 ? 1 : 2;
  return value.toStringAsFixed(precision);
}

double clampNonZero(double value) {
  if (value.isNaN || value.isInfinite) {
    return 0;
  }
  return math.max(0, value);
}


