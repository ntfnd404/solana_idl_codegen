import '../idl.dart';
import 'discriminator_decoder.dart';
import 'idl_format_exception.dart';
import 'strict_json_reader.dart';
import 'type_decoder.dart';

/// Decodes top-level Anchor account declarations.
final class AnchorAccountDefinitionDecoder {
  /// Creates an account definition decoder.
  const AnchorAccountDefinitionDecoder(
    this.values,
    this.typeDecoder,
    this.discriminatorDecoder,
  );

  /// Strict decoded JSON accessor.
  final StrictJsonReader values;

  /// Decoder used for legacy inline account type definitions.
  final AnchorTypeDecoder typeDecoder;

  /// Decoder used for modern or legacy account discriminators.
  final AnchorDiscriminatorDecoder discriminatorDecoder;

  /// Decodes all account declarations from [rawAccounts].
  ///
  /// Legacy inline account type declarations are appended to [types] when they
  /// are not already present.
  List<IdlAccountDefinition> decodeAll(
    List<Object?> rawAccounts,
    AnchorIdlDialect dialect,
    List<IdlTypeDefinition> types,
  ) {
    final accounts = <IdlAccountDefinition>[];
    for (var index = 0; index < rawAccounts.length; index++) {
      final path =
          r'$.accounts['
          '$index]';
      accounts.add(
        decode(values.object(rawAccounts[index], path), path, dialect, types),
      );
    }
    return accounts;
  }

  /// Decodes one top-level account declaration.
  IdlAccountDefinition decode(
    Map<String, Object?> object,
    String path,
    AnchorIdlDialect dialect,
    List<IdlTypeDefinition> types,
  ) {
    values.knownKeys(object, const {
      'name',
      'docs',
      'discriminator',
      'type',
    }, path);
    final accountName = values.requiredString(object, 'name', '$path.name');
    final inlineType = object['type'];
    if (inlineType != null) {
      _decodeLegacyInlineType(object, path, dialect, accountName, types);
    }
    return IdlAccountDefinition(
      name: accountName,
      discriminator: discriminatorDecoder.decode(
        object,
        dialect: dialect,
        legacyPrefix: 'account',
        name: accountName,
        path: '$path.discriminator',
      ),
      sourcePath: path,
    );
  }

  void _decodeLegacyInlineType(
    Map<String, Object?> object,
    String path,
    AnchorIdlDialect dialect,
    String accountName,
    List<IdlTypeDefinition> types,
  ) {
    if (dialect != AnchorIdlDialect.legacy) {
      throw IdlFormatException(
        'Modern account definitions must reference an entry in types.',
        '$path.type',
      );
    }
    if (types.any((type) => type.name == accountName)) return;
    types.add(
      typeDecoder.definition({
        'name': accountName,
        if (object['docs'] != null) 'docs': object['docs'],
        'type': object['type'],
      }, path),
    );
  }
}
