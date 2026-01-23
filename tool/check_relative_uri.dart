import 'dart:io';

void main() {
  final base = File('lib/ui/tabs/production_tab.dart').absolute.uri;
  final resolved = base.resolve('../widgets/ratio_panel.dart');
  stdout.writeln(base);
  stdout.writeln(resolved);
  stdout.writeln(File.fromUri(resolved).existsSync());
}
