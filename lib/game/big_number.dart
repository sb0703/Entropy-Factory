import 'dart:math' as math;

/// 简易大数表示（科学计数法，10 为底）
///
/// 适用于增量游戏的近似运算：性能优先，精度足够即可。
class BigNumber implements Comparable<BigNumber> {
  const BigNumber._(this.mantissa, this.exponent);

  /// 尾数，范围约为 [1, 10)
  final double mantissa;

  /// 指数（10 的幂次）
  final int exponent;

  static const BigNumber zero = BigNumber._(0, 0);
  static const BigNumber one = BigNumber._(1, 0);

  factory BigNumber.fromDouble(double value) {
    if (value.isNaN || value == 0) {
      return zero;
    }
    if (value.isInfinite) {
      final sign = value.isNegative ? -1.0 : 1.0;
      return BigNumber._(sign * 9.99, 308);
    }
    final absValue = value.abs();
    final exponent = absValue < 1 ? absValue.log10().floor() : absValue.log10().floor();
    final mantissa = value / math.pow(10, exponent);
    return BigNumber._normalize(mantissa, exponent);
  }

  factory BigNumber.fromInt(int value) {
    return BigNumber.fromDouble(value.toDouble());
  }

  factory BigNumber.fromLog10(double log10Value) {
    if (log10Value.isNaN || log10Value.isInfinite) {
      return zero;
    }
    final exponent = log10Value.floor();
    final mantissa = math.pow(10, log10Value - exponent).toDouble();
    return BigNumber._normalize(mantissa, exponent);
  }

  factory BigNumber.fromJson(dynamic json) {
    if (json is num) {
      return BigNumber.fromDouble(json.toDouble());
    }
    if (json is String) {
      final parts = json.split('|');
      if (parts.length == 2) {
        final mantissa = double.tryParse(parts[0]) ?? 0;
        final exponent = int.tryParse(parts[1]) ?? 0;
        return BigNumber._normalize(mantissa, exponent);
      }
      return BigNumber.fromDouble(double.tryParse(json) ?? 0);
    }
    if (json is Map) {
      final mantissa = (json['m'] as num?)?.toDouble() ?? 0;
      final exponent = (json['e'] as num?)?.toInt() ?? 0;
      return BigNumber._normalize(mantissa, exponent);
    }
    return zero;
  }

  Map<String, dynamic> toJson() {
    return {'m': mantissa, 'e': exponent};
  }

  static BigNumber _normalize(double mantissa, int exponent) {
    if (mantissa == 0 || mantissa.isNaN) {
      return zero;
    }
    var m = mantissa;
    var e = exponent;
    var absM = m.abs();
    while (absM >= 10) {
      m /= 10;
      e += 1;
      absM /= 10;
    }
    while (absM < 1) {
      m *= 10;
      e -= 1;
      absM *= 10;
    }
    return BigNumber._(m, e);
  }

  bool get isZero => mantissa == 0;

  BigNumber abs() {
    return mantissa < 0 ? BigNumber._(-mantissa, exponent) : this;
  }

  double log10() {
    if (isZero) {
      return double.negativeInfinity;
    }
    return math.log(mantissa.abs()) / math.ln10 + exponent;
  }

  double toDouble({double max = 1e308}) {
    if (isZero) {
      return 0;
    }
    if (exponent > 308) {
      return mantissa.isNegative ? -max : max;
    }
    if (exponent < -324) {
      return 0;
    }
    return mantissa * math.pow(10, exponent);
  }

  BigNumber operator +(BigNumber other) {
    if (isZero) {
      return other;
    }
    if (other.isZero) {
      return this;
    }
    final diff = exponent - other.exponent;
    if (diff.abs() > 12) {
      return diff > 0 ? this : other;
    }
    if (diff >= 0) {
      final aligned = other.mantissa * math.pow(10, -diff);
      return BigNumber._normalize(mantissa + aligned, exponent);
    }
    final aligned = mantissa * math.pow(10, diff);
    return BigNumber._normalize(other.mantissa + aligned, other.exponent);
  }

  BigNumber operator -(BigNumber other) {
    if (other.isZero) {
      return this;
    }
    if (compareTo(other) <= 0) {
      return zero;
    }
    final diff = exponent - other.exponent;
    if (diff.abs() > 12) {
      return this;
    }
    if (diff >= 0) {
      final aligned = other.mantissa * math.pow(10, -diff);
      return BigNumber._normalize(mantissa - aligned, exponent);
    }
    final aligned = mantissa * math.pow(10, diff);
    return BigNumber._normalize(aligned - other.mantissa, other.exponent);
  }

  BigNumber operator *(BigNumber other) {
    if (isZero || other.isZero) {
      return zero;
    }
    return BigNumber._normalize(
      mantissa * other.mantissa,
      exponent + other.exponent,
    );
  }

  BigNumber operator /(BigNumber other) {
    if (isZero || other.isZero) {
      return zero;
    }
    return BigNumber._normalize(
      mantissa / other.mantissa,
      exponent - other.exponent,
    );
  }

  BigNumber timesDouble(double scalar) {
    return this * BigNumber.fromDouble(scalar);
  }

  BigNumber dividedByDouble(double scalar) {
    if (scalar == 0) {
      return zero;
    }
    return this / BigNumber.fromDouble(scalar);
  }

  @override
  int compareTo(BigNumber other) {
    if (isZero && other.isZero) {
      return 0;
    }
    if (exponent != other.exponent) {
      return exponent.compareTo(other.exponent);
    }
    return mantissa.compareTo(other.mantissa);
  }

  bool operator <(BigNumber other) => compareTo(other) < 0;
  bool operator >(BigNumber other) => compareTo(other) > 0;
  bool operator <=(BigNumber other) => compareTo(other) <= 0;
  bool operator >=(BigNumber other) => compareTo(other) >= 0;

  BigNumber floorToIntish() {
    if (isZero) {
      return zero;
    }
    if (exponent <= 6) {
      final value = toDouble();
      return BigNumber.fromDouble(value.floorToDouble());
    }
    return this;
  }

  @override
  String toString() => '$mantissa|$exponent';
}

extension _Log10 on double {
  double log10() => math.log(this) / math.ln10;
}



