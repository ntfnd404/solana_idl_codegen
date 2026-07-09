import 'dart:collection';

import 'definitions.dart';
import 'instruction.dart';
import 'types.dart';

/// Anchor IDL dialect selected by the parser factory.
enum AnchorIdlDialect {
  /// Anchor IDLs generated before version 0.30.
  legacy,

  /// Modern Anchor IDL schema with explicit discriminators.
  modern,
}

/// Immutable intermediate representation of an Anchor program IDL.
final class IdlProgram {
  /// Creates an immutable program definition.
  IdlProgram({
    required this.name,
    required this.version,
    required this.spec,
    required this.address,
    required List<String> docs,
    required List<IdlInstruction> instructions,
    required List<IdlAccountDefinition> accounts,
    required List<IdlEventDefinition> events,
    required List<IdlErrorDefinition> errors,
    required List<IdlConstantDefinition> constants,
    required List<IdlTypeDefinition> types,
    required this.dialect,
  }) : docs = List.unmodifiable(docs),
       instructions = List.unmodifiable(instructions),
       accounts = List.unmodifiable(accounts),
       events = List.unmodifiable(events),
       errors = List.unmodifiable(errors),
       constants = List.unmodifiable(constants),
       types = List.unmodifiable(types);

  /// Program name from IDL metadata.
  final String name;

  /// Program version from IDL metadata.
  final String version;

  /// Anchor IDL specification version, or `legacy`.
  final String spec;

  /// Base58 on-chain program address.
  final String address;

  /// Program-level documentation lines.
  final List<String> docs;

  /// Program instruction definitions in wire order.
  final List<IdlInstruction> instructions;

  /// Program account definitions.
  final List<IdlAccountDefinition> accounts;

  /// Program event definitions.
  final List<IdlEventDefinition> events;

  /// Custom program error definitions.
  final List<IdlErrorDefinition> errors;

  /// Typed IDL constants.
  final List<IdlConstantDefinition> constants;

  /// Named type definitions.
  final List<IdlTypeDefinition> types;

  /// IDL dialect used to decode this program.
  final AnchorIdlDialect dialect;

  /// Whether this program was normalized from a legacy IDL.
  bool get isLegacy => dialect == AnchorIdlDialect.legacy;

  /// Named type definitions indexed by their wire names.
  Map<String, IdlTypeDefinition> get typesByName =>
      UnmodifiableMapView({for (final type in types) type.name: type});
}
