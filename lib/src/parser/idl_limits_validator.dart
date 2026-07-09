import 'dart:convert';

import '../generation.dart';
import '../idl.dart';
import 'idl_format_exception.dart';

/// Enforces resource limits after dialect normalization.
final class IdlLimitsValidator {
  /// Creates a limits validator.
  const IdlLimitsValidator(this.limits);

  /// Configured parser limits.
  final IdlParseLimits limits;

  /// Validates resource limits for normalized [program].
  void validate(IdlProgram program) {
    final declarations =
        program.instructions.length +
        program.accounts.length +
        program.events.length +
        program.errors.length +
        program.constants.length +
        program.types.length;
    if (declarations > limits.maxDeclarations) {
      throw const IdlFormatException(
        'IDL declarations exceed maxDeclarations.',
        r'$',
        code: 'IDL_LIMIT_DECLARATIONS',
      );
    }
    var totalFields = 0;
    var docsBytes = 0;
    void checkIdentifier(String value, String path, {bool namespaced = false}) {
      if (value.length > limits.maxIdentifierLength) {
        throw IdlFormatException(
          'Identifier exceeds maxIdentifierLength.',
          path,
          code: 'IDL_LIMIT_IDENTIFIER',
        );
      }
      final pattern = namespaced
          ? RegExp(r'^[A-Za-z_][A-Za-z0-9_]*(::[A-Za-z_][A-Za-z0-9_]*)*$')
          : RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
      if (!pattern.hasMatch(value)) {
        throw IdlFormatException(
          'Invalid wire identifier "$value".',
          path,
          code: 'IDL_IDENTIFIER_INVALID',
        );
      }
    }

    void addDocs(List<String> docs) {
      for (final line in docs) {
        docsBytes += utf8.encode(line).length;
      }
    }

    void accounts(List<IdlInstructionAccount> nodes) {
      if (nodes.length > limits.maxFieldsPerDeclaration) {
        throw const IdlFormatException(
          'Instruction accounts exceed maxFieldsPerDeclaration.',
          r'$.instructions',
          code: 'IDL_LIMIT_FIELDS',
        );
      }
      totalFields += nodes.length;
      for (final node in nodes) {
        checkIdentifier(node.name, '${node.sourcePath}.name');
        addDocs(node.docs);
        if (node is IdlAccountGroup) accounts(node.accounts);
      }
    }

    checkIdentifier(program.name, r'$.metadata.name');
    for (final instruction in program.instructions) {
      checkIdentifier(instruction.name, '${instruction.sourcePath}.name');
      addDocs(instruction.docs);
      if (instruction.arguments.length > limits.maxFieldsPerDeclaration) {
        throw IdlFormatException(
          'Instruction arguments exceed maxFieldsPerDeclaration.',
          '${instruction.sourcePath}.args',
          code: 'IDL_LIMIT_FIELDS',
        );
      }
      totalFields += instruction.arguments.length;
      for (final field in instruction.arguments) {
        checkIdentifier(field.name, '${field.sourcePath}.name');
        addDocs(field.docs);
      }
      accounts(instruction.accounts);
    }
    for (final definition in program.types) {
      checkIdentifier(
        definition.name,
        '${definition.sourcePath}.name',
        namespaced: true,
      );
      addDocs(definition.docs);
      switch (definition.body) {
        case IdlStructBody(:final fields, :final tupleFields):
          final count = fields.length + tupleFields.length;
          if (count > limits.maxFieldsPerDeclaration) {
            throw IdlFormatException(
              'Type fields exceed maxFieldsPerDeclaration.',
              definition.sourcePath,
              code: 'IDL_LIMIT_FIELDS',
            );
          }
          totalFields += count;
          for (final field in fields) {
            checkIdentifier(field.name, '${field.sourcePath}.name');
            addDocs(field.docs);
          }
        case IdlEnumBody(:final variants):
          if (variants.length > limits.maxFieldsPerDeclaration) {
            throw IdlFormatException(
              'Enum variants exceed maxFieldsPerDeclaration.',
              definition.sourcePath,
              code: 'IDL_LIMIT_FIELDS',
            );
          }
          totalFields += variants.length;
          for (final variant in variants) {
            checkIdentifier(variant.name, '${variant.sourcePath}.name');
            addDocs(variant.docs);
            totalFields += variant.fields.length + variant.tupleFields.length;
          }
        case IdlAliasBody():
          break;
      }
    }
    for (final account in program.accounts) {
      checkIdentifier(
        account.name,
        '${account.sourcePath}.name',
        namespaced: true,
      );
    }
    for (final event in program.events) {
      checkIdentifier(event.name, '${event.sourcePath}.name', namespaced: true);
    }
    for (final error in program.errors) {
      checkIdentifier(error.name, '${error.sourcePath}.name');
    }
    for (final constant in program.constants) {
      checkIdentifier(constant.name, '${constant.sourcePath}.name');
    }
    if (totalFields > limits.maxTotalFields) {
      throw const IdlFormatException(
        'IDL fields exceed maxTotalFields.',
        r'$',
        code: 'IDL_LIMIT_TOTAL_FIELDS',
      );
    }
    if (docsBytes > limits.maxDocsBytes) {
      throw const IdlFormatException(
        'IDL documentation exceeds maxDocsBytes.',
        r'$',
        code: 'IDL_LIMIT_DOCS',
      );
    }
  }
}
