import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_game_test/game/game_controller.dart';
import 'package:flutter_game_test/game/game_state.dart';
import 'package:flutter_game_test/ui/effects/particle_layer.dart';
import 'package:flutter_game_test/ui/tabs/log_tab.dart';
import 'package:flutter_game_test/ui/tabs/prestige_tab.dart';
import 'package:flutter_game_test/ui/tabs/production_tab.dart';
import 'package:flutter_game_test/ui/tabs/research_tab.dart';
import 'package:flutter_game_test/ui/tabs/skill_tab.dart';
import 'package:flutter_game_test/ui/widgets/resource_bar.dart';
import 'package:flutter_game_test/ui/widgets/skill_quick_bar.dart';
import 'package:flutter_game_test/ui/widgets/space_background.dart';
import 'package:flutter_game_test/ui/widgets/daily_panel.dart';

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
    SkillTab(),
    PrestigeTab(),
    LogTab(),
  ];

  @override
  Widget build(BuildContext context) {
    // 在构建时监听离线收益日志，避免重复弹窗。
    return Consumer(
      builder: (context, ref, _) {
        ref.listen<GameState>(gameControllerProvider, (previous, next) {
          // 只取最近的离线收益，并限制触发窗口。
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

        // 主界面包含背景、资源条、底部导航与页面容器。
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
                    icon: Icon(Icons.auto_fix_high_outlined),
                    selectedIcon: Icon(Icons.auto_fix_high),
                    label: '技能',
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
                    const DailyPanel(),
                    const ResourceBar(),
                    const SkillQuickBar(),
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
    if (!mounted) return;

    // 1. 数据预处理：把长字符串切分成列表
    // 假设你的 detail 是类似 "金币 +100，经验 +200" 这样的格式
    // 我们先用 '，' 或 '\n' 切割，过滤掉空行
    final List<String> lines = detail
        .replaceAll('，', '\n') // 统一换行符
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // 强迫点击按钮才能关闭，防止误触
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent, // 背景透明，方便自定义形状
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              // 深色科技风背景
              color: const Color(0xFF0F1B2D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF22324A), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5CE1E6).withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- 顶部标题栏 ---
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B2B4B),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bolt,
                        color: Color(0xFFF5C542),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '系统重连 · 离线结算',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFFF5C542),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --- 中间内容列表 ---
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '监测到休眠期间产生的资源堆积：',
                          style: TextStyle(
                            color: const Color(0xFF8FA3BF),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 动态生成资源列表
                        ...lines.map((line) => _buildGainRow(context, line)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- 底部按钮 ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5CE1E6),
                        foregroundColor: const Color(0xFF071018),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '确认接收',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 辅助方法：构建每一行资源
  Widget _buildGainRow(BuildContext context, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF142236),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // 小圆点装饰
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF5CE1E6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // 文本内容
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFE6EDF7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
