import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'big_number.dart';

enum ResourceType { shard, part, blueprint, law, constant }

enum EnergyPriorityMode { synthesisFirst, conversionFirst }

const int layoutColumns = 5;
const int layoutRows = 4;
const int layoutSize = layoutColumns * layoutRows;
const int layoutBaseColumns = 3;
const int layoutBaseRows = 3;
const String layoutUnlockResearchId = 'industry_layout';
const String layoutExpandResearchId = 'industry_layout_2';
const String layoutMaxResearchId = 'industry_layout_3';

@immutable
class GameState {
  const GameState({
    required this.resources,
    required this.buildings,
    required this.researchPurchased,
    required this.milestonesAchieved,
    required this.constantUpgrades,
    required this.logEntries,
    required this.activeChallengeId,
    required this.completedChallenges,
    required this.permanentUnlocks,
    required this.runModifiers,
    required this.skillPoints,
    required this.unlockedSkills,
    required this.equippedSkills,
    required this.pulseCooldownEndsAtMs,
    required this.shardToPartRatio,
    required this.keepShardReserve,
    required this.energyToSynthesisRatio,
    required this.shardReserveMin,
    required this.timeWarpEndsAtMs,
    required this.timeWarpCooldownEndsAtMs,
    required this.timeWarpLevel,
    required this.energyPriorityMode,
    required this.layoutGrid,
    required this.overclockEndsAtMs,
    required this.overclockCooldownEndsAtMs,
    required this.overclockLevel,
  });

  final Map<ResourceType, BigNumber> resources;

  final Map<String, int> buildings;

  final Set<String> researchPurchased;

  final Set<String> milestonesAchieved;

  final Map<String, int> constantUpgrades;

  final List<GameLogEntry> logEntries;

  final String? activeChallengeId;

  final Set<String> completedChallenges;

  final Set<String> permanentUnlocks;

  final List<String> runModifiers;

  final int skillPoints;

  final Set<String> unlockedSkills;

  final List<String> equippedSkills;

  final int pulseCooldownEndsAtMs;

  final double shardToPartRatio;

  final bool keepShardReserve;

  final double energyToSynthesisRatio;

  final double shardReserveMin;

  final int timeWarpEndsAtMs;

  final int timeWarpCooldownEndsAtMs;

  final int timeWarpLevel;

  final EnergyPriorityMode energyPriorityMode;

  final List<String?> layoutGrid;

  final int overclockEndsAtMs;

  final int overclockCooldownEndsAtMs;

  final int overclockLevel;

  BigNumber resource(ResourceType type) => resources[type] ?? BigNumber.zero;

  bool get isLayoutUnlocked {
    return researchPurchased.contains(layoutUnlockResearchId);
  }

  int get layoutUnlockedColumns {
    if (!isLayoutUnlocked) {
      return 0;
    }
    if (researchPurchased.contains(layoutMaxResearchId)) {
      return layoutColumns;
    }
    if (researchPurchased.contains(layoutExpandResearchId)) {
      return math.min(layoutColumns, 4);
    }
    return layoutBaseColumns;
  }

  int get layoutUnlockedRows {
    if (!isLayoutUnlocked) {
      return 0;
    }
    if (researchPurchased.contains(layoutExpandResearchId) ||
        researchPurchased.contains(layoutMaxResearchId)) {
      return layoutRows;
    }
    return layoutBaseRows;
  }

  int get layoutUnlockedCount => layoutUnlockedColumns * layoutUnlockedRows;

  bool isLayoutSlotUnlocked(int index) {
    if (!isLayoutUnlocked) {
      return false;
    }
    if (index < 0 || index >= layoutSize) {
      return false;
    }
    final unlockedCols = layoutUnlockedColumns;
    final unlockedRows = layoutUnlockedRows;
    if (unlockedCols <= 0 || unlockedRows <= 0) {
      return false;
    }
    final row = index ~/ layoutColumns;
    final col = index % layoutColumns;
    final startCol = (layoutColumns - unlockedCols) ~/ 2;
    final startRow = (layoutRows - unlockedRows) ~/ 2;
    return row >= startRow &&
        row < startRow + unlockedRows &&
        col >= startCol &&
        col < startCol + unlockedCols;
  }

  double resourceAsDouble(ResourceType type, {double max = 1e308}) {
    return resource(type).toDouble(max: max);
  }

  int buildingCount(String id) => buildings[id] ?? 0;

