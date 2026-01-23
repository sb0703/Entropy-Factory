import 'game_state.dart';

/// 建筑类型枚举
enum BuildingType {
  /// 碎片生产：直接产出碎片
  shardProducer,

  /// 碎片转换：将碎片转化为零件
  shardToPart,

  /// 零件合成：将零件合成为蓝图
  partToBlueprint,

  /// 能量生产：提供能量
  energyProducer,
}

/// 建筑定义
class BuildingDefinition {
  const BuildingDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.costResource,
    required this.baseCost,
    required this.costGrowth,
    required this.type,
    required this.baseOutputPerSec,
    this.energyCostPerSec = 0,
  });

  /// 唯一标识符
  final String id;

  /// 显示名称
  final String name;

  /// 描述文本
  final String description;

  /// 购买所需资源
  final ResourceType costResource;

  /// 基础造价
  final double baseCost;

  /// 造价增长系数
  final double costGrowth;

  /// 建筑类型
  final BuildingType type;

  /// 基础产出/处理量（每秒）
  final double baseOutputPerSec;

  /// 每秒能量消耗（仅对部分类型有效）
  final double energyCostPerSec;
}

/// 合成一个零件所需的碎片数量
const double shardsPerPart = 100;

/// 合成一张蓝图所需的零件数量
const double partsPerBlueprint = 100;

/// 所有建筑定义列表
const List<BuildingDefinition> buildingDefinitions = [
  BuildingDefinition(
    id: 'miner',
    name: '矿机',
    description: '基础碎片采集。',
    costResource: ResourceType.shard,
    baseCost: 10,
    costGrowth: 1.15,
    type: BuildingType.shardProducer,
    baseOutputPerSec: 0.1,
  ),
  BuildingDefinition(
    id: 'drill',
    name: '钻头阵列',
    description: '碎片采集倍率更高。',
    costResource: ResourceType.shard,
    baseCost: 120,
    costGrowth: 1.17,
    type: BuildingType.shardProducer,
    baseOutputPerSec: 0.6,
  ),
  BuildingDefinition(
    id: 'core_rig',
    name: '地核采集阵列',
    description: '深层碎片采集装置。',
    costResource: ResourceType.shard,
    baseCost: 5000,
    costGrowth: 1.18,
    type: BuildingType.shardProducer,
    baseOutputPerSec: 3.5,
  ),
  BuildingDefinition(
    id: 'orbital_array',
    name: '轨道采矿阵列',
    description: '高轨规模碎片采集。',
    costResource: ResourceType.shard,
    baseCost: 50000,
    costGrowth: 1.2,
    type: BuildingType.shardProducer,
    baseOutputPerSec: 25,
  ),
  BuildingDefinition(
    id: 'excavator',
    name: '重型挖掘机',
    description: '中期碎片采集装置。',
    costResource: ResourceType.shard,
    baseCost: 250000,
    costGrowth: 1.22,
    type: BuildingType.shardProducer,
    baseOutputPerSec: 120,
  ),
  BuildingDefinition(
    id: 'quantum_drill',
    name: '量子钻机',
    description: '高端碎片采集设施。',
    costResource: ResourceType.shard,
    baseCost: 2000000,
    costGrowth: 1.24,
    type: BuildingType.shardProducer,
    baseOutputPerSec: 600,
  ),
  BuildingDefinition(
    id: 'compressor',
    name: '压缩器',
    description: '将碎片转化为零件。',
    costResource: ResourceType.shard,
    baseCost: 1000,
    costGrowth: 1.2,
    type: BuildingType.shardToPart,
    baseOutputPerSec: 50,
  ),
  BuildingDefinition(
    id: 'refinery',
    name: '精炼压缩机',
    description: '中期碎片精炼与转化。',
    costResource: ResourceType.shard,
    baseCost: 12000,
    costGrowth: 1.22,
    type: BuildingType.shardToPart,
    baseOutputPerSec: 220,
  ),
  BuildingDefinition(
    id: 'assembler',
    name: '分子装配线',
    description: '高效碎片装配线。',
    costResource: ResourceType.shard,
    baseCost: 180000,
    costGrowth: 1.24,
    type: BuildingType.shardToPart,
    baseOutputPerSec: 1200,
  ),
  BuildingDefinition(
    id: 'furnace',
    name: '分型炉',
    description: '合成蓝图。',
    costResource: ResourceType.part,
    baseCost: 300,
    costGrowth: 1.25,
    type: BuildingType.partToBlueprint,
    baseOutputPerSec: 1,
    energyCostPerSec: 80,
  ),
  BuildingDefinition(
    id: 'nanoforge',
    name: '纳米锻炉',
    description: '进阶蓝图合成设施。',
    costResource: ResourceType.part,
    baseCost: 1500,
    costGrowth: 1.28,
    type: BuildingType.partToBlueprint,
    baseOutputPerSec: 3.5,
    energyCostPerSec: 220,
  ),
  BuildingDefinition(
    id: 'fusion',
    name: '聚变堆',
    description: '为合成系统供能。',
    costResource: ResourceType.part,
    baseCost: 500,
    costGrowth: 1.23,
    type: BuildingType.energyProducer,
    baseOutputPerSec: 60,
  ),
  BuildingDefinition(
    id: 'radiation_core',
    name: '辐射核心',
    description: '能量输出极高，但会削弱周围设施效率。',
    costResource: ResourceType.part,
    baseCost: 6000,
    costGrowth: 1.3,
    type: BuildingType.energyProducer,
    baseOutputPerSec: 420,
  ),
];

/// 通过 ID 快速查找建筑定义的映射表
final Map<String, BuildingDefinition> buildingById = {
  for (final def in buildingDefinitions) def.id: def,
};
