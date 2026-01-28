part of 'game_controller.dart';

extension LayoutOps on GameController {
  void placeBuildingInLayout(String buildingId, int index) {
    if (!_simState.isLayoutUnlocked) {
      return;
    }
    if (index < 0 || index >= _simState.layoutGrid.length) {
      return;
    }
    if (!_simState.isLayoutSlotUnlocked(index)) {
      return;
    }
    if (!buildingById.containsKey(buildingId)) {
      return;
    }
    final layout = List<String?>.from(_simState.layoutGrid);
    final placedCounts = _placedCounts(layout);
    final current = layout[index];
    if (current == buildingId) {
      return;
    }
    if (current != null) {
      placedCounts[current] = math.max(0, (placedCounts[current] ?? 1) - 1);
      layout[index] = null;
    }
    if (_simState.runModifiers.contains(runModifierHeavyFootprint) &&
        current == null) {
      final maxPlacements = _simState.layoutUnlockedCount ~/ 2;
      final placedTotal = _placedCountInUnlocked(layout, _simState);
      if (placedTotal >= maxPlacements) {
        _commitState(_simState.copyWith(layoutGrid: layout));
        return;
      }
    }
    final totalOwned = _simState.buildingCount(buildingId);
    final used = placedCounts[buildingId] ?? 0;
    if (totalOwned - used <= 0) {
      _commitState(_simState.copyWith(layoutGrid: layout));
      return;
    }
    layout[index] = buildingId;
    _commitState(_simState.copyWith(layoutGrid: layout));
  }

  void clearLayoutSlot(int index) {
    if (!_simState.isLayoutUnlocked) {
      return;
    }
    if (index < 0 || index >= _simState.layoutGrid.length) {
      return;
    }
    if (!_simState.isLayoutSlotUnlocked(index)) {
      return;
    }
    final layout = List<String?>.from(_simState.layoutGrid);
    layout[index] = null;
    _commitState(_simState.copyWith(layoutGrid: layout));
  }

  void moveLayoutSlot(int from, int to) {
    if (!_simState.isLayoutUnlocked) {
      return;
    }
    if (from < 0 ||
        to < 0 ||
        from >= _simState.layoutGrid.length ||
        to >= _simState.layoutGrid.length) {
      return;
    }
    if (!_simState.isLayoutSlotUnlocked(from) ||
        !_simState.isLayoutSlotUnlocked(to)) {
      return;
    }
    final layout = List<String?>.from(_simState.layoutGrid);
    final fromVal = layout[from];
    final toVal = layout[to];
    if (fromVal == null && toVal == null) {
      return;
    }
    layout[from] = toVal;
    layout[to] = fromVal;
    _commitState(_simState.copyWith(layoutGrid: layout));
  }

  Map<String, int> _placedCounts(List<String?> layout) {
    final counts = <String, int>{};
    for (final id in layout) {
      if (id == null) continue;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  int _placedCountInUnlocked(List<String?> layout, GameState state) {
    var count = 0;
    for (var i = 0; i < layout.length; i++) {
      if (!state.isLayoutSlotUnlocked(i)) continue;
      if (layout[i] != null) {
        count++;
      }
    }
    return count;
  }
}
