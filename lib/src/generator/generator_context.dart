import '../idl.dart';
import '../naming.dart';
import 'generator_version.dart';
import 'name_allocator.dart';
import 'semantic_digest.dart';

/// Immutable program-wide context shared by focused source emitters.
final class GeneratorContext {
  /// Creates a context and computes its wire-semantic digest.
  GeneratorContext({
    required this.program,
    required this.naming,
    required this.sourceDigest,
  }) : semanticDigest = SemanticDigest.compute(program),
       instructionHelpers = InstructionHelperNameAllocator(
         naming,
       ).allocate(program);

  /// Validated normalized program being emitted.
  final IdlProgram program;

  /// Naming policy shared by validation and emission.
  final NamingStrategy naming;

  /// SHA-256 digest of the original IDL source bytes.
  final String sourceDigest;

  /// SHA-256 digest of canonical wire-relevant IDL semantics.
  final String semanticDigest;

  /// Allocated helper type names for every instruction.
  final Map<IdlInstruction, InstructionHelperNames> instructionHelpers;

  /// Maps an IDL type or generated infrastructure name to Dart.
  String type(String wireName) => naming.typeName(wireName);

  /// Maps an IDL field or account path to a Dart member name.
  String member(String wireName) => naming.memberName(wireName);

  /// Allocates a unique Dart member name for [field] inside [scope].
  String fieldMember(List<IdlField> scope, IdlField field) {
    final index = scope.indexWhere((candidate) => identical(candidate, field));
    if (index < 0) return member(field.name);
    return DartMemberNameAllocator(naming).allocateFields(scope)[index];
  }

  /// Allocated helper names for [instruction].
  InstructionHelperNames helpers(IdlInstruction instruction) =>
      instructionHelpers[instruction]!;

  /// Deterministic header prepended to every generated library.
  String get header =>
      '''
// GENERATED CODE - DO NOT MODIFY BY HAND.
// tool: solana_idl_codegen
// generator-version: $solanaIdlGeneratorVersion
// source-sha256: $sourceDigest
// semantic-ir-sha256: $semanticDigest
// SPDX-License-Identifier: MIT
// ignore_for_file: prefer_initializing_formals, unused_element, unused_import, use_super_parameters

''';
}
