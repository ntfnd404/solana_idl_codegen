import 'package:code_builder/code_builder.dart';

import 'resolution/instruction_resolver_fragment.dart';
import 'resolution/support_fragment.dart';
import 'section_emitter.dart';

/// Coordinates shared and per-instruction account-resolution fragments.
final class ResolutionEmitter extends SectionEmitter {
  /// Creates a resolution emitter for [context].
  const ResolutionEmitter(super.context);

  /// Emits resolution support followed by instruction-specific resolvers.
  @override
  List<Spec> emit() => <Spec>[
    ...ResolutionSupportFragment(context).emit(),
    ...InstructionResolverFragment(context).emit(),
  ];
}
