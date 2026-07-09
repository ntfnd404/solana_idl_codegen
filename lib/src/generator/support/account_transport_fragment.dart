import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';
import 'account_transport/failures_fragment.dart';
import 'account_transport/ports_fragment.dart';
import 'account_transport/values_fragment.dart';

/// Coordinates account-transport support fragments.
final class AccountTransportSupportFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const AccountTransportSupportFragment(super.context);

  @override
  List<Spec> emit() => <Spec>[
    ...TransportFailuresFragment(context).emit(),
    ...AccountTransportValuesFragment(context).emit(),
    ...AccountTransportPortsFragment(context).emit(),
  ];
}
