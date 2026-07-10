import 'package:code_builder/code_builder.dart';

import 'section_emitter.dart';

/// Emits the generated non-throwing Anchor program log parser.
final class ProgramErrorParserEmitter extends SectionEmitter {
  /// Creates a program error parser emitter for [context].
  const ProgramErrorParserEmitter(super.context);

  /// Emits the static parser class.
  @override
  List<Spec> emit() => [_parser()];

  Class _parser() => Class(
    (builder) => builder
      ..name = type('program_error_parser')
      ..abstract = true
      ..modifier = ClassModifier.final$
      ..docs.add('/// Parses numeric program failures into typed exceptions.')
      ..methods.addAll([
        Method(
          (builder) => builder
            ..name = 'nameForCode'
            ..static = true
            ..returns = refer('String?')
            ..docs.add('/// Returns the IDL error name for [code], if known.')
            ..requiredParameters.add(_parameter('code', 'int'))
            ..body = Code(_lookupBody('idlName')),
        ),
        Method(
          (builder) => builder
            ..name = 'messageForCode'
            ..static = true
            ..returns = refer('String?')
            ..docs.add(
              '/// Returns the IDL error message for [code], if known.',
            )
            ..requiredParameters.add(_parameter('code', 'int'))
            ..body = Code(_lookupBody('idlMessage')),
        ),
        Method(
          (builder) => builder
            ..name = 'codeForName'
            ..static = true
            ..returns = refer('int?')
            ..docs.add('/// Returns the numeric code for [name], if known.')
            ..requiredParameters.add(_parameter('name', 'String'))
            ..body = Code(_codeForNameBody()),
        ),
        Method(
          (builder) => builder
            ..name = 'isKnownCode'
            ..static = true
            ..returns = refer('bool')
            ..docs.add('/// Whether [code] is declared by this IDL.')
            ..requiredParameters.add(_parameter('code', 'int'))
            ..lambda = true
            ..body = const Code('nameForCode(code) != null'),
        ),
        Method(
          (builder) => builder
            ..name = 'fromCode'
            ..static = true
            ..returns = refer(type('program_exception'))
            ..docs.add('/// Creates a typed error for [code].')
            ..requiredParameters.add(_parameter('code', 'int'))
            ..optionalParameters.addAll(_parserParameters())
            ..body = Code(_fromCodeBody()),
        ),
        Method(
          (builder) => builder
            ..name = 'parseLogs'
            ..static = true
            ..returns = refer('${type('program_exception')}?')
            ..docs.add(
              '/// Parses a numeric code from Anchor or custom-program logs.',
            )
            ..requiredParameters.add(_parameter('logs', 'List<String>'))
            ..optionalParameters.addAll([
              _named('signature', 'String?'),
              _named('failure', '${type('transaction_failure')}?'),
            ])
            ..body = Code(_parseLogsBody()),
        ),
      ]),
  );

  String _lookupBody(String field) {
    final out = StringBuffer()..writeln('return switch (code) {');
    for (final error in context.program.errors) {
      final value = field == 'idlName' ? error.name : error.message;
      out.writeln("  ${error.code} => '${escape(value)}',");
    }
    out
      ..writeln('  _ => null,')
      ..write('};');
    return out.toString();
  }

  String _codeForNameBody() {
    final out = StringBuffer()..writeln('return switch (name) {');
    for (final error in context.program.errors) {
      out.writeln("  '${escape(error.name)}' => ${error.code},");
    }
    out
      ..writeln('  _ => null,')
      ..write('};');
    return out.toString();
  }

  String _fromCodeBody() {
    final out = StringBuffer()..writeln('return switch (code) {');
    for (final error in context.program.errors) {
      out.writeln(
        '  ${error.code} => ${type('${error.name}_exception')}('
        'origin: origin, comparedValues: comparedValues, rawLogs: logs, '
        'signature: signature, failure: failure),',
      );
    }
    out
      ..writeln(
        '  _ => ${type('unknown_program_exception')}(code: code, '
        'origin: origin, comparedValues: comparedValues, rawLogs: logs, '
        'signature: signature, failure: failure),',
      )
      ..write('};');
    return out.toString();
  }

  String _parseLogsBody() =>
      '''
int? code;
${type('error_origin')}? origin;
String? left;
String? right;
for (var index = 0; index < logs.length; index++) {
  final line = logs[index];
  final anchor = RegExp(r'Error Number: ([0-9]+)').firstMatch(line);
  if (anchor != null) code = int.parse(anchor.group(1)!);
  final custom = RegExp(r'custom program error: 0x([0-9a-fA-F]+)').firstMatch(line);
  if (custom != null) code = int.parse(custom.group(1)!, radix: 16);
  final account = RegExp(r'AnchorError caused by account: ([A-Za-z_][A-Za-z0-9_]*)').firstMatch(line);
  if (account != null) origin = ${type('account_error_origin')}(account.group(1)!);
  final program = RegExp(r'AnchorError caused by program: ([1-9A-HJ-NP-Za-km-z]+)').firstMatch(line);
  if (program != null) {
    try {
      origin = ${type('program_error_origin')}(${type('address')}.fromBase58(program.group(1)!));
    } on FormatException {
      origin = null;
    } on ArgumentError {
      origin = null;
    }
  }
  if (line.endsWith('Left:') && index + 1 < logs.length) {
    left = logs[index + 1].replaceFirst('Program log: ', '');
  }
  if (line.endsWith('Right:') && index + 1 < logs.length) {
    right = logs[index + 1].replaceFirst('Program log: ', '');
  }
}
final compared = left == null || right == null
    ? null
    : ${type('text_compared_values')}(left: left, right: right);
return code == null
    ? null
    : fromCode(code, origin: origin, comparedValues: compared, logs: logs, signature: signature, failure: failure);''';

  List<Parameter> _parserParameters() => [
    _named('origin', '${type('error_origin')}?'),
    _named('comparedValues', '${type('compared_values')}?'),
    _named('logs', 'List<String>', defaultValue: 'const []'),
    _named('signature', 'String?'),
    _named('failure', '${type('transaction_failure')}?'),
  ];

  Parameter _parameter(String name, String parameterType) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(parameterType),
  );

  Parameter _named(String name, String parameterType, {String? defaultValue}) =>
      Parameter(
        (builder) => builder
          ..name = name
          ..type = refer(parameterType)
          ..named = true
          ..defaultTo = defaultValue == null ? null : Code(defaultValue),
      );
}
