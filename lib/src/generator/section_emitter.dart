import 'package:code_builder/code_builder.dart';

import 'generator_context.dart';

/// Base contract shared by focused generated-source emitters.
abstract base class SectionEmitter {
  /// Creates an emitter for [context].
  const SectionEmitter(this.context);

  /// Immutable generation context.
  final GeneratorContext context;

  /// Emits this section's immutable declaration specifications.
  List<Spec> emit();

  /// Resolves a generated type name.
  String type(String name) => context.type(name);

  /// Resolves a generated member name.
  String member(String name) => context.member(name);

  /// Escapes a value embedded in a single-quoted Dart literal.
  String escape(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$')
      .replaceAll('\r', r'\r')
      .replaceAll('\n', r'\n');

  /// Emits a typed integer-list literal.
  String bytes(List<int> value) => '<int>[${value.join(', ')}]';

  /// Writes generated API documentation.
  void docs(
    StringBuffer out,
    String summary, {
    List<String> idlDocs = const [],
    String indent = '',
  }) {
    for (final line in <String>[
      summary,
      if (idlDocs.isNotEmpty) '',
      ...idlDocs,
    ]) {
      for (final part in line.replaceAll('\r\n', '\n').split('\n')) {
        out.writeln(part.isEmpty ? '$indent///' : '$indent/// $part');
      }
    }
  }
}
