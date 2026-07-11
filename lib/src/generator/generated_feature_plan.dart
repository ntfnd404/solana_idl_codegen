import '../idl.dart';

/// Program-wide features that control optional generated declarations.
///
/// The plan is derived from validated semantic IR, so emitters do not need to
/// infer dependencies by searching formatted Dart source.
final class GeneratedFeaturePlan {
  const GeneratedFeaturePlan._({
    required this.usesStructuralListEquality,
    required this.hasEvents,
    required this.hasInstructions,
    required this.hasAccounts,
    required this.hasPdaSeeds,
    required this.hasViews,
    required this.typesUseTypedData,
    required this.instructionsUseTypedData,
    required this.clientUsesTypedData,
    required this.resolutionUsesConvert,
    required this.resolutionUsesAccounts,
    required this.resolutionUsesTypes,
  });

  /// Computes generated features for [program].
  factory GeneratedFeaturePlan.fromProgram(IdlProgram program) {
    final views = program.instructions
        .where(isViewInstruction)
        .toList(growable: false);
    return GeneratedFeaturePlan._(
      usesStructuralListEquality: program.types.any(
        (definition) => _bodyUsesStructuralListEquality(definition.body),
      ),
      hasEvents: program.events.isNotEmpty,
      hasInstructions: program.instructions.isNotEmpty,
      hasAccounts: program.accounts.isNotEmpty,
      hasPdaSeeds: program.instructions.any(
        (instruction) => _accountsHavePdaSeeds(instruction.accounts),
      ),
      hasViews: views.isNotEmpty,
      typesUseTypedData:
          program.types.any(
            (definition) => _bodyUsesTypedData(definition.body),
          ) ||
          program.constants.any(
            (constant) => _typeUsesTypedData(constant.type),
          ),
      instructionsUseTypedData: program.instructions.any(
        (instruction) => instruction.arguments.any(
          (argument) => _typeUsesTypedData(argument.type),
        ),
      ),
      clientUsesTypedData: views.any(
        (instruction) => _typeUsesTypedData(instruction.returns!),
      ),
      resolutionUsesConvert: program.instructions.any(
        (instruction) => _accountsUseUtf8Seeds(instruction.accounts),
      ),
      resolutionUsesAccounts: program.instructions.any(
        (instruction) => _accountsUseLocalAccountDataSeeds(
          instruction.accounts,
          program.accounts.map((account) => account.name).toSet(),
        ),
      ),
      resolutionUsesTypes: program.instructions.any(
        (instruction) => _accountsNeedProgramMetadata(instruction.accounts),
      ),
    );
  }

  /// Whether generated value equality needs the private list helper.
  final bool usesStructuralListEquality;

  /// Whether event decoding needs discriminator-prefix matching.
  final bool hasEvents;

  /// Whether the program declares any instructions.
  final bool hasInstructions;

  /// Whether the program declares generated account decoders.
  final bool hasAccounts;

  /// Whether account resolution emits byte-oriented PDA derivation code.
  final bool hasPdaSeeds;

  /// Whether the client emits at least one read-only view method.
  final bool hasViews;

  /// Whether type declarations mention `Uint8List`.
  final bool typesUseTypedData;

  /// Whether instruction declarations mention [Uint8List].
  final bool instructionsUseTypedData;

  /// Whether emitted view signatures mention `Uint8List`.
  final bool clientUsesTypedData;

  /// Whether PDA resolution encodes string seeds with `utf8`.
  final bool resolutionUsesConvert;

  /// Whether PDA resolution decodes a generated account type.
  final bool resolutionUsesAccounts;

  /// Whether resolution references generated program metadata.
  final bool resolutionUsesTypes;

  static bool _bodyUsesStructuralListEquality(IdlTypeBody body) =>
      switch (body) {
        IdlAliasBody() => false,
        IdlStructBody(:final fields, :final tupleFields) =>
          fields.any((field) => _typeUsesStructuralListEquality(field.type)) ||
              tupleFields.any(_typeUsesStructuralListEquality),
        IdlEnumBody(:final variants) => variants.any(
          (variant) =>
              variant.fields.any(
                (field) => _typeUsesStructuralListEquality(field.type),
              ) ||
              variant.tupleFields.any(_typeUsesStructuralListEquality),
        ),
      };

