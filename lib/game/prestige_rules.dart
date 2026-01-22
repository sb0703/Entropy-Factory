import 'dart:math' as math;

// 蓝图转定律阈值与常数换算系数。
const double lawThreshold = 1000;
const double constantFactor = 5;

int lawsFromBlueprints(double blueprints) {
  // 达到阈值后按整数生成定律。
  if (blueprints < lawThreshold) {
    return 0;
  }
  return (blueprints / lawThreshold).floor();
}

double constantsFromLaws(double laws) {
  // 常数公式：向下取整(√定律 × 系数)。
  if (laws <= 0) {
    return 0;
  }
  return (math.sqrt(laws) * constantFactor).floorToDouble();
}
