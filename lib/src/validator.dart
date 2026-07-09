import 'idl.dart';
import 'naming.dart';
import 'parser.dart';
import 'validation/account_declaration_rule.dart';
import 'validation/account_rule.dart';
import 'validation/address_rule.dart';
import 'validation/constant_declaration_rule.dart';
import 'validation/constant_rule.dart';
import 'validation/discriminator_namespace_rule.dart';
import 'validation/discriminator_rule.dart';
import 'validation/event_declaration_rule.dart';
import 'validation/instruction_rule.dart';
import 'validation/naming_rule.dart';
import 'validation/program_uniqueness_rule.dart';
import 'validation/type_definition_rule.dart';
import 'validation/type_rule.dart';
import 'validation/uniqueness_rule.dart';

/// Validates referential, naming, discriminator and wire-layout invariants.
final class IdlValidator {
  /// Creates a validator using [naming] for collision detection.
  const IdlValidator({
    this.naming = const DartNamingStrategy(),
    this.addressRule = const AddressValidationRule(),
    this.accountRule = const AccountValidationRule(),
    this.constantRule = const ConstantValidationRule(),
    this.discriminatorRule = const DiscriminatorValidationRule(),
    this.uniquenessRule = const UniquenessValidationRule(),
    this.typeRule = const TypeValidationRule(),
    this.accountDeclarationRule = const AccountDeclarationValidationRule(),
    this.constantDeclarationRule = const ConstantDeclarationValidationRule(),
    this.discriminatorNamespaceRule =
        const DiscriminatorNamespaceValidationRule(),
    this.eventDeclarationRule = const EventDeclarationValidationRule(),
    this.instructionRule = const InstructionValidationRule(),
    this.programUniquenessRule = const ProgramUniquenessValidationRule(),
    this.typeDefinitionRule = const TypeDefinitionValidationRule(),
  });

  /// Naming policy used to detect post-normalization collisions.
  final NamingStrategy naming;

  /// Rule responsible for Solana address validation.
  final AddressValidationRule addressRule;

  /// Rule responsible for nested accounts, relations, and PDA metadata.
  final AccountValidationRule accountRule;

  /// Rule responsible for typed constant ranges.
  final ConstantValidationRule constantRule;

  /// Rule responsible for discriminator safety.
  final DiscriminatorValidationRule discriminatorRule;

  /// Rule responsible for source namespace uniqueness.
  final UniquenessValidationRule uniquenessRule;

  /// Rule responsible for type references and Borsh layout recursion.
  final TypeValidationRule typeRule;

  /// Rule responsible for top-level account declaration validation.
  final AccountDeclarationValidationRule accountDeclarationRule;

  /// Rule responsible for constant declarations and literal compatibility.
  final ConstantDeclarationValidationRule constantDeclarationRule;

  /// Rule responsible for discriminator prefix ambiguity.
  final DiscriminatorNamespaceValidationRule discriminatorNamespaceRule;

  /// Rule responsible for top-level event declaration validation.
  final EventDeclarationValidationRule eventDeclarationRule;

  /// Rule responsible for instruction declarations.
  final InstructionValidationRule instructionRule;

  /// Rule responsible for top-level source uniqueness.
  final ProgramUniquenessValidationRule programUniquenessRule;

  /// Rule responsible for type definitions and nested layout types.
  final TypeDefinitionValidationRule typeDefinitionRule;

  /// Validates [program] and throws one aggregate internal format failure.
  void validate(IdlProgram program) {
    final issues = <IdlFormatException>[];
    void issue(String code, String message, String path) {
      issues.add(IdlFormatException(message, path, code: code));
    }

    if (!program.isLegacy && program.spec != '0.1.0') {
      issue(
        'IDL_DIALECT_UNSUPPORTED',
        'Unsupported Anchor IDL spec "${program.spec}".',
        r'$.metadata.spec',
      );
    }
    addressRule.validate(program.address, r'$.address', issue);
    programUniquenessRule.validate(program, issue);
    NamingValidationRule(naming).validate(program, issue);

    final definitions = {
      for (final definition in program.types) definition.name: definition,
    };
    accountDeclarationRule.validate(program, definitions, issue);
    eventDeclarationRule.validate(program, definitions, issue);
    instructionRule.validate(program, definitions, issue);
    typeDefinitionRule.validate(program, definitions, issue);
    constantDeclarationRule.validate(program, definitions, issue);
    typeRule.validateRecursiveLayouts(definitions, issue);
    discriminatorNamespaceRule.validate(program, issue);
    if (issues.isNotEmpty) {
      final first = issues.first;
      throw IdlFormatException(
        first.message,
        first.path,
        code: first.code,
        location: first.location,
        related: issues.skip(1).toList(growable: false),
      );
    }
  }
}
