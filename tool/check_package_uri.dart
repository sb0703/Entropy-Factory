import 'dart:io';
import 'dart:isolate';

Future<void> main() async {
  final uri = await Isolate.resolvePackageUri(
    Uri.parse('package:flutter_game_test/game/synergy_rules.dart'),
  );
  stdout.writeln(uri);
  if (uri != null) {
    stdout.writeln(File.fromUri(uri).existsSync());
  }
  final ratio = await Isolate.resolvePackageUri(
    Uri.parse('package:flutter_game_test/ui/widgets/ratio_panel.dart'),
  );
  stdout.writeln(ratio);
  if (ratio != null) {
    stdout.writeln(File.fromUri(ratio).existsSync());
  }
}
