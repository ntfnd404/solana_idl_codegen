import 'package:code_builder/code_builder.dart';

import '../account_leaf.dart';
import '../section_emitter.dart';
import 'resolution_local_names.dart';

/// Emits terminal resolution failures for required accounts.
final class ResolutionFailureEmitter extends SectionEmitter {
  /// Creates a resolution-failure emitter for [context].
  const ResolutionFailureEmitter(super.context);

  @override
  List<Spec> emit() => const [];

  /// Emits final unresolved required-account checks.
  void emitRequiredChecks(StringBuffer out, List<AccountLeaf> leaves) {
    for (final leaf in leaves.where((item) => !item.item.optional)) {
      final local = member(leaf.path);
      final suppressed = resolutionSuppressedMember(leaf, member);
      out
        ..writeln('    if ($local == null && !$suppressed) {')
        ..writeln(
          "      causes.add(const ${type('account_resolution_cause')}(path: '${escape(leaf.wirePath)}', code: 'RESOLUTION_UNRESOLVED', message: 'No override, fixed address, allowed identity, PDA, or relation resolved this account.'));",
        )
        ..writeln('    }');
    }
  }
}
