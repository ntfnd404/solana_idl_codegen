import 'package:code_builder/code_builder.dart';

/// Shared `code_builder` helpers for generated Borsh reader methods.
final class BorshReaderMethodHelpers {
  /// Creates reusable method-building helpers.
  const BorshReaderMethodHelpers();

  /// Builds a reader method with one named optional `path` parameter.
  Method method(
    String name,
    String returns,
    String docs,
    List<Parameter> required,
    Parameter optional,
    Code body,
  ) => Method(
    (builder) => builder
      ..name = name
      ..returns = refer(returns)
      ..docs.add('/// $docs')
      ..requiredParameters.addAll(required)
      ..optionalParameters.add(optional)
      ..body = body,
  );

  /// Builds the optional logical path parameter used by reader methods.
  Parameter pathParameter() => Parameter(
    (builder) => builder
      ..name = 'path'
      ..type = refer('String?')
      ..named = true,
  );

  /// Builds a positional parameter.
  Parameter parameter(String name, String type) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(type),
  );
}
