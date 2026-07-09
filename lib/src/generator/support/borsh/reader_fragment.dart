import 'package:code_builder/code_builder.dart';

import '../../section_emitter.dart';
import 'reader_methods_fragment.dart';

/// Emits the mutable, bounds-checked Borsh reader.
final class BorshReaderFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const BorshReaderFragment(super.context);

  @override
  List<Spec> emit() {
    final limits = type('decode_limits');
    final error = type('borsh_exception');
    final name = type('borsh_reader');
    final methods = BorshReaderMethodsFragment(context);
    return <Spec>[
      Class(
        (builder) => builder
          ..name = name
          ..modifier = ClassModifier.final$
          ..docs.add(
            '/// Mutable, bounds-checked Borsh reader scoped to one decode operation.',
          )
          ..constructors.add(_constructor(limits, error))
          ..fields.addAll([
            _field('_bytes', 'Uint8List', final$: true),
            _field(
              'limits',
              limits,
              final$: true,
              docs: 'Limits used by this decode operation.',
            ),
            _field('_offset', null, assignment: '0'),
            _field('_totalElements', null, assignment: '0'),
            _field('_depth', null, assignment: '0'),
            _field('_path', null, assignment: r"r'$'"),
          ])
          ..methods.addAll([
            _getter('offset', 'int', 'Current byte offset.', '_offset'),
            _getter(
              'remaining',
              'int',
              'Remaining unread byte count.',
              '_bytes.length - _offset',
            ),
            ...methods.pathMethods(error),
            ...methods.primitiveMethods(error),
            ...methods.collectionMethods(error),
          ]),
      ),
    ];
  }

  Constructor _constructor(String limits, String error) => Constructor(
    (builder) => builder
      ..docs.add('/// Creates a reader over a defensive copy of [input].')
      ..requiredParameters.add(_parameter('input', 'List<int>'))
      ..optionalParameters.add(
        Parameter(
          (builder) => builder
            ..name = 'limits'
            ..named = true
            ..toThis = true
            ..defaultTo = Code('$limits.defaults'),
        ),
      )
      ..initializers.add(const Code('_bytes = Uint8List.fromList(input)'))
      ..body = Code('''
if (limits.maxInputBytes < 0 ||
    limits.maxStringBytes < 0 ||
    limits.maxCollectionLength < 0 ||
    limits.maxTotalElements < 0 ||
    limits.maxNestingDepth < 0) {
  throw ArgumentError.value(
    limits,
    'limits',
    'Decode limits must be non-negative.',
  );
}
if (_bytes.length > limits.maxInputBytes) {
  throw $error(
    code: 'BORSH_INPUT_LIMIT',
    message: 'Input exceeds maxInputBytes.',
    offset: 0,
    path: r'\$',
    expected: '<= \${limits.maxInputBytes}',
    actual: '\${_bytes.length}',
  );
}'''),
  );

  Method _getter(String name, String type, String docs, String body) => Method(
    (builder) => builder
      ..name = name
      ..type = MethodType.getter
      ..returns = refer(type)
      ..docs.add('/// $docs')
      ..lambda = true
      ..body = Code(body),
  );

  Parameter _parameter(String name, String type) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(type),
  );

  Field _field(
    String name,
    String? type, {
    bool final$ = false,
    String? assignment,
    String? docs,
  }) => Field((builder) {
    builder.name = name;
    if (type != null) builder.type = refer(type);
    if (final$) builder.modifier = FieldModifier.final$;
    if (assignment != null) builder.assignment = Code(assignment);
    if (docs != null) builder.docs.add('/// $docs');
  });
}
