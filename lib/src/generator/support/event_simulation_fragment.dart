import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';
import 'event_subscription_fragment.dart';
import 'simulation_fragment.dart';

/// Coordinates event-subscription and transaction-simulation support fragments.
final class EventSimulationSupportFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const EventSimulationSupportFragment(super.context);

  @override
  List<Spec> emit() => <Spec>[
    ...EventSubscriptionSupportFragment(context).emit(),
    ...SimulationSupportFragment(context).emit(),
  ];
}
