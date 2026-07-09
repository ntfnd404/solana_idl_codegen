import 'types.dart';

/// Instruction definition, including arguments, accounts and return type.
final class IdlInstruction {
  /// Creates an immutable instruction definition.
  IdlInstruction({
    required this.name,
    required List<String> docs,
    required List<int> discriminator,
    required List<IdlInstructionAccount> accounts,
    required List<IdlField> arguments,
    required this.returns,
    this.sourcePath = r'$',
  }) : docs = List.unmodifiable(docs),
       discriminator = List.unmodifiable(discriminator),
       accounts = List.unmodifiable(accounts),
       arguments = List.unmodifiable(arguments);

  /// Instruction wire name.
  final String name;

  /// Documentation lines supplied by the IDL.
  final List<String> docs;

  /// Non-empty instruction discriminator.
  final List<int> discriminator;

  /// Required account tree in IDL order.
  final List<IdlInstructionAccount> accounts;

  /// Serialized instruction arguments in wire order.
  final List<IdlField> arguments;

  /// Optional instruction return type.
  final IdlType? returns;

  /// JSON path at which this instruction was declared.
  final String sourcePath;
}

/// Base node for an instruction account or nested account group.
sealed class IdlInstructionAccount {
  /// Creates an account node with [name] and IDL [docs].
  IdlInstructionAccount(this.name, List<String> docs, {this.sourcePath = r'$'})
    : docs = List.unmodifiable(docs);

  /// Account or group wire name.
  final String name;

  /// Documentation lines supplied by the IDL.
  final List<String> docs;

  /// JSON path at which this account node was declared.
  final String sourcePath;
}

/// A leaf instruction account with signer, write and PDA metadata.
final class IdlAccountItem extends IdlInstructionAccount {
  /// Creates a leaf account definition.
  IdlAccountItem({
    required String name,
    required List<String> docs,
    required this.writable,
    required this.signer,
    required this.optional,
    required this.address,
    required List<String> relations,
    required List<IdlSeed> seeds,
    required this.pdaProgram,
    String sourcePath = r'$',
  }) : relations = List.unmodifiable(relations),
       seeds = List.unmodifiable(seeds),
       super(name, docs, sourcePath: sourcePath);

  /// Whether the instruction may write this account.
  final bool writable;

  /// Whether this account must sign the transaction.
  final bool signer;

  /// Whether callers may omit this account.
  final bool optional;

  /// Optional fixed Base58 account address.
  final String? address;

  /// Other account paths from which this address can be resolved.
  final List<String> relations;

  /// PDA derivation seeds, if this account can be resolved.
  final List<IdlSeed> seeds;

  /// Optional seed resolving the external PDA program.
  final IdlSeed? pdaProgram;
}

/// A named, nested group of instruction accounts.
final class IdlAccountGroup extends IdlInstructionAccount {
  /// Creates a nested account group.
  IdlAccountGroup({
    required String name,
    required List<String> docs,
    required List<IdlInstructionAccount> accounts,
    String sourcePath = r'$',
  }) : accounts = List.unmodifiable(accounts),
       super(name, docs, sourcePath: sourcePath);

  /// Child account nodes in IDL order.
  final List<IdlInstructionAccount> accounts;
}

/// Base definition of a PDA derivation seed.
sealed class IdlSeed {
  /// Creates a PDA seed with Anchor [kind].
  const IdlSeed(this.kind, this.valueType, this.sourcePath);

  /// Anchor seed kind such as `const`, `arg` or `account`.
  final String kind;

  /// Wire type used to serialize the seed when known.
  final IdlType? valueType;

  /// JSON path at which this seed was declared.
  final String sourcePath;
}

/// Base algebra for constant PDA seed values.
sealed class IdlConstValue {
  /// Creates a constant value.
  const IdlConstValue();
}

/// Constant integer seed value.
final class IdlIntegerConstValue extends IdlConstValue {
  /// Creates an integer constant.
  const IdlIntegerConstValue(this.value);

  /// Integer value.
  final BigInt value;
}

/// Constant boolean seed value.
final class IdlBooleanConstValue extends IdlConstValue {
  /// Creates a boolean constant.
  const IdlBooleanConstValue(this.value);

  /// Boolean value.
  final bool value;
}

/// Constant UTF-8 string seed value.
final class IdlStringConstValue extends IdlConstValue {
  /// Creates a string constant.
  const IdlStringConstValue(this.value);

  /// String value.
  final String value;
}

/// Constant raw byte seed value.
final class IdlBytesConstValue extends IdlConstValue {
  /// Creates a byte constant and copies [value].
  IdlBytesConstValue(List<int> value) : value = List.unmodifiable(value);

  /// Immutable raw bytes.
  final List<int> value;
}

/// A PDA seed containing constant bytes or a typed scalar.
final class IdlConstSeed extends IdlSeed {
  /// Creates a constant PDA seed from raw [value].
  const IdlConstSeed({
    required this.value,
    required IdlType? valueType,
    required String sourcePath,
  }) : super('const', valueType, sourcePath);

  /// Typed constant seed value.
  final IdlConstValue value;
}

/// A PDA seed resolved from an instruction argument or account path.
final class IdlPathSeed extends IdlSeed {
  /// Creates an argument or account-path seed.
  const IdlPathSeed({
    required String kind,
    required this.path,
    required this.account,
    required IdlType? valueType,
    required String sourcePath,
  }) : super(kind, valueType, sourcePath);

  /// IDL path used to resolve the seed value.
  final String path;

  /// Optional account type associated with [path].
  final String? account;
}
