/// Base node for every supported IDL wire type.
sealed class IdlType {
  /// Creates an IDL wire type node.
  const IdlType();
}

/// Primitive Borsh or Solana public-key type.
final class IdlPrimitiveType extends IdlType {
  /// Creates a primitive type with normalized [name].
  const IdlPrimitiveType(this.name);

  /// Normalized primitive wire name.
  final String name;
}

/// Optional wire value.
final class IdlOptionType extends IdlType {
  /// Creates an optional [inner] type.
  const IdlOptionType(this.inner);

  /// Type encoded when the option is present.
  final IdlType inner;
}

/// SPL-compatible optional value encoded with a little-endian `u32` tag.
final class IdlCOptionType extends IdlType {
  /// Creates a COption of [inner].
  const IdlCOptionType(this.inner);

  /// Type encoded when the COption is present.
  final IdlType inner;
}

/// Dynamically-sized wire vector.
final class IdlVectorType extends IdlType {
  /// Creates a dynamically-sized vector of [inner] values.
  const IdlVectorType(this.inner);

  /// Vector element type.
  final IdlType inner;
}

/// Fixed-length wire array.
final class IdlArrayType extends IdlType {
  /// Creates a fixed [length] array of [inner] values.
  const IdlArrayType(this.inner, this.length);

  /// Array element type.
  final IdlType inner;

  /// Required element count.
  final int length;
}

/// Fixed array whose length is supplied by a const generic.
final class IdlGenericArrayType extends IdlType {
  /// Creates an array using const generic [lengthName].
  const IdlGenericArrayType(this.inner, this.lengthName);

  /// Array element type.
  final IdlType inner;

  /// Const generic parameter name.
  final String lengthName;
}

/// Reference to a named type definition.
final class IdlDefinedType extends IdlType {
  /// Creates a reference to a named type with generic arguments.
  IdlDefinedType(
    this.name,
    List<IdlType> generics, {
    List<int> constGenerics = const [],
  }) : generics = List.unmodifiable(generics),
       constGenerics = List.unmodifiable(constGenerics);

  /// Referenced type wire name.
  final String name;

  /// Applied generic type arguments.
  final List<IdlType> generics;

  /// Applied const generic arguments in declaration order.
  final List<int> constGenerics;
}

/// Reference to a generic type parameter.
final class IdlGenericType extends IdlType {
  /// Creates a reference to generic parameter [name].
  const IdlGenericType(this.name);

  /// Generic parameter name.
  final String name;
}

/// Named field in a struct, enum variant or instruction argument list.
final class IdlField {
  /// Creates a named field with optional IDL [docs].
  IdlField(
    this.name,
    this.type, {
    List<String> docs = const [],
    this.sourcePath = r'$',
  }) : docs = List.unmodifiable(docs);

  /// Field wire name.
  final String name;

  /// Field wire type.
  final IdlType type;

  /// Documentation lines supplied by the IDL.
  final List<String> docs;

  /// JSON path at which this field was declared.
  final String sourcePath;
}

/// Base representation of a named type's body.
sealed class IdlTypeBody {
  /// Creates a named type body.
  const IdlTypeBody();
}

/// Struct body with named fields or tuple fields.
final class IdlStructBody extends IdlTypeBody {
  /// Creates a named-field or tuple-field struct body.
  IdlStructBody({
    required List<IdlField> fields,
    required List<IdlType> tupleFields,
  }) : fields = List.unmodifiable(fields),
       tupleFields = List.unmodifiable(tupleFields);

  /// Named struct fields.
  final List<IdlField> fields;

  /// Positional tuple fields.
  final List<IdlType> tupleFields;
}

/// Rust-style enum body.
final class IdlEnumBody extends IdlTypeBody {
  /// Creates an enum body from ordered [variants].
  IdlEnumBody(List<IdlEnumVariant> variants)
    : variants = List.unmodifiable(variants);

  /// Variants in their wire-tag order.
  final List<IdlEnumVariant> variants;
}

/// Type alias body.
final class IdlAliasBody extends IdlTypeBody {
  /// Creates an alias to [value].
  const IdlAliasBody(this.value);

  /// Aliased wire type.
  final IdlType value;
}

/// Unit, tuple or named-field enum variant.
final class IdlEnumVariant {
  /// Creates a unit, tuple or named-field enum variant.
  IdlEnumVariant({
    required this.name,
    required List<String> docs,
    required List<IdlField> fields,
    required List<IdlType> tupleFields,
    this.sourcePath = r'$',
  }) : docs = List.unmodifiable(docs),
       fields = List.unmodifiable(fields),
       tupleFields = List.unmodifiable(tupleFields);

  /// Variant wire name.
  final String name;

  /// Documentation lines supplied by the IDL.
  final List<String> docs;

  /// Named payload fields.
  final List<IdlField> fields;

  /// Positional payload fields.
  final List<IdlType> tupleFields;

  /// JSON path at which this variant was declared.
  final String sourcePath;
}

/// Named IDL type definition with optional generic parameters.
final class IdlTypeDefinition {
  /// Creates a named type definition.
  IdlTypeDefinition({
    required this.name,
    required List<String> docs,
    required this.body,
    required List<String> generics,
    List<String> constGenerics = const [],
    this.serialization = 'borsh',
    this.representation,
    this.sourcePath = r'$',
  }) : docs = List.unmodifiable(docs),
       generics = List.unmodifiable(generics),
       constGenerics = List.unmodifiable(constGenerics);

  /// Type wire name.
  final String name;

  /// Documentation lines supplied by the IDL.
  final List<String> docs;

  /// Struct, enum or alias body.
  final IdlTypeBody body;

  /// Generic parameter names in declaration order.
  final List<String> generics;

  /// Const generic parameter names in declaration order.
  final List<String> constGenerics;

  /// Normalized serialization strategy.
  final String serialization;

  /// Optional Rust representation metadata.
  final String? representation;

  /// JSON path at which this type was declared.
  final String sourcePath;
}
