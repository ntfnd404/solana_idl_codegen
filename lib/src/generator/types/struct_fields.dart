import '../../idl.dart';

/// Normalizes named and tuple struct fields into named fields.
final class StructFieldCollector {
  /// Creates a struct field collector.
  const StructFieldCollector();

  /// Returns named fields, assigning `itemN` names to tuple fields.
  List<IdlField> collect(
    List<IdlField> namedFields,
    List<IdlType> tupleFields,
  ) => namedFields.isNotEmpty
      ? namedFields
      : [
          for (var index = 0; index < tupleFields.length; index++)
            IdlField('item${index + 1}', tupleFields[index]),
        ];
}
