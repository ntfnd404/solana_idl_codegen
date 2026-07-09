import '../../idl.dart';

/// Normalizes named and tuple enum variant fields into named fields.
final class EnumFieldCollector {
  /// Creates a variant field collector.
  const EnumFieldCollector();

  /// Returns named fields for [variant], assigning `itemN` names to tuple fields.
  List<IdlField> collect(IdlEnumVariant variant) => variant.fields.isNotEmpty
      ? variant.fields
      : [
          for (var index = 0; index < variant.tupleFields.length; index++)
            IdlField('item${index + 1}', variant.tupleFields[index]),
        ];
}
