import '../idl.dart';
import 'idl_format_exception.dart';
import 'pda_seed_decoder.dart';
import 'strict_json_reader.dart';
import 'type_decoder.dart';

/// Decodes PDA metadata for one instruction account.
final class AnchorAccountPdaDecoder {
  /// Creates a PDA metadata decoder.
  const AnchorAccountPdaDecoder(this.values, this.types);

  /// Strict JSON value reader.
  final StrictJsonReader values;

  /// Anchor type expression decoder used by PDA seed declarations.
  final AnchorTypeDecoder types;

  /// Decodes PDA seeds for [object].
  List<IdlSeed> seeds(
    Map<String, Object?> object,
    String path,
    AnchorIdlDialect dialect,
  ) {
    final pda = _pdaObject(object, path, dialect);
    final rawSeeds = pda == null
        ? const <Object?>[]
        : values.requiredList(pda, 'seeds', '$path.pda.seeds');
    return [
      for (var index = 0; index < rawSeeds.length; index++)
        _seed(
          values.object(rawSeeds[index], '$path.pda.seeds[$index]'),
          '$path.pda.seeds[$index]',
        ),
    ];
  }

  /// Decodes an optional PDA program seed for [object].
  IdlSeed? programSeed(
    Map<String, Object?> object,
    String path,
    AnchorIdlDialect dialect,
  ) {
    final pda = _pdaObject(object, path, dialect);
    if (pda == null || (pda['program'] ?? pda['programId']) == null) {
      return null;
    }
    return _seed(
      values.object(
        pda['program'] ?? pda['programId'],
        dialect == AnchorIdlDialect.modern
            ? '$path.pda.program'
            : '$path.pda.programId',
      ),
      dialect == AnchorIdlDialect.modern
          ? '$path.pda.program'
          : '$path.pda.programId',
    );
  }

  Map<String, Object?>? _pdaObject(
    Map<String, Object?> object,
    String path,
    AnchorIdlDialect dialect,
  ) {
    final pda = values.optionalObject(object, 'pda', '$path.pda');
    if (pda == null) return null;
    values.knownKeys(pda, const {'seeds', 'program', 'programId'}, '$path.pda');
    if (dialect == AnchorIdlDialect.modern && pda.containsKey('programId')) {
      throw IdlFormatException(
        'Modern IDL uses "program", not legacy "programId".',
        '$path.pda.programId',
        code: 'IDL_DIALECT_MIXED',
      );
    }
    if (dialect == AnchorIdlDialect.legacy && pda.containsKey('program')) {
      throw IdlFormatException(
        'Legacy IDL uses "programId", not modern "program".',
        '$path.pda.program',
        code: 'IDL_DIALECT_MIXED',
      );
    }
    return pda;
  }

  IdlSeed _seed(Map<String, Object?> object, String path) {
    return AnchorPdaSeedDecoder(values, types).seed(object, path);
  }
}