  GameState copyWith({
    Map<ResourceType, BigNumber>? resources,
    Map<String, int>? buildings,
    Set<String>? researchPurchased,
    Set<String>? milestonesAchieved,
    Map<String, int>? constantUpgrades,
    List<GameLogEntry>? logEntries,
    String? activeChallengeId,
    Set<String>? completedChallenges,
    Set<String>? permanentUnlocks,
    List<String>? runModifiers,
    int? skillPoints,
    Set<String>? unlockedSkills,
    List<String>? equippedSkills,
    int? pulseCooldownEndsAtMs,
    double? shardToPartRatio,
    bool? keepShardReserve,
    double? energyToSynthesisRatio,
    double? shardReserveMin,
    int? timeWarpEndsAtMs,
    int? timeWarpCooldownEndsAtMs,
    int? timeWarpLevel,
    EnergyPriorityMode? energyPriorityMode,
    List<String?>? layoutGrid,
    int? overclockEndsAtMs,
    int? overclockCooldownEndsAtMs,
    int? overclockLevel,
  }) {
    return GameState(
      resources: resources ?? this.resources,
      buildings: buildings ?? this.buildings,
      researchPurchased: researchPurchased ?? this.researchPurchased,
      milestonesAchieved: milestonesAchieved ?? this.milestonesAchieved,
      constantUpgrades: constantUpgrades ?? this.constantUpgrades,
      logEntries: logEntries ?? this.logEntries,
      activeChallengeId: activeChallengeId ?? this.activeChallengeId,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      permanentUnlocks: permanentUnlocks ?? this.permanentUnlocks,
      runModifiers: runModifiers ?? this.runModifiers,
      skillPoints: skillPoints ?? this.skillPoints,
      unlockedSkills: unlockedSkills ?? this.unlockedSkills,
      equippedSkills: equippedSkills ?? this.equippedSkills,
      pulseCooldownEndsAtMs: pulseCooldownEndsAtMs ?? this.pulseCooldownEndsAtMs,
      shardToPartRatio: shardToPartRatio ?? this.shardToPartRatio,
      keepShardReserve: keepShardReserve ?? this.keepShardReserve,
      energyToSynthesisRatio: energyToSynthesisRatio ?? this.energyToSynthesisRatio,
      shardReserveMin: shardReserveMin ?? this.shardReserveMin,
      timeWarpEndsAtMs: timeWarpEndsAtMs ?? this.timeWarpEndsAtMs,
      timeWarpCooldownEndsAtMs:
          timeWarpCooldownEndsAtMs ?? this.timeWarpCooldownEndsAtMs,
      timeWarpLevel: timeWarpLevel ?? this.timeWarpLevel,
      energyPriorityMode: energyPriorityMode ?? this.energyPriorityMode,
      layoutGrid: layoutGrid ?? this.layoutGrid,
      overclockEndsAtMs: overclockEndsAtMs ?? this.overclockEndsAtMs,
      overclockCooldownEndsAtMs:
          overclockCooldownEndsAtMs ?? this.overclockCooldownEndsAtMs,
      overclockLevel: overclockLevel ?? this.overclockLevel,
    );
  }

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
    // 如果日志数量超过限制，移除最早的记录。
    final trimmed = next.length > maxEntries
        ? next.sublist(next.length - maxEntries)
        : next;
    return copyWith(logEntries: trimmed);
  }

  Map<String, dynamic> toJson() {
    return {
      'resources': {
        for (final entry in resources.entries) entry.key.name: entry.value.toJson(),
      },
      'buildings': buildings,
      'researchPurchased': researchPurchased.toList(),
      'milestonesAchieved': milestonesAchieved.toList(),
      'constantUpgrades': constantUpgrades,
      'logEntries': logEntries.map((entry) => entry.toJson()).toList(),
      'activeChallengeId': activeChallengeId,
      'completedChallenges': completedChallenges.toList(),
      'permanentUnlocks': permanentUnlocks.toList(),
      'runModifiers': runModifiers,
      'skillPoints': skillPoints,
      'unlockedSkills': unlockedSkills.toList(),
      'equippedSkills': equippedSkills,
      'pulseCooldownEndsAtMs': pulseCooldownEndsAtMs,
      'shardToPartRatio': shardToPartRatio,
      'keepShardReserve': keepShardReserve,
      'energyToSynthesisRatio': energyToSynthesisRatio,
      'shardReserveMin': shardReserveMin,
      'timeWarpEndsAtMs': timeWarpEndsAtMs,
      'timeWarpCooldownEndsAtMs': timeWarpCooldownEndsAtMs,
      'timeWarpLevel': timeWarpLevel,
      'energyPriorityMode': energyPriorityMode.name,
      'layoutGrid': layoutGrid,
      'overclockEndsAtMs': overclockEndsAtMs,
      'overclockCooldownEndsAtMs': overclockCooldownEndsAtMs,
      'overclockLevel': overclockLevel,
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    final defaults = GameState.initial();
    
    // 解析资源
    final resources = Map<ResourceType, BigNumber>.from(defaults.resources);
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
        if (type != null) {
          resources[type] = BigNumber.fromJson(value);
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

    final completedChallenges = <String>{};
    final completedList = json['completedChallenges'];
    if (completedList is List) {
      for (final entry in completedList) {
        completedChallenges.add(entry.toString());
      }
    }

    final permanentUnlocks = <String>{};
    final unlockList = json['permanentUnlocks'];
    if (unlockList is List) {
      for (final entry in unlockList) {
        permanentUnlocks.add(entry.toString());
      }
    }

    final runModifiers = <String>[];
    final runList = json['runModifiers'];
    if (runList is List) {
      for (final entry in runList) {
        runModifiers.add(entry.toString());
      }
    }

    final unlockedSkills = <String>{};
    final unlockedList = json['unlockedSkills'];
    if (unlockedList is List) {
      for (final entry in unlockedList) {
        unlockedSkills.add(entry.toString());
      }
    }

    final equippedSkills = <String>[];
    final equippedList = json['equippedSkills'];
    if (equippedList is List) {
      for (final entry in equippedList) {
        equippedSkills.add(entry.toString());
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

    final layoutGrid = <String?>[];
    final layoutList = json['layoutGrid'];
    if (layoutList is List) {
      for (final entry in layoutList) {
        layoutGrid.add(entry?.toString());
      }
    }
    if (layoutGrid.length < layoutSize) {
      layoutGrid.addAll(List<String?>.filled(
        layoutSize - layoutGrid.length,
        null,
      ));
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
      activeChallengeId: json['activeChallengeId']?.toString(),
      completedChallenges: completedChallenges,
      permanentUnlocks: permanentUnlocks,
      runModifiers: runModifiers,
      skillPoints: (json['skillPoints'] as num?)?.toInt() ?? 0,
      unlockedSkills: unlockedSkills,
      equippedSkills: equippedSkills,
      pulseCooldownEndsAtMs:
          (json['pulseCooldownEndsAtMs'] as num?)?.toInt() ?? 0,
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
      energyPriorityMode: EnergyPriorityMode.values.firstWhere(
        (mode) => mode.name == json['energyPriorityMode'],
        orElse: () => defaults.energyPriorityMode,
      ),
      layoutGrid:
          layoutGrid.isEmpty ? defaults.layoutGrid : layoutGrid,
      overclockEndsAtMs:
          (json['overclockEndsAtMs'] as num?)?.toInt() ??
              defaults.overclockEndsAtMs,
      overclockCooldownEndsAtMs:
          (json['overclockCooldownEndsAtMs'] as num?)?.toInt() ??
              defaults.overclockCooldownEndsAtMs,
      overclockLevel:
          (json['overclockLevel'] as num?)?.toInt() ??
              defaults.overclockLevel,
    );
  }

  factory GameState.initial() {
    return GameState(
      resources: {
        ResourceType.shard: BigNumber.fromDouble(100),
        ResourceType.part: BigNumber.zero,
        ResourceType.blueprint: BigNumber.zero,
        ResourceType.law: BigNumber.zero,
        ResourceType.constant: BigNumber.zero,
      },
      buildings: const {
        'miner': 1,
        'drill': 0,
        'core_rig': 0,
        'orbital_array': 0,
        'excavator': 0,
        'quantum_drill': 0,
        'compressor': 0,
        'refinery': 0,
        'assembler': 0,
        'furnace': 0,
        'nanoforge': 0,
        'fusion': 0,
        'radiation_core': 0,
      },
      researchPurchased: const <String>{},
      milestonesAchieved: const <String>{},
      constantUpgrades: const <String, int>{},
      logEntries: const [],
      activeChallengeId: null,
      completedChallenges: const <String>{},
      permanentUnlocks: const <String>{},
      runModifiers: const <String>[],
      skillPoints: 0,
      unlockedSkills: const <String>{},
      equippedSkills: const <String>[],
      pulseCooldownEndsAtMs: 0,
      shardToPartRatio: 0.5,
      keepShardReserve: true,
      energyToSynthesisRatio: 0.7,
      shardReserveMin: 1000,
      timeWarpEndsAtMs: 0,
      timeWarpCooldownEndsAtMs: 0,
      timeWarpLevel: 0,
      energyPriorityMode: EnergyPriorityMode.synthesisFirst,
      layoutGrid: List<String?>.filled(layoutSize, null),
      overclockEndsAtMs: 0,
      overclockCooldownEndsAtMs: 0,
      overclockLevel: 0,
    );
  }
}

@immutable
class GameLogEntry {
  const GameLogEntry({
    required this.title,
    required this.detail,
    required this.timeMs,
  });

  final String title;
  
  final String detail;
  
  final int timeMs;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'detail': detail,
      'timeMs': timeMs,
    };
  }

  factory GameLogEntry.fromJson(Map<String, dynamic> json) {
    return GameLogEntry(
      title: json['title']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      timeMs: (json['timeMs'] as num?)?.toInt() ?? 0,
    );
  }
}



