/// Canonical matching helpers for IDL dotted paths and path segments.
final class IdlPathMatcher {
  const IdlPathMatcher._();

  /// Canonicalizes one wire path segment for cross-dialect matching.
  static String canonicalSegment(String value) => value
      .replaceAllMapped(
        RegExp('([a-z0-9])([A-Z])'),
        (match) => '${match[1]}_${match[2]}',
      )
      .replaceAll(RegExp('[^A-Za-z0-9]+'), '_')
      .toLowerCase();

  /// Canonicalizes a dotted wire path.
  static String canonicalPath(String path) =>
      path.split('.').map(canonicalSegment).join('.');

  /// Returns whether two wire path segments name the same logical segment.
  static bool segmentsMatch(String left, String right) =>
      canonicalSegment(left) == canonicalSegment(right);

  /// Returns whether two dotted wire paths name the same logical path.
  static bool pathsMatch(String left, String right) =>
      canonicalPath(left) == canonicalPath(right);

  /// Returns whether [raw] has [candidate] as a canonical dotted path prefix.
  static bool pathHasPrefix(String raw, String candidate) {
    final rawSegments = raw.split('.');
    final candidateSegments = candidate.split('.');
    if (rawSegments.length <= candidateSegments.length) return false;
    for (var index = 0; index < candidateSegments.length; index++) {
      if (!segmentsMatch(rawSegments[index], candidateSegments[index])) {
        return false;
      }
    }
    return true;
  }

  /// Returns the longest candidate matching [raw] exactly or as a path prefix.
  static String? longestPathPrefix(String raw, Iterable<String> candidates) {
    String? result;
    var resultLength = -1;
    for (final candidate in candidates) {
      final candidateLength = canonicalPath(candidate).length;
      if ((pathsMatch(raw, candidate) || pathHasPrefix(raw, candidate)) &&
          candidateLength > resultLength) {
        result = candidate;
        resultLength = candidateLength;
      }
    }
    return result;
  }
}
