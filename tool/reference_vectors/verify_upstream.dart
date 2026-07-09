import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Verifies checksums of upstream files recorded by reference-vector metadata.
Future<void> main() async {
  final manifest =
      jsonDecode(
            await File('test/reference_vectors/provenance.json').readAsString(),
          )
          as Map<String, Object?>;
  final vectors = (manifest['vectors']! as List<Object?>)
      .cast<Map<String, Object?>>();
  final expectedBySource = <Uri, String>{};
  for (final vector in vectors) {
    final source = vector['source'];
    final checksum = vector['sourceSha256'];
    if (source is! String || checksum is! String) continue;
    final uri = _rawUri(Uri.parse(source));
    final previous = expectedBySource[uri];
    if (previous != null && previous != checksum) {
      throw StateError('Conflicting checksums for $uri.');
    }
    expectedBySource[uri] = checksum;
  }

  final client = HttpClient();
  try {
    for (final entry in expectedBySource.entries) {
      final request = await client.getUrl(entry.key);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'HTTP ${response.statusCode} while reading ${entry.key}.',
          uri: entry.key,
        );
      }
      final bytes = await response.fold<List<int>>(
        <int>[],
        (result, chunk) => result..addAll(chunk),
      );
      final actual = sha256.convert(bytes).toString();
      if (actual != entry.value) {
        throw StateError(
          'Checksum mismatch for ${entry.key}: '
          'expected ${entry.value}, got $actual.',
        );
      }
      stdout.writeln('VERIFIED ${entry.key}');
    }
  } finally {
    client.close(force: true);
  }
}

Uri _rawUri(Uri source) {
  if (source.host != 'github.com') return source;
  final segments = source.pathSegments;
  final blob = segments.indexOf('blob');
  if (blob < 2 || blob + 1 >= segments.length) return source;
  return Uri.https(
    'raw.githubusercontent.com',
    [segments[0], segments[1], ...segments.skip(blob + 1)].join('/'),
  );
}
