import 'dart:io';
import 'dart:isolate';

Future<void> main() async {
  final uri = await Isolate.resolvePackageUri(
    Uri.parse('package:flutter_game_test/ui/production_tab.dart'),
  );
  stdout.writeln(uri);
  if (uri != null) {
    stdout.writeln(File.fromUri(uri).existsSync());
  }
}
