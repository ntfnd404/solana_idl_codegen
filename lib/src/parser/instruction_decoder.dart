import '../idl.dart';
import 'account_decoder.dart';
import 'discriminator_decoder.dart';
import 'legacy_normalizer.dart';
import 'strict_json_reader.dart';
import 'type_decoder.dart';

/// Decodes one modern or legacy Anchor instruction declaration.
final class AnchorInstructionDecoder {
  /// Creates an instruction decoder from focused wire decoders.
  const AnchorInstructionDecoder(
    this.values,
    this.typeDecoder,
    this.accountDecoder,
    this.discriminatorDecoder,
    this.legacyNormalizer,
  );

  /// Strict JSON value reader.
  final StrictJsonReader values;

  /// Instruction argument and return type decoder.
  final AnchorTypeDecoder typeDecoder;

  /// Nested instruction account decoder.
  final AnchorAccountDecoder accountDecoder;

  /// Modern/legacy discriminator decoder.
  final AnchorDiscriminatorDecoder discriminatorDecoder;

  /// Legacy instruction naming policy.
  final LegacyIdlNormalizer legacyNormalizer;

  /// Decodes [object] at [path].
  IdlInstruction decode(
    Map<String, Object?> object,
    String path,
    AnchorIdlDialect dialect,
  ) {
    values.knownKeys(object, const {
      'name',
      'docs',
      'discriminator',
      'accounts',
      'args',
      'returns',
    }, path);
    final sourceName = values.requiredString(object, 'name', '$path.name');
    final name = dialect == AnchorIdlDialect.legacy
        ? legacyNormalizer.instructionName(sourceName)
        : sourceName;
    final rawAccounts = values.requiredList(
      object,
      'accounts',
      '$path.accounts',
    );
    final rawArguments = values.requiredList(object, 'args', '$path.args');
    return IdlInstruction(
      name: name,
      docs: values.docs(object, 'docs', '$path.docs'),
      discriminator: discriminatorDecoder.decode(
        object,
        dialect: dialect,
        legacyPrefix: 'global',
        name: name,
        path: '$path.discriminator',
      ),
      accounts: accountDecoder.accounts(rawAccounts, '$path.accounts', dialect),
      arguments: typeDecoder.fields(rawArguments, '$path.args'),
      returns: object.containsKey('returns') && object['returns'] != null
          ? typeDecoder.typeExpression(object['returns'], '$path.returns')
          : null,
      sourcePath: path,
    );
  }
}
