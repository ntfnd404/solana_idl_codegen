import 'package:code_builder/code_builder.dart';

import '../account_leaf.dart';
import '../section_emitter.dart';
import 'resolution_local_names.dart';

/// Emits relation resolver attempts for generated account resolvers.
final class RelationResolutionEmitter extends SectionEmitter {
  /// Creates a relation-resolution emitter for [context].
  const RelationResolutionEmitter(super.context);

  @override
  List<Spec> emit() => const [];

  /// Emits relation attempts for one account leaf.
  void emitRelationResolution(
    StringBuffer out,
    List<AccountLeaf> leaves,
    AccountLeaf leaf,
    String indent,
  ) {
    final local = member(leaf.path);
    final suppressed = resolutionSuppressedMember(leaf, member);
    out
      ..writeln('${indent}if ($local == null && !$suppressed) {')
      ..writeln('$indent  final relationResolver = context.relationResolver;')
      ..writeln('$indent  if (relationResolver != null) {');
    for (var index = 0; index < leaf.item.relations.length; index++) {
      final relation = leaf.item.relations[index];
      final resolved = '${local}Relation$index';
      out
        ..writeln('$indent    if ($local == null) {')
        ..writeln(
          '$indent      final $resolved = await relationResolver.resolveRelation(',
        )
        ..writeln("$indent        accountPath: '${escape(leaf.wirePath)}',")
        ..writeln("$indent        relationPath: '${escape(relation)}',")
        ..writeln('$indent        resolvedAccounts: {');
      for (final candidate in leaves) {
        out.writeln(
          "$indent          if (${member(candidate.path)} != null) '${escape(candidate.wirePath)}': ${member(candidate.path)},",
        );
      }
      out
        ..writeln('$indent        },')
        ..writeln('$indent      );')
        ..writeln('$indent      if ($resolved != null) {')
        ..writeln('$indent        $local = $resolved;')
        ..writeln('$indent        progressed = true;')
        ..writeln('$indent      }')
        ..writeln('$indent    }');
    }
    out
      ..writeln('$indent  }')
      ..writeln('$indent}');
  }
}
