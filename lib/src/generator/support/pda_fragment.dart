import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';
import 'account_resolution_ports_fragment.dart';
import 'pda_derivation_fragment.dart';

/// Coordinates PDA derivation and account-resolution support fragments.
final class PdaSupportFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const PdaSupportFragment(super.context);

  @override
  List<Spec> emit() => <Spec>[
    ...PdaDerivationSupportFragment(context).emit(),
    ...AccountResolutionPortsSupportFragment(context).emit(),
  ];
}
