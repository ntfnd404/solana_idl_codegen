import '../idl.dart';
import 'discriminator_rule.dart';
import 'validation_issue.dart';

/// Validates top-level event declarations and their discriminator metadata.
final class EventDeclarationValidationRule {
  /// Creates an event declaration validation rule.
  const EventDeclarationValidationRule({
    this.discriminatorRule = const DiscriminatorValidationRule(),
  });

  /// Rule responsible for discriminator shape validation.
  final DiscriminatorValidationRule discriminatorRule;

  /// Validates event declarations against known type [definitions].
  void validate(
    IdlProgram program,
    Map<String, IdlTypeDefinition> definitions,
    ValidationIssue issue,
  ) {
    for (final event in program.events) {
      if (!definitions.containsKey(event.name)) {
        issue(
          'IDL_EVENT_TYPE_UNDEFINED',
          'Event type "${event.name}" is not defined.',
          event.sourcePath,
        );
      }
      final eventType = definitions[event.name];
      if (eventType != null &&
          (eventType.generics.isNotEmpty ||
              eventType.constGenerics.isNotEmpty)) {
        issue(
          'IDL_EVENT_GENERIC',
          'Event type "${event.name}" must be fully concrete.',
          event.sourcePath,
        );
      }
      discriminatorRule.validate(event.discriminator, event.sourcePath, issue);
    }
  }
}
