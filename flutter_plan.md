# Entropy Works - Flutter Implementation Plan

## 1. Goals and scope
- Build a single-page Flutter app with a fixed top resource bar and bottom tab navigation.
- Implement the core incremental loop: shards -> parts -> blueprints -> laws -> prestige constants.
- Provide the four primary tabs: Production, Research, Prestige, Log.
- Support offline progress, basic animations, and save/load.

## 2. Non-goals (initial MVP)
- No monetization UI.
- No advanced narrative or late-game systems (star map, challenge mode).
- No cloud sync.

## 3. Tech stack
- Flutter stable (Dart 3.x).
- State management: Riverpod (clean separation of state + testability).
- Persistence: shared_preferences for local save + optional JSON export.
- Timing: Ticker/Timer based game loop with fixed tick delta.

## 4. Architecture
- data/
  - models: resource, building, upgrade, research, milestone, prestige.
  - math: big number, cost and production formulas.
- game/
  - game_state: immutable state, reducers, tick processing.
  - systems: production, conversion, synthesis, energy, prestige, offline.
- ui/
  - screens: production, research, prestige, log.
  - widgets: resource_bar, building_card, ratio_panel, research_grid, prestige_panel, event_list.
  - theme: colors, typography, spacing, animations.
- services/
  - persistence: save/load, export.
  - offline: last_seen, delta calc.

## 5. Data model (core)
- ResourceType: shard, part, blueprint, law, constant, energy.
- ResourceState: amount (BigNumber).
- Building:
  - id, name, group, base_cost, growth, base_prod, unlock_condition.
  - count, enabled, ratio_settings (for converters).
- ResearchNode:
  - id, branch, cost, effect, prereq, status.
- Prestige:
  - law_threshold, constant_formula, retained_flags.

## 6. Game loop and math
- Tick cadence: 1s simulation step, 100ms UI interpolation.
- Production formula:
  - base_prod * count * (1 + sum_add) * product_multipliers.
- Cost formula:
  - base_cost * (growth ^ count).
- BigNumber:
  - mantissa + exponent, format to scientific notation for UI.
- Offline:
  - delta = now - last_seen, capped by offline_limit.
  - simulate only collection + conversion, unless upgraded.

## 7. UI layout plan
- Scaffold with:
  - Top: ResourceBar (fixed).
  - Body: Tab content.
  - BottomNavigationBar: Production, Research, Prestige, Log.
- Production tab:
  - Summary card (rates).
  - Building list (cards with buy1/buy10/buyMax).
  - Ratio panel (slider + toggles + energy split).
- Research tab:
  - Branch tabs (Industrial, Algorithm, Cosmos).
  - Node grid with locked/available/purchased states.
  - Detail panel for selected node.
- Prestige tab:
  - Constant preview card (formula output).
  - Reset list and retained list.
  - Long-press prestige button.
- Log tab:
  - Recent events list (milestones, offline gains).

## 8. Visual style and animations
- Theme:
  - Dark space gradient background + subtle grid texture.
  - Cool primary (cyan/blue) with warm highlight (gold/white).
- Animations (MVP):
  - Resource particle on tap.
  - Building card bounce on purchase.
  - Research node glow on unlock.
  - Prestige screen warp transition.
  - Offline rewards count-up popup.

## 9. Persistence and export
- Save schema:
  - resources, buildings, research, milestones, prestige, timestamps.
- Save on:
  - periodic timer, app pause, and manual export.
- Export:
  - JSON file (optional, dev only).

## 10. Milestones
1) Project setup
   - Create Flutter app, theme, and base navigation.
2) Core game state
   - Resources, buildings, formulas, tick loop.
3) Production UI
   - Building cards, buy buttons, rate summary, ratio panel.
4) Research + Prestige
   - Research grid, effects, prestige flow.
5) Offline + Log
   - Save/load, offline calc, event list.
6) Polish
   - Animations, balancing knobs, QA.

## 11. Assumptions / open questions
- Confirm exact platform target (mobile only or include web).
- Confirm default language (EN only or add CN localization).
- Confirm initial balancing constants for MVP.
