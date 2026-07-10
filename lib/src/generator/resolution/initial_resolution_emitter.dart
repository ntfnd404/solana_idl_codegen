import 'package:code_builder/code_builder.dart';

import '../account_leaf.dart';
import '../section_emitter.dart';
import 'resolution_local_names.dart';

/// Emits initial account resolution from overrides, fixed addresses, identity.
final class InitialResolutionEmitter extends SectionEmitter {
  /// Creates an initial-resolution emitter for [context].
  const InitialResolutionEmitter(super.context);

  @override
  List<Spec> emit() => const [];

  /// Emits local variables and the initial override/fixed/identity phase.
  void emitInitialResolution(StringBuffer out, List<AccountLeaf> leaves) {
    for (final leaf in leaves) {
      final local = member(leaf.path);
      final suppressed = resolutionSuppressedMember(leaf, member);
      final needsSuppressed = resolutionNeedsSuppressedState(leaf);
      final item = leaf.item;
      out.writeln('    ${type('address')}? $local;');
      if (needsSuppressed) {
        out.writeln('    var $suppressed = false;');
      }
      out
        ..writeln('    switch (overrides.$local) {')
        ..writeln('      case ${type('use_account_override')}(:final address):')
        ..writeln('        $local = address;');
      if (needsSuppressed) {
        out.writeln('        $suppressed = false;');
      }
      out
        ..writeln('      case ${type('absent_account_override')}():')
        ..writeln(
          needsSuppressed
              ? '        $suppressed = true;'
              : '        $local = null;',
        );
      if (!item.optional) {
        out.writeln(
          "        causes.add(const ${type('account_resolution_cause')}(path: '${escape(leaf.wirePath)}', code: 'RESOLUTION_REQUIRED_ABSENT', message: 'Required account cannot be absent.'));",
        );
      }
      out.writeln('      case ${type('inherit_account_override')}():');
      if (needsSuppressed) {
        out.writeln('        $suppressed = false;');
      }
      if (item.address != null) {
        out.writeln(
          "        $local = ${type('address')}.fromBase58('${escape(item.address!)}');",
        );
      } else {
        out
          ..writeln(
            "        if (context.identityAccountPaths.contains('${escape(leaf.wirePath)}') && context.identity != null) {",
          )
          ..writeln('          $local = context.identity;')
          ..writeln('        }');
      }
      out.writeln('    }');
    }
  }
}
