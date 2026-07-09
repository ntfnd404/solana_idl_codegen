import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../idl.dart';

/// Computes the stable digest of wire-relevant normalized IDL semantics.
final class SemanticDigest {
  const SemanticDigest._();

  /// Returns the SHA-256 digest of canonical wire semantics in [program].
  static String compute(IdlProgram program) =>
      sha256.convert(utf8.encode(_representation(program))).toString();

  static String _representation(IdlProgram program) {
    String wireType(IdlType type) => switch (type) {
      IdlPrimitiveType(:final name) => name,
      IdlOptionType(:final inner) => 'option(${wireType(inner)})',
      IdlCOptionType(:final inner) => 'coption(${wireType(inner)})',
      IdlVectorType(:final inner) => 'vec(${wireType(inner)})',
      IdlArrayType(:final inner, :final length) =>
        'array(${wireType(inner)},$length)',
      IdlGenericArrayType(:final inner, :final lengthName) =>
        'array(${wireType(inner)},generic:$lengthName)',
      IdlDefinedType(:final name, :final generics, :final constGenerics) =>
        'defined($name,${generics.map(wireType).join(',')};'
            '${constGenerics.join(',')})',
      IdlGenericType(:final name) => 'generic($name)',
    };

    String constValue(IdlConstValue value) => switch (value) {
      IdlIntegerConstValue(:final value) => 'int:$value',
      IdlBooleanConstValue(:final value) => 'bool:$value',
      IdlStringConstValue(:final value) => 'string:${jsonEncode(value)}',
      IdlBytesConstValue(:final value) => 'bytes:${value.join(',')}',
    };

    String seed(IdlSeed value) => switch (value) {
      IdlConstSeed(:final value, :final valueType) =>
        'const(${valueType == null ? '-' : wireType(valueType)},'
            '${constValue(value)})',
      IdlPathSeed(:final kind, :final path, :final account, :final valueType) =>
        '$kind($path,${account ?? '-'},'
            '${valueType == null ? '-' : wireType(valueType)})',
    };

    void accountTree(StringBuffer buffer, List<IdlInstructionAccount> nodes) {
      for (final node in nodes) {
        switch (node) {
          case IdlAccountGroup(:final accounts):
            buffer
              ..write(':group=')
              ..write(node.name)
              ..write('{');
            accountTree(buffer, accounts);
            buffer.write('}');
          case IdlAccountItem():
            buffer
              ..write(':account=')
              ..write(node.name)
              ..write(',')
              ..write(node.writable)
              ..write(',')
              ..write(node.signer)
              ..write(',')
              ..write(node.optional)
              ..write(',')
              ..write(node.address ?? '-')
              ..write(',relations=')
              ..write(node.relations.join(','))
              ..write(',seeds=')
              ..write(node.seeds.map(seed).join(','))
              ..write(',program=')
              ..write(node.pdaProgram == null ? '-' : seed(node.pdaProgram!));
        }
      }
    }

    final buffer = StringBuffer()
      ..write(program.name)
      ..write('|')
      ..write(program.address)
      ..write('|')
      ..write(program.spec);
    for (final instruction in program.instructions) {
      buffer
        ..write('|ix:')
        ..write(instruction.name)
        ..write(':')
        ..write(instruction.discriminator.join(','));
      for (final argument in instruction.arguments) {
        buffer
          ..write(':')
          ..write(argument.name)
          ..write('=')
          ..write(wireType(argument.type));
      }
      accountTree(buffer, instruction.accounts);
      buffer
        ..write(':returns=')
        ..write(
          instruction.returns == null ? '-' : wireType(instruction.returns!),
        );
    }
    for (final definition in program.types) {
      buffer
        ..write('|type:')
        ..write(definition.name)
        ..write(':')
        ..write(definition.generics.join(','))
        ..write(';const=')
        ..write(definition.constGenerics.join(','))
        ..write(';serialization=')
        ..write(definition.serialization)
        ..write(';repr=')
        ..write(definition.representation ?? '-');
      switch (definition.body) {
        case IdlStructBody(:final fields, :final tupleFields):
          for (final field in fields) {
            buffer
              ..write(':')
              ..write(field.name)
              ..write('=')
              ..write(wireType(field.type));
          }
          for (final field in tupleFields) {
            buffer
              ..write(':')
              ..write(wireType(field));
          }
        case IdlEnumBody(:final variants):
          for (final variant in variants) {
            buffer
              ..write(':variant=')
              ..write(variant.name);
            for (final field in variant.fields) {
              buffer
                ..write(':')
                ..write(field.name)
                ..write('=')
                ..write(wireType(field.type));
            }
            for (final field in variant.tupleFields) {
              buffer
                ..write(':')
                ..write(wireType(field));
            }
          }
        case IdlAliasBody(:final value):
          buffer
            ..write(':alias=')
            ..write(wireType(value));
      }
    }
    for (final account in program.accounts) {
      buffer
        ..write('|account:')
        ..write(account.name)
        ..write('=')
        ..write(account.discriminator.join(','));
    }
    for (final event in program.events) {
      buffer
        ..write('|event:')
        ..write(event.name)
        ..write('=')
        ..write(event.discriminator.join(','));
    }
    for (final error in program.errors) {
      buffer
        ..write('|error:')
        ..write(error.code)
        ..write(',')
        ..write(error.name)
        ..write(',')
        ..write(jsonEncode(error.message));
    }
    for (final constant in program.constants) {
      buffer
        ..write('|const:')
        ..write(constant.name)
        ..write('=')
        ..write(wireType(constant.type))
        ..write(',')
        ..write(constValue(constant.value));
    }
    return buffer.toString();
  }
}
