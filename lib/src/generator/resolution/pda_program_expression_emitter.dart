import '../../idl.dart';
import '../../idl_path_matcher.dart';
import '../account_leaf.dart';
import 'pda_seed_literals.dart';

/// Builds generated expressions for the program used during PDA derivation.
final class PdaProgramExpressionEmitter {
  /// Creates a program-expression emitter using shared [literals].
  const PdaProgramExpressionEmitter(this.literals);

  /// Shared generated-code literal helpers.
  final PdaSeedLiterals literals;

  /// Builds the program-address expression used for PDA derivation.
  String emit(
    IdlSeed? seed,
    IdlInstruction instruction,
    List<AccountLeaf> leaves, {
    required Set<String> promotedAccountPaths,
  }) {
    if (seed == null) return '${literals.type('program')}.programAddress';
    return switch (seed) {
      IdlConstSeed(value: IdlStringConstValue(:final value)) =>
        "${literals.type('address')}.fromBase58('${literals.escape(value)}')",
      IdlConstSeed(value: IdlBytesConstValue(:final value)) =>
        '${literals.type('address')}.fromBytes(${literals.bytes(value)})',
      IdlPathSeed(kind: 'arg', :final path) =>
        'args.${path.split('.').map(literals.member).join('.')}',
      IdlPathSeed(kind: 'account', :final path) => _accountExpression(
        path,
        leaves,
        promotedAccountPaths,
      ),
      _ => '${literals.type('program')}.programAddress',
    };
  }

  String _accountExpression(
    String path,
    List<AccountLeaf> leaves,
    Set<String> promotedAccountPaths,
  ) {
    final account = leaves.firstWhere(
      (item) => IdlPathMatcher.pathsMatch(item.wirePath, path),
    );
    if (!promotedAccountPaths.contains(account.wirePath)) {
      throw StateError('PDA program dependency is not promoted: $path.');
    }
    return literals.member(account.path);
  }
}
