import '../diagnostics.dart';
import '../generation.dart';
import 'idl_format_exception.dart';

/// Scans JSON before decoding to reject duplicate keys and excessive depth.
final class DuplicateAwareJsonScanner {
  /// Creates a scanner for [source].
  DuplicateAwareJsonScanner(this.source, this.limits);

  /// Raw JSON source.
  final String source;

  /// Parser resource limits.
  final IdlParseLimits limits;

  var _offset = 0;
  var _line = 1;
  var _column = 1;
  final _locations = <String, SourceLocation>{};

  /// Scans the document structure and returns value locations by JSON path.
  JsonSourceMap scan() {
    _space();
    _value(r'$', 0);
    return JsonSourceMap(_locations);
  }

  void _value(String path, int depth) {
    if (depth > limits.maxJsonDepth) {
      throw IdlFormatException(
        'JSON nesting exceeds maxJsonDepth.',
        path,
        code: 'IDL_LIMIT_JSON_DEPTH',
        location: _location,
      );
    }
    _space();
    if (_offset >= source.length) return;
    _locations.putIfAbsent(path, () => _location);
    switch (source.codeUnitAt(_offset)) {
      case 123:
        _object(path, depth + 1);
      case 91:
        _array(path, depth + 1);
      case 34:
        _string();
      default:
        _scalar();
    }
  }

  void _object(String path, int depth) {
    _advance();
    _space();
    final keys = <String, SourceLocation>{};
    if (_peek(125)) {
      _advance();
      return;
    }
    while (_offset < source.length) {
      _space();
      final location = _location;
      final key = _string();
      final first = keys[key];
      if (first != null) {
        throw IdlFormatException(
          'Duplicate JSON key "$key".',
          _childPath(path, key),
          code: 'IDL_JSON_DUPLICATE_KEY',
          location: location,
          related: [
            IdlFormatException(
              'The first "$key" key is here.',
              _childPath(path, key),
              code: 'IDL_JSON_DUPLICATE_KEY_FIRST',
              location: first,
            ),
          ],
        );
      }
      keys[key] = location;
      _space();
      if (_peek(58)) _advance();
      _value(_childPath(path, key), depth);
      _space();
      if (_peek(125)) {
        _advance();
        return;
      }
      if (_peek(44)) _advance();
    }
  }

  void _array(String path, int depth) {
    _advance();
    _space();
    if (_peek(93)) {
      _advance();
      return;
    }
    var index = 0;
    while (_offset < source.length) {
      _value('$path[$index]', depth);
      index++;
      _space();
      if (_peek(93)) {
        _advance();
        return;
      }
      if (_peek(44)) _advance();
    }
  }

  String _string() {
    if (!_peek(34)) return '';
    _advance();
    final value = StringBuffer();
    while (_offset < source.length) {
      final code = source.codeUnitAt(_offset);
      if (code == 34) {
        _advance();
        return value.toString();
      }
      if (code == 92) {
        _advance();
        if (_offset >= source.length) return value.toString();
        final escaped = source.codeUnitAt(_offset);
        if (escaped == 117 && _offset + 4 < source.length) {
          final decoded = int.tryParse(
            source.substring(_offset + 1, _offset + 5),
            radix: 16,
          );
          if (decoded != null) value.writeCharCode(decoded);
          for (var count = 0; count < 5 && _offset < source.length; count++) {
            _advance();
          }
          continue;
        }
        value.writeCharCode(switch (escaped) {
          34 => 34,
          47 => 47,
          92 => 92,
          98 => 8,
          102 => 12,
          110 => 10,
          114 => 13,
          116 => 9,
          _ => escaped,
        });
        _advance();
        continue;
      }
      value.writeCharCode(code);
      _advance();
    }
    return value.toString();
  }

  void _scalar() {
    while (_offset < source.length) {
      final code = source.codeUnitAt(_offset);
      if (code == 44 || code == 93 || code == 125 || _isSpace(code)) return;
      _advance();
    }
  }

  void _space() {
    while (_offset < source.length && _isSpace(source.codeUnitAt(_offset))) {
      _advance();
    }
  }

  void _advance() {
    if (_offset >= source.length) return;
    if (source.codeUnitAt(_offset) == 10) {
      _line++;
      _column = 1;
    } else {
      _column++;
    }
    _offset++;
  }

  bool _peek(int codeUnit) =>
      _offset < source.length && source.codeUnitAt(_offset) == codeUnit;

  bool _isSpace(int code) =>
      code == 32 || code == 9 || code == 10 || code == 13;

  SourceLocation get _location => SourceLocation(line: _line, column: _column);

  String _childPath(String parent, String key) =>
      RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(key)
      ? '$parent.$key'
      : "$parent['${key.replaceAll("'", r"\'")}']";
}

/// Immutable source locations collected for JSON values.
final class JsonSourceMap {
  /// Creates a source map from scanner [locations].
  JsonSourceMap(Map<String, SourceLocation> locations)
    : _locations = Map.unmodifiable(locations);

  final Map<String, SourceLocation> _locations;

  /// Returns the nearest known location for [path].
  SourceLocation locationFor(String path) {
    var candidate = path;
    while (true) {
      final location = _locations[candidate];
      if (location != null) return location;
      final array = candidate.lastIndexOf('[');
      final field = candidate.lastIndexOf('.');
      final split = array > field ? array : field;
      if (split <= 0) {
        return _locations[r'$'] ?? const SourceLocation(line: 1, column: 1);
      }
      candidate = candidate.substring(0, split);
    }
  }
}
