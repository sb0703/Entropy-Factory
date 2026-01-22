import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_controller.dart';
import '../game/game_state.dart';
import 'effects/particle_layer.dart';
import 'tabs/log_tab.dart';
import 'tabs/prestige_tab.dart';
import 'tabs/production_tab.dart';
import 'tabs/research_tab.dart';
import 'widgets/resource_bar.dart';
import 'widgets/space_background.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  int? _lastOfflineEntryTime;

  final _tabs = const [
    ProductionTab(),
    ResearchTab(),
    PrestigeTab(),
    LogTab(),
  ];

  @override
  Widget build(BuildContext context) {
    // 在构建期监听离线收益日志，避免重复弹窗。
    return Consumer(
      builder: (context, ref, _) {
        ref.listen<GameState>(gameControllerProvider, (previous, next) {
          // 仅取最近的离线收益，且限制触发窗口。
          final entry = _latestOfflineEntry(next);
          if (entry == null) {
            return;
          }
          if (_lastOfflineEntryTime == entry.timeMs) {
            return;
          }
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - entry.timeMs > 120000) {
            return;
          }
          _lastOfflineEntryTime = entry.timeMs;
          _showOfflineGainDialog(entry.detail);
        });

        // 主界面包含背景、资源栏、底部导航与页面栈。
        return Stack(
          children: [
            const SpaceBackground(),
            Scaffold(
              backgroundColor: Colors.transparent,
              bottomNavigationBar: NavigationBar(
                selectedIndex: _currentIndex,
                height: 70,
                backgroundColor: const Color(0xFF0B1321).withAlpha(235),
                indicatorColor: const Color(0xFF5CE1E6).withAlpha(51),
                onDestinationSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.precision_manufacturing_outlined),
                    selectedIcon: Icon(Icons.precision_manufacturing),
                    label: '生产',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.science_outlined),
                    selectedIcon: Icon(Icons.science),
                    label: '研究',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.auto_graph_outlined),
                    selectedIcon: Icon(Icons.auto_graph),
                    label: '升维',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.article_outlined),
                    selectedIcon: Icon(Icons.article),
                    label: '日志',
                  ),
                ],
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    const ResourceBar(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: IndexedStack(
                        index: _currentIndex,
                        children: _tabs,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned.fill(child: ParticleLayer()),
          ],
        );
      },
    );
  }

  GameLogEntry? _latestOfflineEntry(GameState state) {
    for (final entry in state.logEntries.reversed) {
      if (entry.title == '离线收益') {
        return entry;
      }
    }
    return null;
  }

  Future<void> _showOfflineGainDialog(String detail) async {
    if (!mounted) {
      return;
    }
    final formatted = detail.replaceAll('，', '\n');
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('离线收益'),
          content: Text('本次离线期间获得：\n$formatted'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }
}
