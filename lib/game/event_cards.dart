import 'research_definitions.dart';

class EventCard {
  const EventCard({
    required this.id,
    required this.title,
    required this.description,
    required this.effects,
  });

  final String id;
  final String title;
  final String description;
  final ResearchEffects effects;
}

const List<EventCard> eventCards = [
  EventCard(
    id: 'event_flux_surge',
    title: '能量激增',
    description: '合成能耗 -15%，持续一天',
    effects: ResearchEffects(
      shardProductionMultiplier: 1.0,
      shardCostGrowthOffset: 0.0,
      shardToPartEfficiencyMultiplier: 1.0,
      shardConversionCapacityMultiplier: 1.0,
      blueprintProductionMultiplier: 1.0,
      energyNeedMultiplier: 0.85,
    ),
  ),
  EventCard(
    id: 'event_industry_rush',
    title: '工业冲刺',
    description: '采集与转化产能 +20%，持续一天',
    effects: ResearchEffects(
      shardProductionMultiplier: 1.2,
      shardCostGrowthOffset: 0.0,
      shardToPartEfficiencyMultiplier: 1.0,
      shardConversionCapacityMultiplier: 1.2,
      blueprintProductionMultiplier: 1.0,
      energyNeedMultiplier: 1.0,
    ),
  ),
  EventCard(
    id: 'event_blueprint_burst',
    title: '蓝图爆发',
    description: '蓝图产出 +25%，持续一天',
    effects: ResearchEffects(
      shardProductionMultiplier: 1.0,
      shardCostGrowthOffset: 0.0,
      shardToPartEfficiencyMultiplier: 1.0,
      shardConversionCapacityMultiplier: 1.0,
      blueprintProductionMultiplier: 1.25,
      energyNeedMultiplier: 1.0,
    ),
  ),
];

final Map<String, EventCard> eventCardById = {
  for (final e in eventCards) e.id: e,
};
