import 'package:code_builder/code_builder.dart';

import 'section_emitter.dart';
import 'support/account_transport_fragment.dart';
import 'support/borsh_fragment.dart';
import 'support/encoding_fragment.dart';
import 'support/event_simulation_fragment.dart';
import 'support/metadata_fragment.dart';
import 'support/pda_fragment.dart';
import 'support/wire_fragment.dart';

/// Coordinates the focused self-contained runtime support fragments.
final class SupportEmitter extends SectionEmitter {
  /// Creates a support emitter for [context].
  const SupportEmitter(super.context);

  /// Emits wire DTOs, Borsh runtime, ports, PDA, and encoding utilities.
  @override
  List<Spec> emit() => <Spec>[
    ...WireSupportFragment(context).emit(),
    ...MetadataSupportFragment(context).emit(),
    ...BorshSupportFragment(context).emit(),
    ...AccountTransportSupportFragment(context).emit(),
    ...EventSimulationSupportFragment(context).emit(),
    ...PdaSupportFragment(context).emit(),
    ...EncodingSupportFragment(context).emit(),
  ];
}
