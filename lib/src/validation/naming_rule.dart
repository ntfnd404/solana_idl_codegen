import '../generator/name_allocator.dart';
import '../idl.dart';
import '../naming.dart';
import 'validation_issue.dart';

/// Detects collisions introduced by Dart naming and generated infrastructure.
final class NamingValidationRule {
  /// Creates a naming rule using [naming].
  const NamingValidationRule(this.naming);

  /// Naming strategy shared with code generation.
  final NamingStrategy naming;

  /// Validates all generated type and member namespaces.
  void validate(IdlProgram program, ValidationIssue issue) {
    const reserved = {
      'codec',
      'copyWith',
      'programAddress',
      'discriminator',
      'encode',
      'decodeExact',
      'decodePrefix',
      'toWire',
      'hashCode',
      'runtimeType',
      'toString',
      'noSuchMethod',
    };
    final generated = <String, String>{};
    void members(Iterable<IdlField> fields) {
      final scope = <String, String>{};
      for (final field in fields) {
        final dartName = naming.memberName(field.name);
        final previous = scope[dartName];
        if (previous != null && previous != field.name) {
          issue(
            'IDL_DART_MEMBER_COLLISION',
            'Wire fields "$previous" and "${field.name}" both map to '
                '"$dartName".',
            field.sourcePath,
          );
        }
        scope[dartName] = field.name;
        if (!reserved.contains(dartName)) continue;
        issue(
          'IDL_RESERVED_MEMBER',
          'Field "${field.name}" collides with generated or inherited API.',
          field.sourcePath,
        );
      }
    }

    void add(String source, String path) {
      final dart = naming.typeName(source);
      final previous = generated[dart];
      if (previous != null && previous != source) {
        issue(
          'IDL_DART_NAME_COLLISION',
          'Wire names "$previous" and "$source" both map to "$dart".',
          path,
        );
      }
      generated[dart] = source;
    }

    for (final infrastructure in const {
      'address',
      'account_meta',
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
      'events_client',
      'view_client',
      'instructions_client',
      'client',
      'program_exception',
      'program_error_parser',
    }) {
      generated[naming.typeName(infrastructure)] =
          '<generated:$infrastructure>';
    }
    for (final definition in program.types) {
      add(definition.name, definition.sourcePath);
      switch (definition.body) {
        case IdlStructBody(:final fields):
          members(fields);
        case IdlEnumBody(:final variants):
          for (final variant in variants) {
            add('${definition.name}_${variant.name}', variant.sourcePath);
            members(variant.fields);
          }
        case IdlAliasBody():
          break;
      }
    }
    try {
      InstructionHelperNameAllocator(naming).allocate(program);
    } on StateError catch (error) {
      issue(
        'IDL_DART_NAME_COLLISION',
        error.message,
        program.instructions.isEmpty
            ? r'$'
            : program.instructions.first.sourcePath,
      );
    }

    for (final instruction in program.instructions) {
      members(instruction.arguments);
      final accountMembers = <String, String>{};
      void visit(
        List<IdlInstructionAccount> nodes, [
        String flattenedPrefix = '',
        String wirePrefix = '',
      ]) {
        for (final node in nodes) {
          final flattened = flattenedPrefix.isEmpty
              ? node.name
              : '${flattenedPrefix}_${node.name}';
          final wire = wirePrefix.isEmpty
              ? node.name
              : '$wirePrefix.${node.name}';
          switch (node) {
            case IdlAccountGroup(:final accounts):
              visit(accounts, flattened, wire);
            case IdlAccountItem():
              final dartName = naming.memberName(flattened);
              final previous = accountMembers[dartName];
              if (previous != null && previous != wire) {
                issue(
                  'IDL_DART_ACCOUNT_MEMBER_COLLISION',
                  'Account paths "$previous" and "$wire" both map to '
                      '"$dartName".',
                  node.sourcePath,
                );
              }
              accountMembers[dartName] = wire;
          }
        }
      }

      visit(instruction.accounts);
    }
  }
}
