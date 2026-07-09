import 'package:code_builder/code_builder.dart';

import 'section_emitter.dart';
import 'types/declarations_fragment.dart';

/// Coordinates focused generated type declaration fragments.
final class TypesEmitter extends SectionEmitter {
  /// Creates a type emitter for [context].
  const TypesEmitter(super.context);

  /// Emits model, enum, codec, metadata, and constant declarations.
  @override
  List<Spec> emit() => TypeDeclarationsFragment(context).emit();
}
