import '../idl.dart';
import 'account_leaf.dart';

/// Flattens nested instruction account groups into ordered leaf accounts.
final class AccountLeafFlattener {
  /// Creates a stateless account-leaf flattener.
  const AccountLeafFlattener();

  /// Flattens [nodes] while preserving source order and nested paths.
  List<AccountLeaf> flatten(
    List<IdlInstructionAccount> nodes, [
    String prefix = '',
    String wirePrefix = '',
  ]) {
    final result = <AccountLeaf>[];
    for (final node in nodes) {
      final path = prefix.isEmpty ? node.name : '${prefix}_${node.name}';
      final wirePath = wirePrefix.isEmpty
          ? node.name
          : '$wirePrefix.${node.name}';
      switch (node) {
        case IdlAccountItem():
          result.add(AccountLeaf(path, wirePath, node));
        case IdlAccountGroup(:final accounts):
          result.addAll(flatten(accounts, path, wirePath));
      }
    }
    return result;
  }
}
