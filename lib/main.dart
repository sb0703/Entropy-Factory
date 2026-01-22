import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/save_service.dart';
import 'theme/app_theme.dart';
import 'ui/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await SaveService.init();
  runApp(const ProviderScope(child: EntropyWorksApp()));
}

class EntropyWorksApp extends StatelessWidget {
  const EntropyWorksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '熵工厂',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HomeShell(),
    );
  }
}
