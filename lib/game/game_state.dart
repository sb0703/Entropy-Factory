import 'package:flutter/foundation.dart';

enum ResourceType { shard, part, blueprint, law, constant }

/// 游戏核心状态类
///
/// 包含所有需要持久化的游戏数据，如资源数量、建筑数量、解锁的研究、里程碑等。
/// 这是一个不可变类，所有的状态修改都会返回一个新的实例。
@immutable
class GameState {
  const GameState({
    required this.resources,
    required this.buildings,
    required this.researchPurchased,
    required this.milestonesAchieved,
    required this.constantUpgrades,
    required this.logEntries,
    required this.shardToPartRatio,
    required this.keepShardReserve,
    required this.energyToSynthesisRatio,
    required this.shardReserveMin,
    required this.timeWarpEndsAtMs,
    required this.timeWarpCooldownEndsAtMs,
    required this.timeWarpLevel,
  });

  /// 当前拥有的资源数量映射表
  final Map<ResourceType, double> resources;

  /// 当前拥有的建筑数量映射表 (建筑ID -> 数量)
  final Map<String, int> buildings;

  /// 已购买的研究项目 ID 集合
  final Set<String> researchPurchased;

  /// 已达成的里程碑 ID 集合
  final Set<String> milestonesAchieved;

  /// 已购买的常数升级及其等级 (升级ID -> 等级)
  final Map<String, int> constantUpgrades;

  /// 游戏日志记录
  final List<GameLogEntry> logEntries;

  /// 碎片转换为零件的分配比例 (0.0 - 1.0)
  /// 控制有多少产生的碎片会被自动送去转换。
  final double shardToPartRatio;

  /// 是否保留最小碎片储备
  /// 如果为 true，转换过程不会消耗低于 [shardReserveMin] 的碎片。
  final bool keepShardReserve;

  /// 能量分配给合成系统的比例 (0.0 - 1.0)
  final double energyToSynthesisRatio;

  /// 最小碎片储备量
  final double shardReserveMin;

  /// 时间扭曲技能结束时间（毫秒时间戳）
  final int timeWarpEndsAtMs;

  /// 时间扭曲技能冷却结束时间（毫秒时间戳）
  final int timeWarpCooldownEndsAtMs;

  /// 时间扭曲技能等级
  final int timeWarpLevel;

  /// 获取指定类型资源的数量，默认为 0
  double resource(ResourceType type) => resources[type] ?? 0;

  /// 获取指定建筑的数量，默认为 0
  int buildingCount(String id) => buildings[id] ?? 0;

  /// 创建当前状态的副本，并根据需要修改部分属性
  GameState copyWith({
    Map<ResourceType, double>? resources,
    Map<String, int>? buildings,
    Set<String>? researchPurchased,
    Set<String>? milestonesAchieved,
    Map<String, int>? constantUpgrades,
    List<GameLogEntry>? logEntries,
    double? shardToPartRatio,
    bool? keepShardReserve,
    double? energyToSynthesisRatio,
    double? shardReserveMin,
    int? timeWarpEndsAtMs,
    int? timeWarpCooldownEndsAtMs,
    int? timeWarpLevel,
  }) {
    return GameState(
      resources: resources ?? this.resources,
      buildings: buildings ?? this.buildings,
      researchPurchased: researchPurchased ?? this.researchPurchased,
      milestonesAchieved: milestonesAchieved ?? this.milestonesAchieved,
      constantUpgrades: constantUpgrades ?? this.constantUpgrades,
      logEntries: logEntries ?? this.logEntries,
      shardToPartRatio: shardToPartRatio ?? this.shardToPartRatio,
      keepShardReserve: keepShardReserve ?? this.keepShardReserve,
      energyToSynthesisRatio: energyToSynthesisRatio ?? this.energyToSynthesisRatio,
      shardReserveMin: shardReserveMin ?? this.shardReserveMin,
      timeWarpEndsAtMs: timeWarpEndsAtMs ?? this.timeWarpEndsAtMs,
      timeWarpCooldownEndsAtMs:
          timeWarpCooldownEndsAtMs ?? this.timeWarpCooldownEndsAtMs,
      timeWarpLevel: timeWarpLevel ?? this.timeWarpLevel,
    );
  }

  /// 添加一条日志记录
  ///
  /// [title] 日志标题
  /// [detail] 日志详情
  /// [maxEntries] 保留的最大日志条数，默认为 50
  GameState addLogEntry(
    String title,
    String detail, {
    DateTime? time,
    int maxEntries = 50,
  }) {
    final entry = GameLogEntry(
      title: title,
      detail: detail,
      timeMs: (time ?? DateTime.now()).millisecondsSinceEpoch,
    );
    final next = [...logEntries, entry];
    // 如果日志数量超过限制，移除最早的记录
    final trimmed = next.length > maxEntries
        ? next.sublist(next.length - maxEntries)
        : next;
    return copyWith(logEntries: trimmed);
  }

