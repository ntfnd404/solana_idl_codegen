import 'dart:io';

import 'package:solana_idl_codegen/src/cli.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runCli(arguments);
}
