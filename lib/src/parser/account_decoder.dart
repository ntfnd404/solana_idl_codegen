import '../idl.dart';
import 'account_flag_decoder.dart';
import 'account_pda_decoder.dart';
import 'idl_format_exception.dart';
import 'strict_json_reader.dart';
import 'type_decoder.dart';

/// Decodes nested instruction-account trees and their PDA metadata.
final class AnchorAccountDecoder {
  /// Creates an account decoder.
  const AnchorAccountDecoder(
    this.values,
    this.types, {
    this.flags = const AnchorAccountFlagDecoder(StrictJsonReader()),
    this.pdaDecoder = const AnchorAccountPdaDecoder(
      StrictJsonReader(),
      AnchorTypeDecoder(StrictJsonReader()),
    ),
  });

  /// Strict JSON value reader.
  final StrictJsonReader values;

  /// Anchor type expression decoder used by PDA seed declarations.
  final AnchorTypeDecoder types;

  /// Decoder for modern/legacy boolean aliases.
  final AnchorAccountFlagDecoder flags;

  /// Decoder for PDA metadata.
  final AnchorAccountPdaDecoder pdaDecoder;

  /// Decodes an ordered nested instruction-account list.
  List<IdlInstructionAccount> accounts(
    List<Object?> raw,
    String path,
    AnchorIdlDialect dialect,
  ) => [
    for (var index = 0; index < raw.length; index++)
      _account(
        values.object(raw[index], '$path[$index]'),
        '$path[$index]',
        dialect,
      ),
  ];

  IdlInstructionAccount _account(
    Map<String, Object?> object,
    String path,
    AnchorIdlDialect dialect,
  ) {
    values.knownKeys(object, const {
      'name',
      'docs',
      'accounts',
      'writable',
      'signer',
      'optional',
      'isMut',
      'isSigner',
      'isOptional',
      'address',
      'relations',
      'pda',
    }, path);
    final name = values.requiredString(object, 'name', '$path.name');
    final modernFlags = const {'writable', 'signer', 'optional'};
    final legacyFlags = const {'isMut', 'isSigner', 'isOptional'};
    final forbiddenDialectFields = dialect == AnchorIdlDialect.modern
        ? legacyFlags
        : modernFlags;
    for (final key in forbiddenDialectFields) {
      if (object.containsKey(key)) {
        throw IdlFormatException(
          'Field "$key" belongs to the other IDL dialect.',
          '$path.$key',
          code: 'IDL_DIALECT_MIXED',
        );
      }
    }
    if (object.containsKey('accounts')) {
      for (final forbidden in const {
        'writable',
        'signer',
        'optional',
        'isMut',
        'isSigner',
        'isOptional',
        'address',
        'relations',
        'pda',
      }) {
        if (object.containsKey(forbidden)) {
          throw IdlFormatException(
            'Account groups cannot declare "$forbidden".',
            '$path.$forbidden',
          );
        }
      }
      return IdlAccountGroup(
        name: name,
        docs: values.docs(object, 'docs', '$path.docs'),
        accounts: accounts(
          values.requiredList(object, 'accounts', '$path.accounts'),
          '$path.accounts',
          dialect,
        ),
        sourcePath: path,
      );
    }

    final relations = values.optionalList(
      object,
      'relations',
      '$path.relations',
    );
    return IdlAccountItem(
      name: name,
      docs: values.docs(object, 'docs', '$path.docs'),
      writable: flags.aliasedBoolean(
        object,
        modern: 'writable',
        legacy: 'isMut',
        path: path,
      ),
      signer: flags.aliasedBoolean(
        object,
        modern: 'signer',
        legacy: 'isSigner',
        path: path,
      ),
      optional: flags.aliasedBoolean(
        object,
        modern: 'optional',
        legacy: 'isOptional',
        path: path,
      ),
      address: values.optionalString(object, 'address', '$path.address'),
      relations: [
        for (var index = 0; index < relations.length; index++)
          values.nonEmptyString(relations[index], '$path.relations[$index]'),
      ],
      seeds: pdaDecoder.seeds(object, path, dialect),
      pdaProgram: pdaDecoder.programSeed(object, path, dialect),
      sourcePath: path,
    );
  }
}
