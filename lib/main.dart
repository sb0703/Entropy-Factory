import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import 'ui/home_shell.dart';

void main() {
  // 确保插件初始化后再启动应用。
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: EntropyWorksApp()));
}

class EntropyWorksApp extends StatelessWidget {
  const EntropyWorksApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 根入口仅负责主题与首页容器。
    return MaterialApp(
      title: '熵工厂',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HomeShell(),
    );
  }
}
