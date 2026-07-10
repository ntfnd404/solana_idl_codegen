import '../account_dependency_graph.dart';
import '../idl.dart';
import '../idl_path_matcher.dart';
import 'account_tree_rule.dart';
import 'address_rule.dart';
import 'pda_seed_rule.dart';
import 'relation_rule.dart';
import 'type_path_resolver.dart';
import 'validation_issue.dart';

/// Validates nested instruction accounts, relations, and PDA seed metadata.
final class AccountValidationRule {
  /// Creates a stateless account and PDA validation rule.
  const AccountValidationRule({
    this.accountTreeRule = const AccountTreeValidationRule(),
    this.pdaSeedRule = const PdaSeedValidationRule(),
    this.relationRule = const RelationValidationRule(),
    this.typePathResolver = const TypePathResolver(),
  });

  /// Rule responsible for nested path uniqueness and leaf indexing.
  final AccountTreeValidationRule accountTreeRule;

  /// Rule responsible for PDA seed type, path, and value compatibility.
  final PdaSeedValidationRule pdaSeedRule;

  /// Rule responsible for relation target validation.
  final RelationValidationRule relationRule;

  /// Resolver for nested argument and account-data field paths.
  final TypePathResolver typePathResolver;

  /// Validates the account tree of [instruction].
  void validate(
    IdlInstruction instruction,
    Map<String, IdlTypeDefinition> definitions,
    Set<String> programAccounts,
    AddressValidationRule addressRule,
    ValidationIssue issue,
  ) {
    final tree = accountTreeRule.validate(instruction.accounts, issue);
    for (final item in tree.leafItems.values) {
      _validateItem(item, instruction, definitions, addressRule, issue);
    }
    relationRule.validate(instruction.accounts, tree.leaves, issue);
    _validateAccountSeeds(
      instruction,
      definitions,
      programAccounts,
      tree.leafItems,
      issue,
    );
  }

  void _validateItem(
    IdlAccountItem item,
    IdlInstruction instruction,
    Map<String, IdlTypeDefinition> definitions,
    AddressValidationRule addressRule,
    ValidationIssue issue,
  ) {
    if (item.address case final address?) {
      addressRule.validate(address, '${item.sourcePath}.address', issue);
    }
    if (item.seeds.length > 15) {
      issue(
        'IDL_PDA_SEED_COUNT',
        'At most 15 IDL seeds are allowed before the bump.',
        '${item.sourcePath}.pda.seeds',
      );
    }
    for (final seed in item.seeds) {
      if (seed is IdlPathSeed && seed.kind == 'arg') {
        final resolvedType = typePathResolver.resolveArgumentPath(
          instruction.arguments,
          seed.path,
          definitions,
        );
        if (resolvedType == null) {
          issue(
            'IDL_PDA_ARG_PATH',
            'PDA argument path "${seed.path}" is undefined.',
            seed.sourcePath,
          );
        } else {
          pdaSeedRule.validateSeedType(
            seed.valueType ?? resolvedType,
            seed.sourcePath,
            issue,
          );
        }
      }
      if (seed is IdlConstSeed) {
        pdaSeedRule.validateConstSeed(seed, issue);
      }
    }
    if (item.pdaProgram case final programSeed?) {
      pdaSeedRule.validateSeedType(
        programSeed.valueType ?? const IdlPrimitiveType('pubkey'),
        programSeed.sourcePath,
        issue,
      );
    }
  }

  void _validateAccountSeeds(
    IdlInstruction instruction,
    Map<String, IdlTypeDefinition> definitions,
    Set<String> programAccounts,
    Map<String, IdlAccountItem> leafItems,
    ValidationIssue issue,
  ) {
    final graph = AccountDependencyGraph.pdaValidation(instruction);
    for (final entry in leafItems.entries) {
      for (final seed in entry.value.seeds.whereType<IdlPathSeed>()) {
        if (seed.kind != 'account') continue;
        if (seed.valueType case final declaredType?) {
          pdaSeedRule.validateSeedType(declaredType, seed.sourcePath, issue);
        }
        final dependency = graph.accountPathFor(seed.path);
        if (dependency == null) {
          issue(
            'IDL_PDA_ACCOUNT_PATH',
            'PDA account path "${seed.path}" is undefined.',
            seed.sourcePath,
          );
        } else if (!IdlPathMatcher.pathsMatch(seed.path, dependency)) {
          _validateAccountDataSeed(
            seed,
            dependency,
            definitions,
            programAccounts,
            issue,
          );
        }
      }
    }
    if (graph.findCycle() case final cycle?) {
      issue(
        'IDL_ACCOUNT_RESOLUTION_CYCLE',
        'Account resolution dependency cycle: ${cycle.join(' -> ')}.',
        instruction.sourcePath,
      );
    }
  }

  void _validateAccountDataSeed(
    IdlPathSeed seed,
    String dependency,
    Map<String, IdlTypeDefinition> definitions,
    Set<String> programAccounts,
    ValidationIssue issue,
  ) {
    if (seed.account == null) {
      issue(
        'IDL_PDA_ACCOUNT_DATA_TYPE',
        'Account-data seed "${seed.path}" requires an account type.',
        seed.sourcePath,
      );
      return;
    }
    if (!programAccounts.contains(seed.account)) {
      if (seed.valueType == null) {
        issue(
          'IDL_PDA_EXTERNAL_SEED_TYPE',
          'External account-data seed "${seed.path}" requires an '
              'explicit supported seed type.',
          seed.sourcePath,
        );
      }
      return;
    }

    final fields = seed.path.substring(dependency.length + 1).split('.');
    final fieldPath = fields.join('.');
    if (!typePathResolver.hasAccountFieldPath(
      seed.account!,
      fieldPath,
      definitions,
    )) {
      issue(
        'IDL_PDA_ACCOUNT_FIELD',
        'Account-data seed field "${seed.path}" is undefined.',
        seed.sourcePath,
      );
    } else if (seed.valueType case final seedType?) {
      pdaSeedRule.validateSeedType(seedType, seed.sourcePath, issue);
    }
  }
}
