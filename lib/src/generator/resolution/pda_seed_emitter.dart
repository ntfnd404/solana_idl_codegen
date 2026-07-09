import '../../idl.dart';
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
    String indent,
  ) {
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
            (item) => _segmentsMatch(item.name, root),
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
            if (_pathsMatch(candidate.wirePath, path)) {
              account = candidate;
              break;
            }
          }
          if (account != null) {
            out.writeln(
              '${indent}seeds.add(${literals.member(account.path)}!.bytes);',
            );
            return;
          }
          AccountLeaf? sourceAccount;
          for (final candidate in leaves) {
            if (_pathHasPrefix(path, candidate.wirePath) &&
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
          PdaAccountDataSeedEmitter(
            context,
            literals,
          ).emit(out, seed, sourceAccount, index, indent);
        }
    }
  }

  /// Builds the program-address expression used for PDA derivation.
  String pdaProgramExpression(
    IdlSeed? seed,
    IdlInstruction instruction,
    List<AccountLeaf> leaves,
  ) => PdaProgramExpressionEmitter(_literals).emit(seed, instruction, leaves);

  bool _pathsMatch(String left, String right) =>
      _canonicalPath(left) == _canonicalPath(right);

  bool _pathHasPrefix(String raw, String candidate) {
    final rawSegments = raw.split('.');
    final candidateSegments = candidate.split('.');
    if (rawSegments.length <= candidateSegments.length) return false;
    for (var index = 0; index < candidateSegments.length; index++) {
      if (!_segmentsMatch(rawSegments[index], candidateSegments[index])) {
        return false;
      }
    }
    return true;
  }

  bool _segmentsMatch(String left, String right) =>
      _canonicalSegment(left) == _canonicalSegment(right);

  String _canonicalPath(String path) =>
      path.split('.').map(_canonicalSegment).join('.');

  String _canonicalSegment(String value) => value
      .replaceAllMapped(
        RegExp('([a-z0-9])([A-Z])'),
        (match) => '${match[1]}_${match[2]}',
      )
      .replaceAll(RegExp('[^A-Za-z0-9]+'), '_')
      .toLowerCase();
}
