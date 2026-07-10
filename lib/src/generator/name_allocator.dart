import '../idl.dart';
import '../naming.dart';

/// Deterministically assigns unique Dart member names inside one scope.
final class DartMemberNameAllocator {
  /// Creates an allocator backed by the shared [naming] strategy.
  const DartMemberNameAllocator(this.naming);

  /// Naming strategy used for the initial wire-to-Dart conversion.
  final NamingStrategy naming;

  /// Allocates one Dart member name for each [field] while preserving order.
  List<String> allocateFields(List<IdlField> fields) {
    final used = <String>{};
    final nextSuffix = <String, int>{};
    return List.unmodifiable([
      for (final field in fields)
        _allocate(naming.memberName(field.name), used, nextSuffix),
    ]);
  }

  String _allocate(String base, Set<String> used, Map<String, int> nextSuffix) {
    if (used.add(base)) {
      nextSuffix.putIfAbsent(base, () => 2);
      return base;
    }

    var suffix = nextSuffix[base] ?? 2;
    while (true) {
      final candidate = '$base$suffix';
      suffix++;
      if (used.add(candidate)) {
        nextSuffix[base] = suffix;
        return candidate;
      }
    }
  }
}

/// Deterministically assigns generated helper type names for instructions.
final class InstructionHelperNameAllocator {
  /// Creates an allocator backed by the shared [naming] strategy.
  const InstructionHelperNameAllocator(this.naming);

  /// Naming strategy used for wire-to-Dart type conversion.
  final NamingStrategy naming;

  /// Allocates helper type names while preserving existing names when possible.
  Map<IdlInstruction, InstructionHelperNames> allocate(IdlProgram program) {
    final used = <String>{
      for (final definition in program.types) naming.typeName(definition.name),
      for (final definition in program.types)
        if (definition.body case IdlEnumBody(:final variants))
          for (final variant in variants)
            naming.typeName('${definition.name}_${variant.name}'),
      for (final account in program.accounts) ...{
        naming.typeName(account.name),
        naming.typeName('${account.name}_account'),
      },
      for (final event in program.events) ...{
        naming.typeName(event.name),
        naming.typeName('${event.name}_event'),
      },
    };
    for (final infrastructure in _generatedInfrastructure) {
      used.add(naming.typeName(infrastructure));
    }

    final result = <IdlInstruction, InstructionHelperNames>{};
    for (final instruction in program.instructions) {
      result[instruction] = InstructionHelperNames(
        args: _allocate(
          used,
          preferred: naming.typeName('${instruction.name}_args'),
          fallback: naming.typeName('${instruction.name}_instruction_args'),
          source: instruction.sourcePath,
        ),
        accounts: _allocate(
          used,
          preferred: naming.typeName('${instruction.name}_accounts'),
          fallback: naming.typeName('${instruction.name}_instruction_accounts'),
          source: instruction.sourcePath,
        ),
        accountOverrides: _allocate(
          used,
          preferred: naming.typeName('${instruction.name}_account_overrides'),
          fallback: naming.typeName(
            '${instruction.name}_instruction_account_overrides',
          ),
          source: instruction.sourcePath,
        ),
        accountResolver: _allocate(
          used,
          preferred: naming.typeName('${instruction.name}_account_resolver'),
          fallback: naming.typeName(
            '${instruction.name}_instruction_account_resolver',
          ),
          source: instruction.sourcePath,
        ),
        request: _allocate(
          used,
          preferred: naming.typeName('${instruction.name}_request'),
          fallback: naming.typeName('${instruction.name}_instruction_request'),
          source: instruction.sourcePath,
        ),
      );
    }
    return Map.unmodifiable(result);
  }

  String _allocate(
    Set<String> used, {
    required String preferred,
    required String fallback,
    required String source,
  }) {
    if (used.add(preferred)) return preferred;
    if (used.add(fallback)) return fallback;
    throw StateError(
      'Generated helper name collision at $source: $preferred and $fallback.',
    );
  }

  static const _generatedInfrastructure = {
    'address',
    'account_meta',
    'account_metadata',
    'instruction_account_metadata',
    'instruction_metadata',
    'instruction',
    'decode_limits',
    'borsh_exception',
    'borsh_reader',
    'borsh_writer',
    'borsh_codec',
    'functional_borsh_codec',
    'transaction_failure',
    'account_exception',
    'view_exception',
    'account_snapshot',
    'commitment',
    'account_read_options',
    'account_filter',
    'memcmp_filter',
    'data_size_filter',
    'account_reader',
    'account_scanner',
    'event_subscriber',
    'event_subscription',
    'log_batch',
    'transaction_simulator',
    'simulation_result',
    'pda_deriver',
    'pda_result',
    'relation_resolver',
    'external_account_seed_resolver',
    'external_account_seed_resolver_callback',
    'account_override',
    'inherit_account_override',
    'use_account_override',
    'absent_account_override',
    'resolution_context',
    'account_resolution_cause',
    'account_resolution_exception',
    'pda_exception',
    'program',
    'constants',
    'accounts_client',
    'account_registry',
    'events_client',
    'view_client',
    'instructions_client',
    'instruction_registry',
    'client',
    'program_exception',
    'program_error_parser',
  };
}

/// Generated helper type names for one instruction.
final class InstructionHelperNames {
  /// Creates allocated helper names.
  const InstructionHelperNames({
    required this.args,
    required this.accounts,
    required this.accountOverrides,
    required this.accountResolver,
    required this.request,
  });

  /// Args model type.
  final String args;

  /// Resolved accounts model type.
  final String accounts;

  /// Account override model type.
  final String accountOverrides;

  /// Account resolver type.
  final String accountResolver;

  /// Prepared request type.
  final String request;
}
