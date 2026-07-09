import 'dart:io';

import 'canonical_path.dart';
import 'generated_output_scanner.dart';
import 'output_lock.dart';
import 'output_recovery_exception.dart';
import 'output_transaction_observer.dart';
import 'recovery_manager.dart';
import 'transaction_manifest.dart';

export 'output_recovery_exception.dart' show OutputRecoveryException;

/// Transactional, process-safe writer for generated output trees.
final class OutputTransactionWriter {
  /// Creates a writer from replaceable filesystem policies.
  const OutputTransactionWriter({
    this.scanner = const GeneratedOutputScanner(),
    this.paths = const CanonicalPathResolver(),
    this.lock = const OutputLock(),
    this.observer = const NoopOutputTransactionObserver(),
  });

  /// Ownership policy used to protect handwritten files.
  final GeneratedOutputScanner scanner;

  /// Canonical path policy.
  final CanonicalPathResolver paths;

  /// Cross-process lock service.
  final OutputLock lock;

  /// Optional phase observer used by deterministic interruption tests.
  final OutputTransactionObserver observer;

  RecoveryManager get _recovery => RecoveryManager(scanner: scanner);

  /// Recovers an interrupted transaction, if present.
  Future<void> recover(Directory root) async {
    await root.create(recursive: true);
    final canonical = await paths.resolveDirectory(root);
    await lock.synchronized(
      canonical,
      () => _recovery.recoverLocked(canonical),
    );
  }

  /// Verifies that no interrupted transaction exists without changing files.
  Future<void> verifyNoPendingRecovery(Directory root) async {
    if (!await root.exists()) return;
    final canonical = await paths.resolveDirectory(root);
    await lock.synchronized(canonical, () async {
      if (await _recovery.manifestFile(canonical).exists()) {
        throw const OutputRecoveryException(
          'A pending transaction requires a normal generate or clean run.',
        );
      }
    });
  }

  /// Atomically replaces [planned] and removes scoped [stale] outputs.
  Future<void> write(
    Directory root,
    Map<String, String> planned,
    Iterable<File> stale,
  ) async {
    await root.create(recursive: true);
    final canonical = await paths.resolveDirectory(root);
    await lock.synchronized(canonical, () async {
      await _recovery.recoverLocked(canonical);
      await _writeLocked(canonical, planned, stale);
    });
  }

  Future<void> _writeLocked(
    String canonicalRoot,
    Map<String, String> planned,
    Iterable<File> stale,
  ) async {
    final token = '${pid}_${DateTime.now().microsecondsSinceEpoch}';
    final targets = <String, TransactionEntry>{};
    for (final target in planned.keys) {
      final normalized = paths.requireInside(canonicalRoot, target);
      targets[normalized] = TransactionEntry(
        target: normalized,
        staged: '$normalized.solana-idl-stage-$token',
        backup: '$normalized.solana-idl-backup-$token',
        install: true,
        hadOriginal: await File(normalized).exists(),
      );
    }
    for (final file in stale) {
      final normalized = paths.requireInside(canonicalRoot, file.path);
      targets.putIfAbsent(
        normalized,
        () => TransactionEntry(
          target: normalized,
          staged: null,
          backup: '$normalized.solana-idl-backup-$token',
          install: false,
          hadOriginal: true,
        ),
      );
    }
    for (final entry in targets.values) {
      final target = File(entry.target);
      if (entry.hadOriginal && !await scanner.isOwned(target)) {
        throw FileSystemException(
          'Refusing to replace a file not owned by solana_idl_codegen.',
          target.path,
        );
      }
    }

    final manifestFile = _recovery.manifestFile(canonicalRoot);
    final manifest = TransactionManifest(
      token: token,
      phase: 'preparing',
      entries: targets.values.toList(growable: false),
    );
    await _recovery.writeManifest(manifestFile, manifest);
    await observer.reached(OutputTransactionPhase.manifestCreated);
    try {
      for (final entry in targets.values.where((entry) => entry.install)) {
        final staged = File(entry.staged!);
        await staged.parent.create(recursive: true);
        await staged.writeAsString(
          planned[entry.target]!
              .replaceAll('\r\n', '\n')
              .replaceAll('\r', '\n'),
          flush: true,
        );
      }
      await _recovery.writeManifest(manifestFile, manifest.withPhase('staged'));
      await observer.reached(OutputTransactionPhase.staged);
      for (final entry in targets.values) {
        final target = File(entry.target);
        if (await target.exists()) await target.rename(entry.backup);
      }
      await _recovery.writeManifest(
        manifestFile,
        manifest.withPhase('backedUp'),
      );
      await observer.reached(OutputTransactionPhase.backedUp);
      var installed = 0;
      for (final entry in targets.values.where((entry) => entry.install)) {
        await File(entry.staged!).rename(entry.target);
        await observer.reached(
          OutputTransactionPhase.partialInstall,
          entryIndex: installed++,
        );
      }
      await _recovery.writeManifest(
        manifestFile,
        manifest.withPhase('installed'),
      );
      await observer.reached(OutputTransactionPhase.installed);
      await _recovery.writeManifest(
        manifestFile,
        manifest.withPhase('committed'),
      );
      await observer.reached(OutputTransactionPhase.committed);
      await _recovery.finishCommit(manifestFile, manifest);
    } on OutputTransactionInterruption {
      rethrow;
    } on Object {
      await _recovery.rollback(manifestFile, manifest);
      rethrow;
    }
  }
}
