import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';
import 'account_meta_fragment.dart';
import 'address_fragment.dart';
import 'instruction_fragment.dart';

/// Coordinates transport-neutral wire value object fragments.
final class WireSupportFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const WireSupportFragment(super.context);

  @override
  List<Spec> emit() => <Spec>[
    ...AddressSupportFragment(context).emit(),
    ...AccountMetaSupportFragment(context).emit(),
    ...InstructionSupportFragment(context).emit(),
  ];
}
