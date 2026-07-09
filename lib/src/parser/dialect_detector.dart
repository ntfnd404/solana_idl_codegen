import '../idl.dart';
import 'idl_format_exception.dart';

/// Selects a supported Anchor IDL dialect from explicit schema markers.
final class AnchorDialectDetector {
  /// Creates a dialect detector.
  const AnchorDialectDetector();

  /// Detects modern, legacy, mixed and unknown documents.
  AnchorIdlDialect detect(
    Map<String, Object?> json,
    Map<String, Object?>? metadata,
  ) {
    final hasSpec = metadata?.containsKey('spec') ?? false;
    final rawSpec = metadata?['spec'];
    final hasLegacyMarkers =
        json.containsKey('name') || json.containsKey('version');
    final hasModernMarkers =
        json.containsKey('address') ||
        (metadata?.containsKey('name') ?? false) ||
        (metadata?.containsKey('version') ?? false);
    if (hasSpec && hasLegacyMarkers) {
      throw const IdlFormatException(
        'IDL mixes modern metadata.spec with legacy top-level name/version.',
        r'$',
        code: 'IDL_DIALECT_MIXED',
      );
    }
    if (!hasSpec && !hasLegacyMarkers) {
      throw IdlFormatException(
        hasModernMarkers
            ? 'Modern IDL shape requires metadata.spec.'
            : 'IDL dialect cannot be determined from its schema shape.',
        hasModernMarkers ? r'$.metadata.spec' : r'$',
        code: hasModernMarkers
            ? 'IDL_DIALECT_MODERN_SPEC_MISSING'
            : 'IDL_DIALECT_UNKNOWN',
      );
    }
    if (hasSpec && rawSpec != '0.1.0') {
      throw IdlFormatException(
        'Unsupported Anchor IDL specification "$rawSpec".',
        r'$.metadata.spec',
        code: 'IDL_DIALECT_UNSUPPORTED',
      );
    }
    return hasSpec ? AnchorIdlDialect.modern : AnchorIdlDialect.legacy;
  }
}
