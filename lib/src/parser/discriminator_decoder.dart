import '../idl.dart';
import 'idl_format_exception.dart';
import 'legacy_normalizer.dart';
import 'strict_json_reader.dart';

/// Decodes explicit modern discriminators and computes legacy discriminators.
final class AnchorDiscriminatorDecoder {
  /// Creates a discriminator decoder from strict wire dependencies.
  const AnchorDiscriminatorDecoder(this.values, this.legacyNormalizer);

  /// Strict JSON value reader.
  final StrictJsonReader values;

  /// Legacy discriminator computation policy.
  final LegacyIdlNormalizer legacyNormalizer;

  /// Decodes the discriminator owned by [owner].
  List<int> decode(
    Map<String, Object?> owner, {
    required AnchorIdlDialect dialect,
    required String legacyPrefix,
    required String name,
    required String path,
  }) {
    if (!owner.containsKey('discriminator') || owner['discriminator'] == null) {
      if (dialect == AnchorIdlDialect.modern) {
        throw IdlFormatException('Modern IDL discriminator is required.', path);
      }
      return legacyNormalizer.discriminator(legacyPrefix, name);
    }
    final raw = values.list(owner['discriminator'], path);
    if (raw.isEmpty) {
      throw IdlFormatException('Discriminator cannot be empty.', path);
    }
    return List<int>.unmodifiable([
      for (var index = 0; index < raw.length; index++)
        values.byte(raw[index], '$path[$index]'),
    ]);
  }
}
