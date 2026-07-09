/// Durable phases exposed for deterministic transaction interruption tests.
enum OutputTransactionPhase {
  /// Initial recovery manifest has been persisted.
  manifestCreated,

  /// All replacement files have been staged.
  staged,

  /// Existing targets have been moved to backups.
  backedUp,

  /// One replacement target has been installed.
  partialInstall,

  /// Every replacement target has been installed.
  installed,

  /// The transaction has been durably committed.
  committed,
}

/// Observes output transaction phases.
abstract interface class OutputTransactionObserver {
  /// Called after [phase] becomes observable on disk.
  Future<void> reached(OutputTransactionPhase phase, {int? entryIndex});
}

/// Default observer with no side effects.
final class NoopOutputTransactionObserver implements OutputTransactionObserver {
  /// Creates a no-op observer.
  const NoopOutputTransactionObserver();

  @override
  Future<void> reached(OutputTransactionPhase phase, {int? entryIndex}) async {}
}

/// Test-only interruption which intentionally bypasses in-process rollback.
final class OutputTransactionInterruption implements Exception {
  /// Creates a simulated process interruption.
  const OutputTransactionInterruption(this.phase);

  /// Interrupted phase.
  final OutputTransactionPhase phase;
}
