import '../../idl.dart';
import '../../idl_path_matcher.dart';
import '../account_leaf.dart';
import '../generator_context.dart';
import 'pda_account_data_seed_emitter.dart';
import 'pda_integer_seed_emitter.dart';
import 'pda_program_expression_emitter.dart';
import 'pda_seed_literals.dart';
import 'pda_typed_seed_emitter.dart';

/// Emits validated typed PDA seed encoding statements.
final class PdaSeedEmitter {
  /// Creates a PDA seed emitter for [context].
  const PdaSeedEmitter(this.context);

  /// Shared immutable generation context.
  final GeneratorContext context;

  PdaSeedLiterals get _literals => PdaSeedLiterals(context);

  /// Appends encoding statements for one validated [seed].
  void emitSeed(
    StringBuffer out,
    IdlInstruction instruction,
    List<AccountLeaf> leaves,
    IdlSeed seed,
    int index,
    String indent, {
    required Set<String> promotedAccountPaths,
  }) {
    final literals = _literals;
    switch (seed) {
      case IdlConstSeed(:final value, :final valueType):
        switch (value) {
          case IdlBytesConstValue(:final value):
            out.writeln(
              '${indent}seeds.add(Uint8List.fromList(${literals.bytes(value)}));',
            );
          case IdlStringConstValue(:final value):
            out.writeln(
              "${indent}seeds.add(Uint8List.fromList(utf8.encode('${literals.escape(value)}')));",
            );
          case IdlBooleanConstValue(:final value):
            out.writeln(
              '${indent}seeds.add(Uint8List.fromList(<int>[${value ? 1 : 0}]));',
            );
          case IdlIntegerConstValue(:final value):
            PdaIntegerSeedEmitter(literals).emit(
              out,
              valueType,
              value.toString(),
              index,
              indent,
              constant: true,
            );
        }
      case IdlPathSeed(:final kind, :final path, :final valueType):
        if (kind == 'arg') {
          final root = path.split('.').first;
          final argument = instruction.arguments.firstWhere(
            (item) => IdlPathMatcher.segmentsMatch(item.name, root),
          );
          final expression = [
            'args',
            context.fieldMember(instruction.arguments, argument),
            ...path.split('.').skip(1).map(literals.member),
          ].join('.');
          PdaTypedSeedEmitter(
            literals,
          ).emit(out, valueType ?? argument.type, expression, index, indent);
        } else {
          AccountLeaf? account;
          for (final candidate in leaves) {
            if (IdlPathMatcher.pathsMatch(candidate.wirePath, path)) {
              account = candidate;
              break;
            }
          }
          if (account != null) {
            _requirePromoted(account, promotedAccountPaths, path);
            out.writeln(
              '${indent}seeds.add(${literals.member(account.path)}.bytes);',
            );
            return;
          }
          AccountLeaf? sourceAccount;
          for (final candidate in leaves) {
            if (IdlPathMatcher.pathHasPrefix(path, candidate.wirePath) &&
                (sourceAccount == null ||
                    candidate.wirePath.length >
                        sourceAccount.wirePath.length)) {
              sourceAccount = candidate;
            }
          }
          if (sourceAccount == null) {
            throw StateError(
              'Validated account-data seed has no source account: $path.',
            );
          }
          _requirePromoted(sourceAccount, promotedAccountPaths, path);
          PdaAccountDataSeedEmitter(context, literals).emit(
            out,
            seed,
            sourceAccount,
            index,
            indent,
            promotedAddress: literals.member(sourceAccount.path),
          );
        }
    }
  }

  /// Builds the program-address expression used for PDA derivation.
  String pdaProgramExpression(
    IdlSeed? seed,
    IdlInstruction instruction,
    List<AccountLeaf> leaves, {
    required Set<String> promotedAccountPaths,
  }) => PdaProgramExpressionEmitter(
    _literals,
  ).emit(seed, instruction, leaves, promotedAccountPaths: promotedAccountPaths);

  void _requirePromoted(
    AccountLeaf account,
    Set<String> promotedAccountPaths,
    String seedPath,
  ) {
    if (!promotedAccountPaths.contains(account.wirePath)) {
      throw StateError('PDA account dependency is not promoted: $seedPath.');
    }
  }
}
