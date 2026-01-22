import 'package:flutter/foundation.dart';

import 'big_number.dart';

enum ResourceType { shard, part, blueprint, law, constant }

enum EnergyPriorityMode { synthesisFirst, conversionFirst }

const int layoutColumns = 4;
const int layoutRows = 4;
const int layoutSize = layoutColumns * layoutRows;

/// 娓告垙鏍稿績鐘舵€佺被
///
/// 鍖呭惈鎵€鏈夐渶瑕佹寔涔呭寲鐨勬父鎴忔暟鎹紝濡傝祫婧愭暟閲忋€佸缓绛戞暟閲忋€佽В閿佺殑鐮旂┒銆侀噷绋嬬绛夈€?
/// 杩欐槸涓€涓笉鍙彉绫伙紝鎵€鏈夌殑鐘舵€佷慨鏀归兘浼氳繑鍥炰竴涓柊鐨勫疄渚嬨€?
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

  /// 褰撳墠鎷ユ湁鐨勮祫婧愭暟閲忔槧灏勮〃
  final Map<ResourceType, BigNumber> resources;

  /// 褰撳墠鎷ユ湁鐨勫缓绛戞暟閲忔槧灏勮〃 (寤虹瓚ID -> 鏁伴噺)
  final Map<String, int> buildings;

  /// 宸茶喘涔扮殑鐮旂┒椤圭洰 ID 闆嗗悎
  final Set<String> researchPurchased;

  /// 宸茶揪鎴愮殑閲岀▼纰?ID 闆嗗悎
  final Set<String> milestonesAchieved;

  /// 宸茶喘涔扮殑甯告暟鍗囩骇鍙婂叾绛夌骇 (鍗囩骇ID -> 绛夌骇)
  final Map<String, int> constantUpgrades;

  /// 娓告垙鏃ュ織璁板綍
  final List<GameLogEntry> logEntries;

  /// 褰撳墠姝ｅ湪杩涜鐨勬寫鎴樺崌缁存ā寮?ID
  final String? activeChallengeId;

  /// 宸插畬鎴愮殑鎸戞垬鍗囩淮 ID 闆嗗悎
  final Set<String> completedChallenges;

  /// 宸解鎖的永久解鎖 ID 闆嗗悎
  final Set<String> permanentUnlocks;

  /// 本轮变体词条 ID 列表
  final List<String> runModifiers;

  /// 可用技能点
  final int skillPoints;

  /// 已解锁技能 ID 集合
  final Set<String> unlockedSkills;

  /// 已装配技能 ID（含主动与被动）
  final List<String> equippedSkills;

  /// 资源脉冲冷却结束时间
  final int pulseCooldownEndsAtMs;

  /// 纰庣墖杞崲涓洪浂浠剁殑鍒嗛厤姣斾緥 (0.0 - 1.0)
  /// 鎺у埗鏈夊灏戜骇鐢熺殑纰庣墖浼氳鑷姩閫佸幓杞崲銆?
  final double shardToPartRatio;

  /// 鏄惁淇濈暀鏈€灏忕鐗囧偍澶?
  /// 濡傛灉涓?true锛岃浆鎹㈣繃绋嬩笉浼氭秷鑰椾綆浜?[shardReserveMin] 鐨勭鐗囥€?
  final bool keepShardReserve;

  /// 鑳介噺鍒嗛厤缁欏悎鎴愮郴缁熺殑姣斾緥 (0.0 - 1.0)
  final double energyToSynthesisRatio;

  /// 鏈€灏忕鐗囧偍澶囬噺
  final double shardReserveMin;

  /// 鏃堕棿鎵洸鎶€鑳界粨鏉熸椂闂达紙姣鏃堕棿鎴筹級
  final int timeWarpEndsAtMs;

  /// 鏃堕棿鎵洸鎶€鑳藉喎鍗寸粨鏉熸椂闂达紙姣鏃堕棿鎴筹級
  final int timeWarpCooldownEndsAtMs;

  /// 鏃堕棿鎵洸鎶€鑳界瓑绾?
  final int timeWarpLevel;

  /// 鑳介噺鍒嗛厤浼樺厛绾?
  final EnergyPriorityMode energyPriorityMode;

  /// 璁炬柦甯冨眬鏍硷紙鎸夎灞曞紑鐨勫缓绛?ID锛?
  final List<String?> layoutGrid;

  /// 鎵嬪姩瓒呴鎶€鑳界粨鏉熸椂闂达紙姣鏃堕棿鎴筹級
  final int overclockEndsAtMs;

  /// 鎵嬪姩瓒呴鎶€鑳藉喎鍗寸粨鏉熸椂闂达紙姣鏃堕棿鎴筹級
  final int overclockCooldownEndsAtMs;

  /// 鎵嬪姩瓒呴鎶€鑳界瓑绾?
  final int overclockLevel;

  /// 鑾峰彇鎸囧畾绫诲瀷璧勬簮鐨勬暟閲忥紝榛樿涓?0
  BigNumber resource(ResourceType type) => resources[type] ?? BigNumber.zero;

  double resourceAsDouble(ResourceType type, {double max = 1e308}) {
    return resource(type).toDouble(max: max);
  }

  /// 鑾峰彇鎸囧畾寤虹瓚鐨勬暟閲忥紝榛樿涓?0
  int buildingCount(String id) => buildings[id] ?? 0;

  /// 鍒涘缓褰撳墠鐘舵€佺殑鍓湰锛屽苟鏍规嵁闇€瑕佷慨鏀归儴鍒嗗睘鎬?
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

  /// 娣诲姞涓€鏉℃棩蹇楄褰?
  ///
  /// [title] 鏃ュ織鏍囬
  /// [detail] 鏃ュ織璇︽儏
  /// [maxEntries] 淇濈暀鐨勬渶澶ф棩蹇楁潯鏁帮紝榛樿涓?50
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
    // 濡傛灉鏃ュ織鏁伴噺瓒呰繃闄愬埗锛岀Щ闄ゆ渶鏃╃殑璁板綍
    final trimmed = next.length > maxEntries
        ? next.sublist(next.length - maxEntries)
        : next;
    return copyWith(logEntries: trimmed);
  }

  /// 灏嗘父鎴忕姸鎬佸簭鍒楀寲涓?JSON Map
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

  /// 浠?JSON Map 鍙嶅簭鍒楀寲娓告垙鐘舵€?
  factory GameState.fromJson(Map<String, dynamic> json) {
    final defaults = GameState.initial();
    
    // 瑙ｆ瀽璧勬簮
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

    // 瑙ｆ瀽寤虹瓚
    final buildings = <String, int>{};
    final buildingsMap = json['buildings'];
    if (buildingsMap is Map) {
      for (final entry in buildingsMap.entries) {
        buildings[entry.key.toString()] = (entry.value as num).toInt();
      }
    }

    // 瑙ｆ瀽宸茶喘涔扮殑鐮旂┒
    final researchPurchased = <String>{};
    final researchList = json['researchPurchased'];
    if (researchList is List) {
      for (final entry in researchList) {
        researchPurchased.add(entry.toString());
      }
    }

    // 瑙ｆ瀽宸茶揪鎴愮殑閲岀▼纰?
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

    // 瑙ｆ瀽甯告暟鍗囩骇
    final constantUpgrades = <String, int>{};
    final upgradeMap = json['constantUpgrades'];
    if (upgradeMap is Map) {
      for (final entry in upgradeMap.entries) {
        constantUpgrades[entry.key.toString()] = (entry.value as num).toInt();
      }
    }

    // 瑙ｆ瀽鏃ュ織
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

  /// 鍒濆鍖栨父鎴忕姸鎬侊紙鏂版父鎴忥級
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
        'compressor': 0,
        'furnace': 0,
        'fusion': 0,
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

/// 娓告垙鏃ュ織鏉＄洰绫?
///
/// 璁板綍娓告垙涓殑閲嶈浜嬩欢锛屽杈炬垚閲岀▼纰戙€佸畬鎴愮爺绌剁瓑銆?
@immutable
class GameLogEntry {
  const GameLogEntry({
    required this.title,
    required this.detail,
    required this.timeMs,
  });

  /// 鏍囬
  final String title;
  
  /// 璇︽儏鍐呭
  final String detail;
  
  /// 鍙戠敓鏃堕棿锛堟绉掓椂闂存埑锛?
  final int timeMs;

  /// 搴忓垪鍖栦负 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'detail': detail,
      'timeMs': timeMs,
    };
  }

  /// 鍙嶅簭鍒楀寲
  factory GameLogEntry.fromJson(Map<String, dynamic> json) {
    return GameLogEntry(
      title: json['title']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      timeMs: (json['timeMs'] as num?)?.toInt() ?? 0,
    );
  }
}



