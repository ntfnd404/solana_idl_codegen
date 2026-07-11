// GENERATED CODE - DO NOT MODIFY BY HAND.
// tool: solana_idl_codegen
// generator-version: 0.1.0
// source-sha256: bfba19c124c33b827b5c139cc62b583f9c36aafb5951f72e02387a67705816a7
// semantic-ir-sha256: 116502c850c55b1b16510193442452e33c2161adb8e40f36a00d8c66826e6b0a
// SPDX-License-Identifier: MIT
// ignore_for_file: prefer_initializing_formals, unused_element, unused_import, use_super_parameters

/// Generated event API for `secondary_program`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'secondary_program_solana_support.dart';
import 'secondary_program_solana_types.dart';

/// Base class for decoded program events.
sealed class SecondaryProgramEvent {
  /// Creates a decoded event wrapper.
  const SecondaryProgramEvent();
}

/// Context attached to every decoded event notification.
final class SecondaryProgramEventContext {
  /// Creates event context.
  const SecondaryProgramEventContext({
    required this.signature,
    required this.slot,
  });

  /// Transaction signature.
  final String signature;

  /// Context slot.
  final BigInt slot;
}

/// One typed event notification or recoverable log diagnostic.
sealed class SecondaryProgramEventNotification {
  /// Creates a notification.
  const SecondaryProgramEventNotification();
}

/// Successfully decoded event notification.
final class SecondaryProgramDecodedEventNotification
    extends SecondaryProgramEventNotification {
  /// Creates a decoded notification.
  const SecondaryProgramDecodedEventNotification({
    required this.event,
    required this.context,
  });

  /// Typed event.
  final SecondaryProgramEvent event;

  /// Transaction context.
  final SecondaryProgramEventContext context;
}

/// Recoverable malformed or truncated log notification.
final class SecondaryProgramEventDiagnosticNotification
    extends SecondaryProgramEventNotification {
  /// Creates a diagnostic notification.
  const SecondaryProgramEventDiagnosticNotification({
    required this.code,
    required this.message,
  });

  /// Stable diagnostic code.
  final String code;

  /// Human-readable diagnostic.
  final String message;
}

/// Closeable typed event subscription.
final class SecondaryProgramTypedEventSubscription {
  /// Creates a typed wrapper around a raw subscription.
  SecondaryProgramTypedEventSubscription._(this._raw, this.notifications);

  final SecondaryProgramEventSubscription _raw;

  bool _closed = false;

  /// Typed events and recoverable malformed-log diagnostics.
  final Stream<SecondaryProgramEventNotification> notifications;

  /// Closes the raw subscription exactly once.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _raw.close();
  }
}

/// Typed event subscription client with invocation-stack parsing.
final class SecondaryProgramEventsClient {
  /// Creates an event client.
  const SecondaryProgramEventsClient(this.subscriber);

  /// Raw log subscription capability.
  final SecondaryProgramEventSubscriber subscriber;

  /// Subscribes and decodes events without closing on malformed logs.
  Future<SecondaryProgramTypedEventSubscription> subscribe() async {
    final subscription = await subscriber.subscribe(
      SecondaryProgramProgram.programAddress,
    );
    return SecondaryProgramTypedEventSubscription._(
      subscription,
      subscription.batches.asyncExpand(_decodeBatch),
    );
  }

  Stream<SecondaryProgramEventNotification> _decodeBatch(
    SecondaryProgramLogBatch batch,
  ) async* {
    final target = SecondaryProgramProgram.address;
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
          yield const SecondaryProgramEventDiagnosticNotification(
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
        yield const SecondaryProgramEventDiagnosticNotification(
          code: 'EVENT_BASE64',
          message: 'Event payload is not valid Base64.',
        );
        continue;
      }
      final decoded = _decode(payload);
      if (decoded == null) {
        yield const SecondaryProgramEventDiagnosticNotification(
          code: 'EVENT_DISCRIMINATOR',
          message: 'Unknown or truncated event discriminator.',
        );
      } else {
        yield SecondaryProgramDecodedEventNotification(
          event: decoded,
          context: SecondaryProgramEventContext(
            signature: batch.signature,
            slot: batch.slot,
          ),
        );
      }
    }
  }

  SecondaryProgramEvent? _decode(Uint8List data) {
    return null;
  }

  bool _startsWith(List<int> data, List<int> prefix) {
    if (data.length < prefix.length) return false;
    for (var index = 0; index < prefix.length; index++) {
      if (data[index] != prefix[index]) return false;
    }
    return true;
  }
}
