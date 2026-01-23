import 'dart:io';

void main() {
  final base = Uri.parse('package:flutter_game_test/ui/home_shell.dart');
  final resolved = base.resolve('tabs/production_tab.dart');
  stdout.writeln(resolved);
}
