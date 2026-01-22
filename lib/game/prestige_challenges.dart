import 'game_definitions.dart';
import 'game_state.dart';
import 'big_number.dart';

class PrestigeChallenge {
  const PrestigeChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardUnlockId,
    required this.requirementMet,
    this.allowedBuildingTypes,
  });

  final String id;
  final String title;
  final String description;
  final String rewardUnlockId;
  final bool Function(GameState state) requirementMet;
  final Set<BuildingType>? allowedBuildingTypes;
}

class PermanentUnlock {
  const PermanentUnlock({
    required this.id,
    required this.title,
    required this.description,
    this.moduleSlots = 0,
    this.productionBonus = 0,
  });

  final String id;
  final String title;
  final String description;
  final int moduleSlots;
  final double productionBonus;
}

const List<PermanentUnlock> permanentUnlockDefinitions = [
  PermanentUnlock(
    id: 'unlock_module_slot_1',
    title: '永久模块槽 I',
    description: '解锁 1 个永久模块槽（产出 +3%）',
    moduleSlots: 1,
    productionBonus: 0.03,
  ),
  PermanentUnlock(
    id: 'unlock_module_slot_2',
    title: '永久模块槽 II',
    description: '再解锁 1 个永久模块槽（产出 +3%）',
    moduleSlots: 1,
    productionBonus: 0.03,
  ),
  PermanentUnlock(
    id: 'unlock_module_slot_3',
    title: '永久模块槽 III',
    description: '再解锁 1 个永久模块槽（产出 +3%）',
    moduleSlots: 1,
    productionBonus: 0.03,
  ),
];

final Map<String, PermanentUnlock> permanentUnlockById = {
  for (final def in permanentUnlockDefinitions) def.id: def,
};

const List<PrestigeChallenge> prestigeChallenges = [
  PrestigeChallenge(
    id: 'challenge_no_energy',
    title: '断能协议',
    description: '挑战期间禁止建造能量设施，需达到 3 定律完成。',
    rewardUnlockId: 'unlock_module_slot_1',
    requirementMet: _lawsAt3,
    allowedBuildingTypes: {
      BuildingType.shardProducer,
      BuildingType.shardToPart,
      BuildingType.partToBlueprint,
    },
  ),
  PrestigeChallenge(
    id: 'challenge_no_conversion',
    title: '纯净采集',
    description: '挑战期间禁止建造转换设施，需达到 5 定律完成。',
    rewardUnlockId: 'unlock_module_slot_2',
    requirementMet: _lawsAt5,
    allowedBuildingTypes: {
      BuildingType.shardProducer,
      BuildingType.energyProducer,
      BuildingType.partToBlueprint,
    },
  ),
  PrestigeChallenge(
    id: 'challenge_no_synthesis',
    title: '蓝图自律',
    description: '挑战期间禁止建造合成设施，需达到 8 定律完成。',
    rewardUnlockId: 'unlock_module_slot_3',
    requirementMet: _lawsAt8,
    allowedBuildingTypes: {
      BuildingType.shardProducer,
      BuildingType.energyProducer,
      BuildingType.shardToPart,
    },
  ),
];

bool _lawsAt3(GameState state) {
  return state.resource(ResourceType.law) >= BigNumber.fromInt(3);
}

bool _lawsAt5(GameState state) {
  return state.resource(ResourceType.law) >= BigNumber.fromInt(5);
}

bool _lawsAt8(GameState state) {
  return state.resource(ResourceType.law) >= BigNumber.fromInt(8);
}

int unlockedModuleSlots(GameState state) {
  var total = 0;
  for (final id in state.permanentUnlocks) {
    final def = permanentUnlockById[id];
    if (def != null) {
      total += def.moduleSlots;
    }
  }
  return total;
}

double permanentProductionBonus(GameState state) {
  var bonus = 0.0;
  for (final id in state.permanentUnlocks) {
    final def = permanentUnlockById[id];
    if (def != null) {
      bonus += def.productionBonus;
    }
  }
  return bonus;
}