  /// 将游戏状态序列化为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'resources': {
        for (final entry in resources.entries) entry.key.name: entry.value,
      },
      'buildings': buildings,
      'researchPurchased': researchPurchased.toList(),
      'milestonesAchieved': milestonesAchieved.toList(),
      'constantUpgrades': constantUpgrades,
      'logEntries': logEntries.map((entry) => entry.toJson()).toList(),
      'shardToPartRatio': shardToPartRatio,
      'keepShardReserve': keepShardReserve,
      'energyToSynthesisRatio': energyToSynthesisRatio,
      'shardReserveMin': shardReserveMin,
      'timeWarpEndsAtMs': timeWarpEndsAtMs,
      'timeWarpCooldownEndsAtMs': timeWarpCooldownEndsAtMs,
      'timeWarpLevel': timeWarpLevel,
    };
  }

  /// 从 JSON Map 反序列化游戏状态
  factory GameState.fromJson(Map<String, dynamic> json) {
    final defaults = GameState.initial();
    
    // 解析资源
    final resources = Map<ResourceType, double>.from(defaults.resources);
    final resourceMap = json['resources'];
    if (resourceMap is Map) {
      for (final entry in resourceMap.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        ResourceType? type;
        for (final candidate in ResourceType.values) {
          if (candidate.name == key) {
            type = candidate;
            break;
          }
        }
        if (type != null && value is num) {
          resources[type] = value.toDouble();
        }
      }
    }

    // 解析建筑
    final buildings = <String, int>{};
    final buildingsMap = json['buildings'];
    if (buildingsMap is Map) {
      for (final entry in buildingsMap.entries) {
        buildings[entry.key.toString()] = (entry.value as num).toInt();
      }
    }

    // 解析已购买的研究
    final researchPurchased = <String>{};
    final researchList = json['researchPurchased'];
    if (researchList is List) {
      for (final entry in researchList) {
        researchPurchased.add(entry.toString());
      }
    }

    // 解析已达成的里程碑
    final milestonesAchieved = <String>{};
    final milestoneList = json['milestonesAchieved'];
    if (milestoneList is List) {
      for (final entry in milestoneList) {
        milestonesAchieved.add(entry.toString());
      }
    }

    // 解析常数升级
    final constantUpgrades = <String, int>{};
    final upgradeMap = json['constantUpgrades'];
    if (upgradeMap is Map) {
      for (final entry in upgradeMap.entries) {
        constantUpgrades[entry.key.toString()] = (entry.value as num).toInt();
      }
    }

    // 解析日志
    final logEntries = <GameLogEntry>[];
    final logList = json['logEntries'];
    if (logList is List) {
      for (final entry in logList) {
        if (entry is Map) {
          logEntries.add(GameLogEntry.fromJson(
            entry.map((key, value) => MapEntry(key.toString(), value)),
          ));
        }
      }
    }

    return GameState(
      resources: resources,
      buildings: buildings.isEmpty ? defaults.buildings : buildings,
      researchPurchased: researchPurchased,
      milestonesAchieved: milestonesAchieved.isEmpty
          ? defaults.milestonesAchieved
          : milestonesAchieved,
      constantUpgrades:
          constantUpgrades.isEmpty ? defaults.constantUpgrades : constantUpgrades,
      logEntries: logEntries,
      shardToPartRatio:
          (json['shardToPartRatio'] as num?)?.toDouble() ?? defaults.shardToPartRatio,
      keepShardReserve: json['keepShardReserve'] as bool? ?? defaults.keepShardReserve,
      energyToSynthesisRatio:
          (json['energyToSynthesisRatio'] as num?)?.toDouble() ??
              defaults.energyToSynthesisRatio,
      shardReserveMin:
          (json['shardReserveMin'] as num?)?.toDouble() ?? defaults.shardReserveMin,
      timeWarpEndsAtMs:
          (json['timeWarpEndsAtMs'] as num?)?.toInt() ??
              defaults.timeWarpEndsAtMs,
      timeWarpCooldownEndsAtMs:
          (json['timeWarpCooldownEndsAtMs'] as num?)?.toInt() ??
              defaults.timeWarpCooldownEndsAtMs,
      timeWarpLevel:
          (json['timeWarpLevel'] as num?)?.toInt() ?? defaults.timeWarpLevel,
    );
  }

  /// 初始化游戏状态（新游戏）
  factory GameState.initial() {
    return GameState(
      resources: const {
        ResourceType.shard: 100,
        ResourceType.part: 0,
        ResourceType.blueprint: 0,
        ResourceType.law: 0,
        ResourceType.constant: 0,
      },
      buildings: const {
        'miner': 1,
        'drill': 0,
        'compressor': 0,
        'furnace': 0,
        'fusion': 0,
      },
      researchPurchased: const <String>{},
      milestonesAchieved: const <String>{},
      constantUpgrades: const <String, int>{},
      logEntries: const [],
      shardToPartRatio: 0.5,
      keepShardReserve: true,
      energyToSynthesisRatio: 0.7,
      shardReserveMin: 1000,
      timeWarpEndsAtMs: 0,
      timeWarpCooldownEndsAtMs: 0,
      timeWarpLevel: 0,
    );
  }
}

/// 游戏日志条目类
///
/// 记录游戏中的重要事件，如达成里程碑、完成研究等。
@immutable
class GameLogEntry {
  const GameLogEntry({
    required this.title,
    required this.detail,
    required this.timeMs,
  });

  /// 标题
  final String title;
  
  /// 详情内容
  final String detail;
  
  /// 发生时间（毫秒时间戳）
  final int timeMs;

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'detail': detail,
      'timeMs': timeMs,
    };
  }

  /// 反序列化
  factory GameLogEntry.fromJson(Map<String, dynamic> json) {
    return GameLogEntry(
      title: json['title']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      timeMs: (json['timeMs'] as num?)?.toInt() ?? 0,
    );
  }
}
