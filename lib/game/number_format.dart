import 'dart:math' as math;

class _Unit {
  const _Unit(this.value, this.label);

  final double value;
  final String label;
}

const List<_Unit> _units = [
  _Unit(1e44, '载'),
  _Unit(1e40, '正'),
  _Unit(1e36, '涧'),
  _Unit(1e32, '沟'),
  _Unit(1e28, '穰'),
  _Unit(1e24, '秭'),
  _Unit(1e20, '垓'),
  _Unit(1e16, '京'),
  _Unit(1e12, '兆'),
  _Unit(1e8, '亿'),
  _Unit(1e4, '万'),
];

String formatNumber(double value) {
  if (value.isNaN) {
    return '—';
  }
  if (value.isInfinite) {
    return value.isNegative ? '-∞' : '∞';
  }
  final absValue = value.abs();
  if (absValue < 1e4) {
    return value.toStringAsFixed(value < 10 ? 2 : 1);
  }
  for (final unit in _units) {
    if (absValue >= unit.value) {
      return '${formatFixed(value / unit.value)}${unit.label}';
    }
  }
  if (absValue >= 1e48) {
    return value.toStringAsExponential(2);
  }
  return value.toStringAsFixed(1);
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
