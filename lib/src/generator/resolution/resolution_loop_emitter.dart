import 'package:code_builder/code_builder.dart';

import '../../idl.dart';
import '../account_leaf.dart';
import '../section_emitter.dart';
import 'pda_resolution_emitter.dart';
import 'relation_resolution_emitter.dart';
import 'resolution_local_names.dart';

/// Emits the multi-pass PDA/relation resolution loop.
final class ResolutionLoopEmitter extends SectionEmitter {
  /// Creates a resolution-loop emitter for [context].
  const ResolutionLoopEmitter(super.context);

  @override
  List<Spec> emit() => const [];

  /// Emits the bounded resolution loop for PDA and relation metadata.
  void emitResolutionLoop(
    StringBuffer out,
    IdlInstruction instruction,
    List<AccountLeaf> leaves,
  ) {
    if (!leaves.any(
      (leaf) => leaf.item.seeds.isNotEmpty || leaf.item.relations.isNotEmpty,
    )) {
      return;
    }
    out
      ..writeln('    for (var pass = 0; pass < ${leaves.length}; pass++) {')
      ..writeln('      var progressed = false;');
    _emitPdaAndRelations(out, instruction, leaves, '      ');
    out
      ..writeln(
        '      if (${_allResolutionParticipantsResolvedCondition(leaves)}) break;',
      )
      ..writeln('      if (!progressed) break;')
      ..writeln('    }');
  }

  void _emitPdaAndRelations(
    StringBuffer out,
    IdlInstruction instruction,
    List<AccountLeaf> leaves,
    String indent,
  ) {
    var generatedSeedId = 0;
    for (final leaf in leaves) {
      final item = leaf.item;
      if (item.seeds.isNotEmpty) {
        generatedSeedId = PdaResolutionEmitter(context).emitPdaResolution(
          out,
          instruction,
          leaves,
          leaf,
          generatedSeedId,
          indent,
        );
      }
      if (item.relations.isNotEmpty) {
        RelationResolutionEmitter(
          context,
        ).emitRelationResolution(out, leaves, leaf, indent);
      }
    }
  }

  String _allResolutionParticipantsResolvedCondition(List<AccountLeaf> leaves) {
    final participants = leaves
        .where(
          (item) =>
              item.item.seeds.isNotEmpty || item.item.relations.isNotEmpty,
        )
        .toList();
    if (participants.isEmpty) return 'true';
    return participants
        .map(
          (item) =>
              '${member(item.path)} != null || ${resolutionSuppressedMember(item, member)}',
        )
        .join(' && ');
  }
}
