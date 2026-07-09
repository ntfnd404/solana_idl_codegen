import 'dart:io';

import 'package:solana_idl_codegen/src/cli/output_transaction.dart';
import 'package:solana_idl_codegen/src/cli/output_transaction_observer.dart';

Future<void> main(List<String> arguments) async {
  final root = Directory(arguments[0]);
  final target = arguments[1];
  final reached = File(arguments[2]);
  final release = arguments[3] == '-' ? null : File(arguments[3]);
  await OutputTransactionWriter(
    observer: _ProcessObserver(reached, release),
  ).write(root, {
    target: '// tool: solana_idl_codegen\n// subprocess\n',
  }, const []);
}

final class _ProcessObserver implements OutputTransactionObserver {
  const _ProcessObserver(this.signal, this.release);

  final File signal;
  final File? release;

  @override
  Future<void> reached(OutputTransactionPhase phase, {int? entryIndex}) async {
    if (phase != OutputTransactionPhase.staged) return;
    await signal.writeAsString('reached', flush: true);
    final releaseFile = release;
    if (releaseFile == null) return;
    while (!await releaseFile.exists()) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }
}
