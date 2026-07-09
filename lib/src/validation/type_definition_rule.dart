import '../idl.dart';
import 'type_rule.dart';
import 'uniqueness_rule.dart';
import 'validation_issue.dart';

/// Validates type declarations, generic declarations, and nested field types.
final class TypeDefinitionValidationRule {
  /// Creates a type definition validation rule.
  const TypeDefinitionValidationRule({
    this.typeRule = const TypeValidationRule(),
    this.uniquenessRule = const UniquenessValidationRule(),
  });

  /// Rule responsible for type references and recursive layouts.
  final TypeValidationRule typeRule;

  /// Rule responsible for duplicate variants.
  final UniquenessValidationRule uniquenessRule;

  /// Validates all type definitions in [program].
  void validate(
    IdlProgram program,
    Map<String, IdlTypeDefinition> definitions,
    ValidationIssue issue,
  ) {
    for (final definition in program.types) {
      final genericNames = {
        ...definition.generics,
        ...definition.constGenerics,
      };
      if (genericNames.length !=
          definition.generics.length + definition.constGenerics.length) {
        issue(
          'IDL_GENERIC_DUPLICATE',
          'Generic declarations must be unique.',
          '${definition.sourcePath}.generics',
        );
      }
      switch (definition.body) {
        case IdlStructBody(:final fields, :final tupleFields):
          _validateStruct(
            definition,
            fields,
            tupleFields,
            definitions,
            genericNames,
            issue,
          );
        case IdlEnumBody(:final variants):
          _validateEnum(definition, variants, definitions, genericNames, issue);
        case IdlAliasBody(:final value):
          typeRule.validate(
            value,
            definitions,
            genericNames,
            definition.sourcePath,
            issue,
          );
      }
    }
  }

  void _validateStruct(
    IdlTypeDefinition definition,
    List<IdlField> fields,
    List<IdlType> tupleFields,
    Map<String, IdlTypeDefinition> definitions,
    Set<String> genericNames,
    ValidationIssue issue,
  ) {
    for (final field in fields) {
      typeRule.validate(
        field.type,
        definitions,
        genericNames,
        field.sourcePath,
        issue,
      );
    }
    for (var index = 0; index < tupleFields.length; index++) {
      typeRule.validate(
        tupleFields[index],
        definitions,
        genericNames,
        '${definition.sourcePath}.type.fields[$index]',
        issue,
      );
    }
  }

  void _validateEnum(
    IdlTypeDefinition definition,
    List<IdlEnumVariant> variants,
    Map<String, IdlTypeDefinition> definitions,
    Set<String> genericNames,
    ValidationIssue issue,
  ) {
    if (variants.length > 256) {
      issue(
        'IDL_ENUM_TOO_MANY_VARIANTS',
        'Borsh enum tags support at most 256 variants.',
        definition.sourcePath,
      );
    }
    uniquenessRule.names(
      variants.map((item) => (item.name, item.sourcePath)),
      'enum variant',
      issue,
    );
    for (final variant in variants) {
      for (final field in variant.fields) {
        typeRule.validate(
          field.type,
          definitions,
          genericNames,
          field.sourcePath,
          issue,
        );
      }
      for (var index = 0; index < variant.tupleFields.length; index++) {
        typeRule.validate(
          variant.tupleFields[index],
          definitions,
          genericNames,
          '${variant.sourcePath}.fields[$index]',
          issue,
        );
      }
    }
  }
}
