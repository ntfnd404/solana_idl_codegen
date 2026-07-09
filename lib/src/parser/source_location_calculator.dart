import '../diagnostics.dart';

/// Converts source offsets into one-based line/column locations.
final class SourceLocationCalculator {
  /// Creates a source location calculator.
  const SourceLocationCalculator();

  /// Returns the line and column for [offset] in [source].
  SourceLocation locationFor(String source, int offset) {
    var line = 1;
    var column = 1;
    for (var index = 0; index < offset && index < source.length; index++) {
      if (source.codeUnitAt(index) == 10) {
        line++;
        column = 1;
      } else {
        column++;
      }
    }
    return SourceLocation(line: line, column: column);
  }
}
