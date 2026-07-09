import '../idl.dart';

/// Flattened leaf of a possibly nested instruction-account tree.
final class AccountLeaf {
  /// Creates a leaf with generated [path], source [wirePath], and IDL [item].
  const AccountLeaf(this.path, this.wirePath, this.item);

  /// Flattened identifier path used by generated Dart members.
  final String path;

  /// Canonical dot-separated account path from the IDL.
  final String wirePath;

  /// Account metadata declared by the IDL.
  final IdlAccountItem item;
}
