import '../account_leaf.dart';

/// Generated local-variable naming helpers for account resolution emitters.
String resolutionSuppressedMember(
  AccountLeaf leaf,
  String Function(String) member,
) => '${member(leaf.path)}Suppressed';

/// Whether a generated account local needs an explicit suppression flag.
bool resolutionNeedsSuppressedState(AccountLeaf leaf) =>
    !leaf.item.optional ||
    leaf.item.seeds.isNotEmpty ||
    leaf.item.relations.isNotEmpty;
