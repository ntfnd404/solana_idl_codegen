import 'package:path/path.dart' as path;

import 'output_recovery_exception.dart';

/// One target participating in a generated-output transaction.
final class TransactionEntry {
  /// Creates a transaction entry.
  const TransactionEntry({
    required this.target,
    required this.staged,
    required this.backup,
    required this.install,
    required this.hadOriginal,
  });

  /// Decodes and validates one manifest entry.
  factory TransactionEntry.fromJson(
    Object? value, {
    required String canonicalRoot,
    required String token,
  }) {
    if (value is! Map<String, Object?>) {
      throw const OutputRecoveryException('Invalid transaction entry.');
    }
    final target = _safePath(value['target'], canonicalRoot);
    final stagedValue = value['staged'];
    final staged = stagedValue == null
        ? null
        : _safePath(stagedValue, canonicalRoot);
    final backup = _safePath(value['backup'], canonicalRoot);
    final install = value['install'];
    final hadOriginal = value['hadOriginal'];
    if (install is! bool ||
        hadOriginal is! bool ||
        backup != '$target.solana-idl-backup-$token' ||
        (staged != null && staged != '$target.solana-idl-stage-$token')) {
      throw const OutputRecoveryException('Invalid transaction entry fields.');
    }
    return TransactionEntry(
      target: target,
      staged: staged,
      backup: backup,
      install: install,
      hadOriginal: hadOriginal,
    );
  }

  /// Final output path.
  final String target;

  /// Staged output path, when [install] is true.
  final String? staged;

  /// Rollback backup path.
  final String backup;

  /// Whether a new target is installed rather than only removed.
  final bool install;

  /// Whether [target] existed before the transaction.
  final bool hadOriginal;

  /// Encodes this entry for the recovery manifest.
  Map<String, Object?> toJson() => {
    'target': target,
    'staged': staged,
    'backup': backup,
    'install': install,
    'hadOriginal': hadOriginal,
  };

  static String _safePath(Object? value, String root) {
    if (value is! String) {
      throw const OutputRecoveryException('Transaction path is not a string.');
    }
    final normalized = path.normalize(path.absolute(value));
    if (!path.isWithin(root, normalized)) {
      throw const OutputRecoveryException('Transaction path escapes root.');
    }
    return normalized;
  }
}

/// Versioned recovery manifest for one output transaction.
final class TransactionManifest {
  /// Creates a recovery manifest.
  const TransactionManifest({
    required this.token,
    required this.phase,
    required this.entries,
  });

  /// Decodes and validates a recovery manifest.
  factory TransactionManifest.fromJson(
    Object? value, {
    required String canonicalRoot,
  }) {
    if (value is! Map<String, Object?> ||
        value['version'] != 1 ||
        value['token'] is! String ||
        value['phase'] is! String ||
        value['entries'] is! List<Object?>) {
      throw const OutputRecoveryException('Invalid recovery manifest shape.');
    }
    final token = value['token']! as String;
    if (!RegExp(r'^[0-9]+_[0-9]+$').hasMatch(token)) {
      throw const OutputRecoveryException('Invalid recovery token.');
    }
    final phase = value['phase']! as String;
    if (!const {
      'preparing',
      'staged',
      'backedUp',
      'installed',
      'committed',
    }.contains(phase)) {
      throw const OutputRecoveryException('Invalid recovery phase.');
    }
    return TransactionManifest(
      token: token,
      phase: phase,
      entries: [
        for (final entry in value['entries']! as List<Object?>)
          TransactionEntry.fromJson(
            entry,
            canonicalRoot: canonicalRoot,
            token: token,
          ),
      ],
    );
  }

  /// Unique transaction token.
  final String token;

  /// Last durable transaction phase.
  final String phase;

  /// Ordered transaction entries.
  final List<TransactionEntry> entries;

  /// Returns this manifest at another durable [phase].
  TransactionManifest withPhase(String phase) =>
      TransactionManifest(token: token, phase: phase, entries: entries);

  /// Encodes this manifest.
  Map<String, Object?> toJson() => {
    'version': 1,
    'token': token,
    'phase': phase,
    'entries': entries.map((entry) => entry.toJson()).toList(),
  };
}
