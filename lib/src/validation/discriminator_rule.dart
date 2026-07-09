import 'validation_issue.dart';

/// Validates discriminator bytes and namespace prefix safety.
final class DiscriminatorValidationRule {
  /// Creates the stateless discriminator rule.
  const DiscriminatorValidationRule();

  /// Validates one discriminator.
  void validate(List<int> bytes, String path, ValidationIssue issue) {
    if (bytes.isEmpty) {
      issue(
        'IDL_DISCRIMINATOR_EMPTY',
        'Discriminator must contain at least one byte.',
        '$path.discriminator',
      );
    }
    for (final byte in bytes) {
      if (byte < 0 || byte > 255) {
        issue(
          'IDL_DISCRIMINATOR_BYTE',
          'Discriminator values must be bytes.',
          '$path.discriminator',
        );
      }
    }
  }

  /// Rejects prefix-ambiguous discriminators within [namespace].
  void validatePrefixes(
    List<(String, List<int>, String)> entries,
    String namespace,
    ValidationIssue issue,
  ) {
    for (var left = 0; left < entries.length; left++) {
      for (var right = left + 1; right < entries.length; right++) {
        final a = entries[left];
        final b = entries[right];
        final length = a.$2.length < b.$2.length ? a.$2.length : b.$2.length;
        var matches = true;
        for (var index = 0; index < length; index++) {
          if (a.$2[index] != b.$2[index]) {
            matches = false;
            break;
          }
        }
        if (matches) {
          issue(
            'IDL_DISCRIMINATOR_PREFIX',
            '$namespace discriminators for "${a.$1}" and "${b.$1}" '
                'are prefix-ambiguous.',
            '${b.$3}.discriminator',
          );
        }
      }
    }
  }
}
