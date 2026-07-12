// GENERATED CODE - DO NOT MODIFY BY HAND.
// tool: solana_idl_codegen
// generator-version: 0.2.0
// source-sha256: 2865113b5e9095b7a15ecca890930530f1875b9cd72df2cd2c81ac066ae07d80
// semantic-ir-sha256: 5a434b479f377019592da21c1dd21985819054fa8f3ddcca8908f25645f95fef
// SPDX-License-Identifier: MIT
/// Generated event API for `example_program`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'example_program_solana_support.dart';
import 'example_program_solana_types.dart';

/// Base class for decoded program events.
sealed class ExampleProgramEvent {
  /// Creates a decoded event wrapper.
  const ExampleProgramEvent();
}

/// Decoded `MessageCreated` event.
final class ExampleProgramMessageCreatedEvent extends ExampleProgramEvent {
  /// Creates an event wrapper.
  const ExampleProgramMessageCreatedEvent(this.value);

  /// Typed event payload.
  final ExampleProgramMessageCreated value;

  /// IDL event discriminator.
  static final List<int> discriminator = List.unmodifiable(<int>[
    77,
    101,
    115,
    115,
    97,
    103,
    101,
    2,
  ]);
}

/// Context attached to every decoded event notification.
final class ExampleProgramEventContext {
  /// Creates event context.
  const ExampleProgramEventContext({
    required this.signature,
    required this.slot,
  });

  /// Transaction signature.
  final String signature;

  /// Context slot.
  final BigInt slot;
}

/// One typed event notification or recoverable log diagnostic.
sealed class ExampleProgramEventNotification {
  /// Creates a notification.
  const ExampleProgramEventNotification();
}

/// Successfully decoded event notification.
final class ExampleProgramDecodedEventNotification
    extends ExampleProgramEventNotification {
  /// Creates a decoded notification.
  const ExampleProgramDecodedEventNotification({
    required this.event,
    required this.context,
  });

  /// Typed event.
  final ExampleProgramEvent event;

  /// Transaction context.
  final ExampleProgramEventContext context;
}

/// Recoverable malformed or truncated log notification.
final class ExampleProgramEventDiagnosticNotification
    extends ExampleProgramEventNotification {
  /// Creates a diagnostic notification.
  const ExampleProgramEventDiagnosticNotification({
    required this.code,
    required this.message,
  });

  /// Stable diagnostic code.
  final String code;

  /// Human-readable diagnostic.
  final String message;
}

/// Closeable typed event subscription.
final class ExampleProgramTypedEventSubscription {
  /// Creates a typed wrapper around a raw subscription.
  ExampleProgramTypedEventSubscription._(this._raw, this.notifications);

  final ExampleProgramEventSubscription _raw;

  bool _closed = false;

  /// Typed events and recoverable malformed-log diagnostics.
  final Stream<ExampleProgramEventNotification> notifications;

  /// Closes the raw subscription exactly once.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _raw.close();
  }
}

/// Typed event subscription client with invocation-stack parsing.
final class ExampleProgramEventsClient {
  /// Creates an event client.
  const ExampleProgramEventsClient(this.subscriber);

  /// Raw log subscription capability.
  final ExampleProgramEventSubscriber subscriber;

  /// Subscribes and decodes events without closing on malformed logs.
  Future<ExampleProgramTypedEventSubscription> subscribe() async {
    final subscription = await subscriber.subscribe(
      ExampleProgramProgram.programAddress,
    );
    return ExampleProgramTypedEventSubscription._(
      subscription,
      subscription.batches.asyncExpand(_decodeBatch),
    );
  }

  Stream<ExampleProgramEventNotification> _decodeBatch(
    ExampleProgramLogBatch batch,
  ) async* {
    final target = ExampleProgramProgram.address;
    final stack = <String>[];
    for (final line in batch.logs) {
      final invoke = RegExp(
        r'^Program ([1-9A-HJ-NP-Za-km-z]+) invoke',
      ).firstMatch(line);
      if (invoke != null) {
        stack.add(invoke.group(1)!);
        continue;
      }
      final exit = RegExp(
        r'^Program ([1-9A-HJ-NP-Za-km-z]+) (success|failed)',
      ).firstMatch(line);
      if (exit != null) {
        if (stack.isEmpty || stack.last != exit.group(1)) {
          yield const ExampleProgramEventDiagnosticNotification(
            code: 'EVENT_STACK_MISMATCH',
            message: 'Program invocation stack is malformed.',
          );
        } else {
          stack.removeLast();
        }
        continue;
      }
      if (!line.startsWith('Program data: ') ||
          stack.isEmpty ||
          stack.last != target) {
        continue;
      }
      Uint8List payload;
      try {
        payload = base64Decode(line.substring(14));
      } on FormatException {
        yield const ExampleProgramEventDiagnosticNotification(
          code: 'EVENT_BASE64',
          message: 'Event payload is not valid Base64.',
        );
        continue;
      }
      final decoded = _decode(payload);
      if (decoded == null) {
        yield const ExampleProgramEventDiagnosticNotification(
          code: 'EVENT_DISCRIMINATOR',
          message: 'Unknown or truncated event discriminator.',
        );
      } else {
        yield ExampleProgramDecodedEventNotification(
          event: decoded,
          context: ExampleProgramEventContext(
            signature: batch.signature,
            slot: batch.slot,
          ),
        );
      }
    }
  }

  ExampleProgramEvent? _decode(Uint8List data) {
    if (_startsWith(data, ExampleProgramMessageCreatedEvent.discriminator)) {
      return ExampleProgramMessageCreatedEvent(
        ExampleProgramMessageCreated.codec.decodeExact(
          data.sublist(ExampleProgramMessageCreatedEvent.discriminator.length),
        ),
      );
    }
    return null;
  }

  bool _startsWith(List<int> data, List<int> prefix) {
    if (data.length < prefix.length) {
      return false;
    }
    for (var index = 0; index < prefix.length; index++) {
      if (data[index] != prefix[index]) {
        return false;
      }
    }
    return true;
  }
}
