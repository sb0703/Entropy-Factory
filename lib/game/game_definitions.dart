import 'game_state.dart';

/// 建筑类型枚举
enum BuildingType {
  /// 碎片生产者：直接产出碎片（如矿机）
  shardProducer,

  /// 碎片转换器：将碎片转换为零件
  shardToPart,

  /// 零件转换器：将零件转换为蓝图
  partToBlueprint,

  /// 能量生产者：提供能量，提高转换效率
  energyProducer
}

/// 建筑定义类
///
/// 定义了游戏中每种建筑的基本属性、造价和功能。
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

  /// 购买该建筑所需的资源类型
  final ResourceType costResource;

  /// 基础造价（第一个建筑的价格）
  final double baseCost;

  /// 造价增长系数（每多买一个，价格乘以该系数）
  final double costGrowth;

  /// 建筑类型（决定其生产逻辑）
  final BuildingType type;

  /// 基础每秒产出/处理量
  final double baseOutputPerSec;

  /// 每秒能量消耗（仅对某些类型有效）
  final double energyCostPerSec;
}

/// 常量：合成一个零件所需的碎片数量
const double shardsPerPart = 100;

/// 常量：合成一张蓝图所需的零件数量
const double partsPerBlueprint = 100;

/// 所有建筑的定义列表
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
    name: '地核采集阵',
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
    description: '高轨大规模碎片采集。',
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
    description: '将碎片转换为零件。',
    costResource: ResourceType.shard,
    baseCost: 1000,
    costGrowth: 1.2,
    type: BuildingType.shardToPart,
    baseOutputPerSec: 50,
  ),
  BuildingDefinition(
    id: 'furnace',
    name: '分形炉',
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
    name: '纳米熔炉',
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
];

/// 通过 ID 快速查找建筑定义的映射表
final Map<String, BuildingDefinition> buildingById = {
  for (final def in buildingDefinitions) def.id: def,
};
