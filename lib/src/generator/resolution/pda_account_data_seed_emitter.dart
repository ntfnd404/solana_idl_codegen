import '../../idl.dart';
import '../../idl_path_matcher.dart';
import '../account_leaf.dart';
import '../generator_context.dart';
import 'pda_seed_literals.dart';
import 'pda_typed_seed_emitter.dart';

/// Emits local and external account-data PDA seed resolution code.
final class PdaAccountDataSeedEmitter {
  /// Creates an account-data seed emitter.
  const PdaAccountDataSeedEmitter(this.context, this.literals);

  /// Shared immutable generation context.
  final GeneratorContext context;

  /// Shared generated-code literal helpers.
  final PdaSeedLiterals literals;

  /// Appends account-data seed loading, decoding, and seed-byte extraction.
  void emit(
    StringBuffer out,
    IdlPathSeed seed,
    AccountLeaf sourceAccount,
    int index,
    String indent, {
    required String promotedAddress,
  }) {
    final path = seed.path;
    final accountType = seed.account;
    final definition = accountType == null
        ? null
        : context.program.typesByName[accountType];
    final fieldPath = path
        .split('.')
        .skip(sourceAccount.wirePath.split('.').length)
        .toList(growable: false);
    final isLocalAccount = context.program.accounts.any(
      (account) => account.name == accountType,
    );
    final address = promotedAddress;
    final snapshot = 'seedSnapshot$index';
    out
      ..writeln('${indent}final seedReader$index = context.accountReader;')
      ..write(indent)
      ..writeln('if (seedReader$index == null) {')
      ..writeln(
        "$indent  throw ${literals.type('pda_exception')}(code: 'PDA_ACCOUNT_READER_REQUIRED', message: 'AccountReader is required for account-data PDA seeds.', seedIndex: $index);",
      )
      ..writeln('$indent}')
      ..writeln(
        '$indent final $snapshot = await (seedAccountCache[$address] ??= seedReader$index.readAccount($address, options: context.readOptions));',
      )
      ..write(indent)
      ..writeln('if ($snapshot == null) {')
      ..writeln(
        "$indent  throw ${literals.type('pda_exception')}(code: 'PDA_SOURCE_MISSING', message: 'PDA seed source account does not exist.', seedIndex: $index);",
      )
      ..writeln('$indent}');

    if (isLocalAccount && definition != null && accountType != null) {
      _emitLocalAccountSeed(
        out,
        seed,
        definition,
        accountType,
        fieldPath,
        snapshot,
        index,
        indent,
      );
    } else {
      _emitExternalAccountSeed(
        out,
        seed,
        sourceAccount,
        fieldPath,
        snapshot,
        address,
        index,
        indent,
      );
    }
  }

  void _emitLocalAccountSeed(
    StringBuffer out,
    IdlPathSeed seed,
    IdlTypeDefinition definition,
    String accountType,
    List<String> fieldPath,
    String snapshot,
    int index,
    String indent,
  ) {
    final fieldType = _resolveFieldType(definition, fieldPath);
    if (fieldType == null) {
      throw StateError(
        'Validated account-data seed field is undefined: ${seed.path}.',
      );
    }
    final decoded = 'seedAccount$index';
    out
      ..write(indent)
      ..writeln(
        'if ($snapshot.owner != ${literals.type('program')}.programAddress) {',
      )
      ..writeln(
        "$indent  throw ${literals.type('pda_exception')}(code: 'PDA_SOURCE_OWNER', message: 'PDA seed source account owner mismatch.', seedIndex: $index);",
      )
      ..writeln('$indent}')
      ..writeln(
        '$indent final $decoded = ${literals.type('${accountType}_account')}.decodeAccount($snapshot.data, limits: context.decodeLimits);',
      );
    final expression = [decoded, ...fieldPath.map(literals.member)].join('.');
    PdaTypedSeedEmitter(
      literals,
    ).emit(out, seed.valueType ?? fieldType, expression, index, indent);
  }

  void _emitExternalAccountSeed(
    StringBuffer out,
    IdlPathSeed seed,
    AccountLeaf sourceAccount,
    List<String> fieldPath,
    String snapshot,
    String address,
    int index,
    String indent,
  ) {
    final declaredType = seed.valueType;
    if (declaredType == null) {
      throw StateError(
        'Validated external account seed has no declared type: ${seed.path}.',
      );
    }
    out
      ..writeln(
        '${indent}final externalSeedResolver$index = context.externalAccountSeedResolver;',
      )
      ..write(indent)
      ..writeln('if (externalSeedResolver$index == null) {')
      ..writeln(
        "$indent  throw ${literals.type('pda_exception')}(code: 'PDA_EXTERNAL_RESOLVER_REQUIRED', message: 'ExternalAccountSeedResolver is required.', seedIndex: $index);",
      )
      ..writeln('$indent}')
      ..writeln(
        '${indent}seeds.add(Uint8List.fromList(await externalSeedResolver$index.resolve(',
      )
      ..writeln(
        "$indent  accountPath: '${literals.escape(sourceAccount.wirePath)}',",
      )
      ..writeln(
        "$indent  fieldPath: '${literals.escape(fieldPath.join('.'))}',",
      )
      ..writeln(
        "$indent  declaredType: '${literals.escape(literals.seedTypeName(declaredType))}',",
      )
      ..writeln('$indent  address: $address,')
      ..writeln('$indent  snapshot: $snapshot,')
      ..writeln('$indent)));');
  }

  IdlType? _resolveFieldType(IdlTypeDefinition definition, List<String> path) {
    IdlTypeDefinition current = definition;
    IdlType? result;
    for (var index = 0; index < path.length; index++) {
      final body = current.body;
      if (body is! IdlStructBody || body.fields.isEmpty) return null;
      IdlField? field;
      for (final candidate in body.fields) {
        if (IdlPathMatcher.segmentsMatch(candidate.name, path[index])) {
          field = candidate;
          break;
        }
      }
      if (field == null) return null;
      result = field.type;
      if (index < path.length - 1) {
        final nested = result;
        if (nested is! IdlDefinedType) return null;
        final next = context.program.typesByName[nested.name];
        if (next == null) return null;
        current = next;
      }
    }
    return result;
  }
}