  static bool _typeUsesStructuralListEquality(IdlType type) => switch (type) {
    IdlPrimitiveType(name: 'bytes') ||
    IdlVectorType() ||
    IdlArrayType() ||
    IdlGenericArrayType() => true,
    IdlOptionType(:final inner) ||
    IdlCOptionType(:final inner) => _typeUsesStructuralListEquality(inner),
    _ => false,
  };

  static bool _typeUsesTypedData(IdlType type) => switch (type) {
    IdlPrimitiveType(name: 'bytes') => true,
    IdlOptionType(:final inner) ||
    IdlCOptionType(:final inner) ||
    IdlVectorType(:final inner) ||
    IdlArrayType(:final inner) ||
    IdlGenericArrayType(:final inner) => _typeUsesTypedData(inner),
    IdlDefinedType(:final generics) => generics.any(_typeUsesTypedData),
    _ => false,
  };

  static bool _bodyUsesTypedData(IdlTypeBody body) => switch (body) {
    IdlAliasBody(:final value) => _typeUsesTypedData(value),
    IdlStructBody(:final fields, :final tupleFields) =>
      fields.any((field) => _typeUsesTypedData(field.type)) ||
          tupleFields.any(_typeUsesTypedData),
    IdlEnumBody(:final variants) => variants.any(
      (variant) =>
          variant.fields.any((field) => _typeUsesTypedData(field.type)) ||
          variant.tupleFields.any(_typeUsesTypedData),
    ),
  };

  static bool _accountsUseUtf8Seeds(List<IdlInstructionAccount> accounts) {
    for (final account in accounts) {
      switch (account) {
        case IdlAccountGroup(:final accounts):
          if (_accountsUseUtf8Seeds(accounts)) return true;
        case IdlAccountItem(:final seeds, :final pdaProgram):
          if ([...seeds, ?pdaProgram].any(_seedUsesUtf8)) return true;
      }
    }
    return false;
  }

  static bool _accountsHavePdaSeeds(List<IdlInstructionAccount> accounts) {
    for (final account in accounts) {
      switch (account) {
        case IdlAccountGroup(:final accounts):
          if (_accountsHavePdaSeeds(accounts)) return true;
        case IdlAccountItem(:final seeds, :final pdaProgram):
          if (seeds.isNotEmpty || pdaProgram != null) return true;
      }
    }
    return false;
  }

  static bool _accountsUseLocalAccountDataSeeds(
    List<IdlInstructionAccount> accounts,
    Set<String> localAccounts,
  ) {
    for (final account in accounts) {
      switch (account) {
        case IdlAccountGroup(:final accounts):
          if (_accountsUseLocalAccountDataSeeds(accounts, localAccounts)) {
            return true;
          }
        case IdlAccountItem(:final seeds, :final pdaProgram):
          for (final seed in [...seeds, ?pdaProgram]) {
            if (seed case IdlPathSeed(kind: 'account', :final account?)) {
              if (localAccounts.contains(account)) return true;
            }
          }
      }
    }
    return false;
  }

  static bool _accountsNeedProgramMetadata(
    List<IdlInstructionAccount> accounts,
  ) {
    for (final account in accounts) {
      switch (account) {
        case IdlAccountGroup(:final accounts):
          if (_accountsNeedProgramMetadata(accounts)) return true;
        case IdlAccountItem(:final address, :final seeds, :final pdaProgram):
          if (address != null || seeds.isNotEmpty || pdaProgram != null) {
            return true;
          }
      }
    }
    return false;
  }

  static bool _seedUsesUtf8(IdlSeed seed) => switch (seed) {
    IdlConstSeed(value: IdlStringConstValue()) => true,
    IdlPathSeed(valueType: IdlPrimitiveType(name: 'string')) => true,
    _ => false,
  };
}

/// Whether [instruction] produces a generated read-only view method.
bool isViewInstruction(IdlInstruction instruction) =>
    instruction.returns != null &&
    !_accountsContainWritable(instruction.accounts);

bool _accountsContainWritable(List<IdlInstructionAccount> accounts) {
  for (final account in accounts) {
    switch (account) {
      case IdlAccountItem(:final writable):
        if (writable) return true;
      case IdlAccountGroup(:final accounts):
        if (_accountsContainWritable(accounts)) return true;
    }
  }
  return false;
}
