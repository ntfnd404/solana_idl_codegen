import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'generated_output_scanner.dart';
import 'output_recovery_exception.dart';
import 'transaction_manifest.dart';

/// Restores or completes durable generated-output transactions.
final class RecoveryManager {
  /// Creates a recovery manager.
  const RecoveryManager({this.scanner = const GeneratedOutputScanner()});

  /// Ownership policy protecting handwritten files.
  final GeneratedOutputScanner scanner;

  /// Recovery manifest inside [canonicalRoot].
  File manifestFile(String canonicalRoot) =>
      File(path.join(canonicalRoot, '.solana_idl_codegen.recovery.json'));

  /// Reads and resolves a pending transaction while the caller holds its lock.
  Future<void> recoverLocked(String canonicalRoot) async {
    final file = manifestFile(canonicalRoot);
    if (!await file.exists()) return;
    try {
      final decoded = jsonDecode(await file.readAsString());
      final manifest = TransactionManifest.fromJson(
        decoded,
        canonicalRoot: canonicalRoot,
      );
      if (manifest.phase == 'committed') {
        await finishCommit(file, manifest);
      } else {
        await rollback(file, manifest);
      }
    } on OutputRecoveryException {
      rethrow;
    } on Object catch (error) {
      throw OutputRecoveryException(
        'The recovery manifest is invalid and was left untouched.',
        error,
      );
    }
  }

  /// Rolls back [manifest] and removes it.
  Future<void> rollback(File manifestFile, TransactionManifest manifest) async {
    try {
      for (final entry in manifest.entries.reversed) {
        final target = File(entry.target);
        final backup = File(entry.backup);
        if (await backup.exists()) {
          if (await target.exists()) {
            if (!await scanner.isOwned(target)) {
              throw OutputRecoveryException(
                'Refusing to replace foreign file ${target.path}.',
              );
            }
            await target.delete();
          }
          await backup.rename(target.path);
        } else if (!entry.hadOriginal && await target.exists()) {
          if (!await scanner.isOwned(target)) {
            throw OutputRecoveryException(
              'Refusing to remove foreign file ${target.path}.',
            );
          }
          await target.delete();
        }
        final stagedPath = entry.staged;
        if (stagedPath != null) {
          final staged = File(stagedPath);
          if (await staged.exists()) await staged.delete();
        }
      }
      if (await manifestFile.exists()) await manifestFile.delete();
    } on OutputRecoveryException {
      rethrow;
    } on Object catch (error) {
      throw OutputRecoveryException('Rollback did not complete.', error);
    }
  }

  /// Removes transaction artifacts after a durable commit.
  Future<void> finishCommit(
    File manifestFile,
    TransactionManifest manifest,
  ) async {
    try {
      for (final entry in manifest.entries) {
        final backup = File(entry.backup);
        if (await backup.exists()) await backup.delete();
        final stagedPath = entry.staged;
        if (stagedPath != null) {
          final staged = File(stagedPath);
          if (await staged.exists()) await staged.delete();
        }
      }
      if (await manifestFile.exists()) await manifestFile.delete();
    } on Object catch (error) {
      throw OutputRecoveryException('Commit cleanup did not complete.', error);
    }
  }

  /// Persists [manifest].
  Future<void> writeManifest(File file, TransactionManifest manifest) =>
      file.writeAsString(jsonEncode(manifest.toJson()), flush: true);
}
