import 'package:code_builder/code_builder.dart';

import 'client_facade_emitter.dart';
import 'instructions_client_emitter.dart';
import 'section_emitter.dart';
import 'view_client_emitter.dart';

/// Emits specialized generated clients and their optional facade.
final class ClientEmitter extends SectionEmitter {
  /// Creates a client emitter for [context].
  const ClientEmitter(super.context);

  /// Emits client declarations for the current program.
  @override
  List<Spec> emit() => List.unmodifiable([
    ...InstructionsClientEmitter(context).emit(),
    ...ViewClientEmitter(context).emit(),
    ...ClientFacadeEmitter(context).emit(),
  ]);
}
