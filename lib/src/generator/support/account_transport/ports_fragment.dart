import 'package:code_builder/code_builder.dart';

import '../../section_emitter.dart';
import 'reader_ports_fragment.dart';
import 'scanner_ports_fragment.dart';

/// Coordinates account reader/scanner ports and callback adapters.
final class AccountTransportPortsFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const AccountTransportPortsFragment(super.context);

  @override
  List<Spec> emit() => <Spec>[
    ...AccountReaderPortsFragment(context).emit(),
    ...AccountScannerPortsFragment(context).emit(),
  ];
}
