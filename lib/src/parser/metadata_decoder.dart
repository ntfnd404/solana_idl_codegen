import '../idl.dart';
import 'idl_format_exception.dart';
import 'strict_json_reader.dart';

/// Validates and reads top-level Anchor IDL metadata.
final class AnchorMetadataDecoder {
  /// Creates a metadata decoder using [values] for strict JSON access.
  const AnchorMetadataDecoder(this.values);

  /// Strict decoded JSON accessor.
  final StrictJsonReader values;

  /// Validates known metadata fields and dialect-specific placement rules.
  void validate(Map<String, Object?>? metadata, AnchorIdlDialect dialect) {
    if (metadata == null) return;
    values.knownKeys(metadata, const {
      'name',
      'version',
      'spec',
      'address',
      'description',
      'repository',
      'dependencies',
      'contact',
      'deployments',
    }, r'$.metadata');
    if (dialect == AnchorIdlDialect.modern && metadata.containsKey('address')) {
      throw const IdlFormatException(
        'Modern IDL program address must be top-level.',
        r'$.metadata.address',
        code: 'IDL_DIALECT_MIXED',
      );
    }
    _validateStringMetadata(metadata);
    _validateDependencies(metadata);
    _validateContact(metadata);
    _validateDeployments(metadata);
  }

  void _validateStringMetadata(Map<String, Object?> metadata) {
    for (final entry in metadata.entries) {
      if (const {
            'name',
            'version',
            'spec',
            'address',
            'description',
            'repository',
          }.contains(entry.key) &&
          entry.value != null &&
          entry.value is! String) {
        throw IdlFormatException(
          'Expected a string or null.',
          r'$.metadata.'
              '${entry.key}',
        );
      }
    }
  }

  void _validateDependencies(Map<String, Object?> metadata) {
    if (metadata['dependencies'] case final value?) {
      final dependencies = values.list(value, r'$.metadata.dependencies');
      for (var index = 0; index < dependencies.length; index++) {
        final path =
            r'$.metadata.dependencies['
            '$index]';
        final dependency = values.object(dependencies[index], path);
        values.knownKeys(dependency, const {'name', 'version'}, path);
        values.requiredString(dependency, 'name', '$path.name');
        values.requiredString(dependency, 'version', '$path.version');
      }
    }
  }

  void _validateContact(Map<String, Object?> metadata) {
    if (metadata['contact'] case final value?) {
      values.nonEmptyString(value, r'$.metadata.contact');
    }
  }

  void _validateDeployments(Map<String, Object?> metadata) {
    if (metadata['deployments'] case final value?) {
      final deployments = values.object(value, r'$.metadata.deployments');
      values.knownKeys(deployments, const {
        'mainnet',
        'testnet',
        'devnet',
        'localnet',
      }, r'$.metadata.deployments');
      for (final entry in deployments.entries) {
        values.nonEmptyString(
          entry.value,
          r'$.metadata.deployments.${entry.key}',
        );
      }
    }
  }
}
