import '../idl.dart';
import 'validation_issue.dart';

/// Validates type references, generic arguments, and recursive wire layouts.
final class TypeValidationRule {
  /// Creates the stateless type rule.
  const TypeValidationRule();

  /// Validates one type expression in its declaration context.
  void validate(
    IdlType value,
    Map<String, IdlTypeDefinition> definitions,
    Set<String> generics,
    String path,
    ValidationIssue issue,
  ) {
    switch (value) {
      case IdlPrimitiveType():
        return;
      case IdlOptionType(:final inner) || IdlVectorType(:final inner):
        validate(inner, definitions, generics, path, issue);
      case IdlCOptionType(:final inner):
        if (inner case IdlPrimitiveType(name: 'pubkey' || 'u64')) {
          validate(inner, definitions, generics, path, issue);
        } else {
          issue(
            'IDL_COPTION_TYPE_UNSUPPORTED',
            'COption is supported only for the SPL wire types pubkey and u64.',
            path,
          );
        }
      case IdlArrayType(:final inner, :final length):
        if (length < 0) {
          issue('IDL_ARRAY_LENGTH', 'Array length cannot be negative.', path);
        }
        validate(inner, definitions, generics, path, issue);
      case IdlGenericArrayType(:final inner, :final lengthName):
        if (!generics.contains(lengthName)) {
          final owner = definitions.values.any(
            (definition) => definition.constGenerics.contains(lengthName),
          );
          if (!owner) {
            issue(
              'IDL_CONST_GENERIC_UNDECLARED',
              'Undeclared const generic "$lengthName".',
              path,
            );
          }
        }
        validate(inner, definitions, generics, path, issue);
      case IdlDefinedType(:final name, :final generics, :final constGenerics):
        final definition = definitions[name];
        if (definition == null) {
          issue('IDL_TYPE_UNDEFINED', 'Undefined type "$name".', path);
        } else if (definition.generics.length != generics.length) {
          issue(
            'IDL_GENERIC_ARITY',
            'Type "$name" expects ${definition.generics.length} type '
                'arguments, got ${generics.length}.',
            path,
          );
        }
        if (definition != null &&
            definition.constGenerics.length != constGenerics.length) {
          issue(
            'IDL_CONST_GENERIC_ARITY',
            'Type "$name" expects ${definition.constGenerics.length} const '
                'arguments, got ${constGenerics.length}.',
            path,
          );
        }
        for (final value in constGenerics) {
          if (value < 0) {
            issue(
              'IDL_CONST_GENERIC_VALUE',
              'Const generic array length cannot be negative.',
              path,
            );
          }
        }
        for (final generic in generics) {
          validate(generic, definitions, const {}, path, issue);
        }
      case IdlGenericType(:final name):
        if (!generics.contains(name)) {
          issue('IDL_GENERIC_UNDECLARED', 'Undeclared generic "$name".', path);
        }
    }
  }

  /// Rejects direct or indirect recursive Borsh layouts.
  void validateRecursiveLayouts(
    Map<String, IdlTypeDefinition> definitions,
    ValidationIssue issue,
  ) {
    final edges = <String, Set<String>>{};
    void collect(IdlType value, Set<String> result) {
      switch (value) {
        case IdlPrimitiveType() || IdlGenericType():
          return;
        case IdlOptionType(:final inner) ||
            IdlCOptionType(:final inner) ||
            IdlVectorType(:final inner):
          collect(inner, result);
        case IdlArrayType(:final inner) || IdlGenericArrayType(:final inner):
          collect(inner, result);
        case IdlDefinedType(:final name, :final generics):
          result.add(name);
          for (final generic in generics) {
            collect(generic, result);
          }
      }
    }

    for (final entry in definitions.entries) {
      final result = <String>{};
      switch (entry.value.body) {
        case IdlStructBody(:final fields, :final tupleFields):
          for (final field in fields) {
            collect(field.type, result);
          }
          for (final field in tupleFields) {
            collect(field, result);
          }
        case IdlEnumBody(:final variants):
          for (final variant in variants) {
            for (final field in variant.fields) {
              collect(field.type, result);
            }
            for (final field in variant.tupleFields) {
              collect(field, result);
            }
          }
        case IdlAliasBody(:final value):
          collect(value, result);
      }
      edges[entry.key] = result;
    }
    final visiting = <String>{};
    final visited = <String>{};
    bool visit(String name) {
      if (visiting.contains(name)) return true;
      if (!visited.add(name)) return false;
      visiting.add(name);
      for (final target in edges[name] ?? const <String>{}) {
        if (definitions.containsKey(target) && visit(target)) return true;
      }
      visiting.remove(name);
      return false;
    }

    for (final definition in definitions.values) {
      visiting.clear();
      if (visit(definition.name)) {
        issue(
          'IDL_RECURSIVE_LAYOUT',
          'Recursive Borsh layout involving "${definition.name}" is unsupported.',
          definition.sourcePath,
        );
        break;
      }
    }
  }
}
