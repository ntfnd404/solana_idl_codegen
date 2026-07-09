import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';
import 'context_support_fragment.dart';
import 'failure_support_fragment.dart';
import 'override_support_fragment.dart';

/// Coordinates shared account-resolution support declarations.
final class ResolutionSupportFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const ResolutionSupportFragment(super.context);

  @override
  List<Spec> emit() => <Spec>[
    ...OverrideSupportFragment(context).emit(),
    ...ContextSupportFragment(context).emit(),
    ...FailureSupportFragment(context).emit(),
  ];
}
