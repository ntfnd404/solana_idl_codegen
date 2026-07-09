import 'package:code_builder/code_builder.dart';

import 'event_client_emitter.dart';
import 'event_model_emitter.dart';
import 'section_emitter.dart';

/// Emits typed events, invocation parsing, and subscription clients.
final class EventsEmitter extends SectionEmitter {
  /// Creates an event emitter for [context].
  const EventsEmitter(super.context);

  /// Emits event-related declarations for the current program.
  @override
  List<Spec> emit() => List.unmodifiable([
    ...EventModelEmitter(context).emit(),
    ...EventClientEmitter(context).emit(),
  ]);
}
