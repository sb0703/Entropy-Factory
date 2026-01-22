import 'dart:math' as math;

import 'big_number.dart';

// 蓝图转定律阈值与常数换算系数。
const double lawThreshold = 1000;
const double constantFactor = 5;

/// 根据当前蓝图数量计算可获得的定律数量（近似）。
BigNumber lawsFromBlueprints(BigNumber blueprints) {
  if (blueprints < BigNumber.fromDouble(lawThreshold)) {
    return BigNumber.zero;
  }
  return blueprints.dividedByDouble(lawThreshold).floorToIntish();
}

/// 根据定律数量计算可获得的常数数量（近似）。
BigNumber constantsFromLaws(BigNumber laws) {
  if (laws <= BigNumber.zero) {
    return BigNumber.zero;
  }
  final log10Value = laws.log10();
  if (!log10Value.isFinite) {
    return BigNumber.zero;
  }
  final constantLog10 = math.log(constantFactor) / math.ln10;
  final resultLog10 = 0.5 * log10Value + constantLog10;
  return BigNumber.fromLog10(resultLog10).floorToIntish();
}
