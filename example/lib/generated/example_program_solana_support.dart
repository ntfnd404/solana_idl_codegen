// GENERATED CODE - DO NOT MODIFY BY HAND.
// tool: solana_idl_codegen
// generator-version: 0.1.0
// source-sha256: 2865113b5e9095b7a15ecca890930530f1875b9cd72df2cd2c81ac066ae07d80
// semantic-ir-sha256: 5a434b479f377019592da21c1dd21985819054fa8f3ddcca8908f25645f95fef
// SPDX-License-Identifier: MIT
/// Generated runtime support for `example_program`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

/// Immutable 32-byte Solana address used by the generated SDK.
final class ExampleProgramAddress {
  ExampleProgramAddress._(Uint8List bytes) : _bytes = Uint8List.fromList(bytes);

  /// Creates an address from exactly 32 bytes.
  factory ExampleProgramAddress.fromBytes(List<int> bytes) {
    if (bytes.length != 32) {
      throw ArgumentError.value(bytes.length, 'bytes', 'Expected 32 bytes.');
    }
    for (final byte in bytes) {
      if (byte < 0 || byte > 255) {
        throw ArgumentError.value(byte, 'bytes', 'Expected byte values.');
      }
    }
    return ExampleProgramAddress._(Uint8List.fromList(bytes));
  }

  /// Decodes a canonical Base58 address.
  factory ExampleProgramAddress.fromBase58(String value) {
    final decoded = _programDecodeBase58(value);
    if (decoded.length != 32) {
      throw FormatException('Address must decode to exactly 32 bytes.');
    }
    final address = ExampleProgramAddress.fromBytes(decoded);
    if (address.toBase58() != value) {
      throw FormatException('Address is not canonical Base58.');
    }
    return address;
  }

  final Uint8List _bytes;

  /// Returns an unmodifiable defensive copy of the address bytes.
  Uint8List get bytes => Uint8List.fromList(_bytes).asUnmodifiableView();

  /// Encodes this address as Base58.
  String toBase58() => _programEncodeBase58(_bytes);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExampleProgramAddress &&
          _programBytesEqual(_bytes, other._bytes);

  @override
  int get hashCode => Object.hashAll(_bytes);

  @override
  String toString() => toBase58();
}

/// Immutable account metadata for one instruction account position.
final class ExampleProgramAccountMeta {
  /// Creates account metadata.
  const ExampleProgramAccountMeta({
    required this.address,
    required this.isSigner,
    required this.isWritable,
  });

  /// Account address.
  final ExampleProgramAddress address;

  /// Whether the transaction requires this account to sign.
  final bool isSigner;

  /// Whether the instruction may write this account.
  final bool isWritable;
}

/// Immutable transport-neutral Solana instruction.
final class ExampleProgramInstruction {
  /// Creates an instruction and defensively copies collections.
  ExampleProgramInstruction({
    required this.programAddress,
    required List<ExampleProgramAccountMeta> accounts,
    required List<int> data,
  }) : accounts = List.unmodifiable(accounts),
       data = Uint8List.fromList(data).asUnmodifiableView();

  /// Program invoked by this instruction.
  final ExampleProgramAddress programAddress;

  /// Ordered account metadata. Duplicate positions are preserved.
  final List<ExampleProgramAccountMeta> accounts;

  /// Immutable serialized instruction data.
  final Uint8List data;

  /// Returns a structural wire record for cross-program composition.
  ({
    Uint8List programAddress,
    List<({Uint8List address, bool isSigner, bool isWritable})> accounts,
    Uint8List data,
  })
  toWire() => (
    programAddress: programAddress.bytes,
    accounts: List.unmodifiable(
      accounts.map(
        (item) => (
          address: item.address.bytes,
          isSigner: item.isSigner,
          isWritable: item.isWritable,
        ),
      ),
    ),
    data: Uint8List.fromList(data).asUnmodifiableView(),
  );
}

/// Immutable metadata for one generated account decoder.
final class ExampleProgramAccountMetadata {
  /// Creates account metadata and copies byte lists.
  ExampleProgramAccountMetadata({
    required this.name,
    required List<int> discriminator,
  }) : discriminator = List.unmodifiable(discriminator);

  /// IDL account name.
  final String name;

  /// Account discriminator bytes.
  final List<int> discriminator;

  /// Number of discriminator bytes.
  int get discriminatorLength => discriminator.length;
}

/// Immutable metadata for one instruction account position.
final class ExampleProgramInstructionAccountMetadata {
  /// Creates instruction account metadata.
  const ExampleProgramInstructionAccountMetadata({
    required this.name,
    required this.path,
    required this.isSigner,
    required this.isWritable,
    required this.isOptional,
  });

  /// Leaf account name from the IDL.
  final String name;

  /// Dot-separated account path from the IDL.
  final String path;

  /// Whether this account signs.
  final bool isSigner;

  /// Whether this account is writable.
  final bool isWritable;

  /// Whether this account is optional.
  final bool isOptional;
}

/// Immutable metadata for one generated instruction.
final class ExampleProgramInstructionMetadata {
  /// Creates instruction metadata and copies collections.
  ExampleProgramInstructionMetadata({
    required this.name,
    required List<int> discriminator,
    required List<ExampleProgramInstructionAccountMetadata> accounts,
  }) : discriminator = List.unmodifiable(discriminator),
       accounts = List.unmodifiable(accounts);

  /// IDL instruction name.
  final String name;

  /// Instruction discriminator bytes.
  final List<int> discriminator;

  /// Ordered account metadata. Duplicate positions are preserved.
  final List<ExampleProgramInstructionAccountMetadata> accounts;

  /// Number of discriminator bytes.
  int get discriminatorLength => discriminator.length;
}

/// Resource limits applied by every public Borsh decoder.
final class ExampleProgramDecodeLimits {
  /// Creates explicit decoder limits.
  const ExampleProgramDecodeLimits({
    required this.maxInputBytes,
    required this.maxStringBytes,
    required this.maxCollectionLength,
    required this.maxTotalElements,
    required this.maxNestingDepth,
  });

  /// Recommended limits for untrusted account and event data.
  static const defaults = ExampleProgramDecodeLimits(
    maxInputBytes: 16 * 1024 * 1024,
    maxStringBytes: 4 * 1024 * 1024,
    maxCollectionLength: 1000000,
    maxTotalElements: 2000000,
    maxNestingDepth: 128,
  );

  /// Maximum input bytes.
  final int maxInputBytes;

  /// Maximum UTF-8 string bytes.
  final int maxStringBytes;

  /// Maximum elements in one collection.
  final int maxCollectionLength;

  /// Maximum total decoded collection elements.
  final int maxTotalElements;

  /// Maximum nested codec depth.
  final int maxNestingDepth;
}

/// Canonical floating-point construction rules used by generated models.
abstract final class ExampleProgramFloatSemantics {
  /// Rejects NaN and rounds [value] to its IEEE-754 f32 representation.
  static double f32(double value) {
    if (value.isNaN) {
      throw ArgumentError.value(value, 'value', 'NaN is not canonical Borsh.');
    }
    final bytes = Uint8List(4);
    final data = ByteData.sublistView(bytes)
      ..setFloat32(0, value, Endian.little);
    return data.getFloat32(0, Endian.little);
  }

  /// Rejects NaN and returns an f64 value unchanged.
  static double f64(double value) {
    if (value.isNaN) {
      throw ArgumentError.value(value, 'value', 'NaN is not canonical Borsh.');
    }
    return value;
  }
}

/// Borsh failure with byte offset and logical field path.
final class ExampleProgramBorshException implements Exception {
  /// Creates a structured Borsh failure.
  const ExampleProgramBorshException({
    required this.code,
    required this.message,
    required this.offset,
    required this.path,
    this.expected,
    this.actual,
    this.cause,
  });

  /// Stable failure code.
  final String code;

  /// Human-readable failure message.
  final String message;

  /// Byte offset at which decoding failed.
  final int offset;

  /// Logical field path.
  final String path;

  /// Optional expected value description.
  final String? expected;

  /// Optional actual value description.
  final String? actual;

  /// Sanitized underlying failure description.
  final String? cause;

  @override
  String toString() =>
      'ExampleProgramBorshException($code at $path+$offset: $message)';
}

/// Mutable, bounds-checked Borsh reader scoped to one decode operation.
final class ExampleProgramBorshReader {
  /// Creates a reader over a defensive copy of [input].
  ExampleProgramBorshReader(
    List<int> input, {
    this.limits = ExampleProgramDecodeLimits.defaults,
  }) : _bytes = Uint8List.fromList(input) {
    if (limits.maxInputBytes < 0 ||
        limits.maxStringBytes < 0 ||
        limits.maxCollectionLength < 0 ||
        limits.maxTotalElements < 0 ||
        limits.maxNestingDepth < 0) {
      throw ArgumentError.value(
        limits,
        'limits',
        'Decode limits must be non-negative.',
      );
    }
    if (_bytes.length > limits.maxInputBytes) {
      throw ExampleProgramBorshException(
        code: 'BORSH_INPUT_LIMIT',
        message: 'Input exceeds maxInputBytes.',
        offset: 0,
        path: r'$',
        expected: '<= ${limits.maxInputBytes}',
        actual: '${_bytes.length}',
      );
    }
  }

  final Uint8List _bytes;

  /// Limits used by this decode operation.
  final ExampleProgramDecodeLimits limits;

  var _offset = 0;

  var _totalElements = 0;

  var _depth = 0;

  var _path = r'$';

  /// Current byte offset.
  int get offset => _offset;

  /// Remaining unread byte count.
  int get remaining => _bytes.length - _offset;

  /// Executes [callback] with [name] appended to the logical field path.
  T field<T>(String name, T Function() callback) {
    final previous = _path;
    _path = '$previous.$name';
    try {
      return callback();
    } finally {
      _path = previous;
    }
  }

  /// Executes [callback] with [index] appended to the logical collection path.
  T index<T>(int index, T Function() callback) {
    final previous = _path;
    _path = '$previous[$index]';
    try {
      return callback();
    } finally {
      _path = previous;
    }
  }

  /// Executes a nested decode while enforcing maxNestingDepth.
  T nested<T>(T Function() callback, {String? path}) {
    _depth++;
    if (_depth > limits.maxNestingDepth) {
      _depth--;
      throw ExampleProgramBorshException(
        code: 'BORSH_NESTING_LIMIT',
        message: 'Value exceeds maxNestingDepth.',
        offset: _offset,
        path: path ?? _path,
      );
    }
    try {
      return callback();
    } finally {
      _depth--;
    }
  }

  /// Reads exactly [length] bytes.
  Uint8List readBytes(int length, {String? path}) {
    final logicalPath = path ?? _path;
    if (length < 0 || length > remaining) {
      throw ExampleProgramBorshException(
        code: 'BORSH_UNEXPECTED_EOF',
        message: 'Not enough bytes.',
        offset: _offset,
        path: logicalPath,
        expected: '$length bytes',
        actual: '$remaining bytes',
      );
    }
    final result = Uint8List.fromList(
      _bytes.sublist(_offset, _offset + length),
    );
    _offset += length;
    return result.asUnmodifiableView();
  }

  /// Reads an unsigned little-endian integer.
  BigInt readUnsigned(int byteLength, {String? path}) {
    final value = readBytes(byteLength, path: path);
    var result = BigInt.zero;
    for (var index = value.length - 1; index >= 0; index--) {
      result = (result << 8) | BigInt.from(value[index]);
    }
    return result;
  }

  /// Reads a signed two's-complement little-endian integer.
  BigInt readSigned(int byteLength, {String? path}) {
    final unsigned = readUnsigned(byteLength, path: path);
    final bits = byteLength * 8;
    final sign = BigInt.one << (bits - 1);
    return (unsigned & sign) == BigInt.zero
        ? unsigned
        : unsigned - (BigInt.one << bits);
  }

  /// Reads an unsigned integer that must fit a Dart [int].
  int readInt(int byteLength, {String? path}) =>
      readUnsigned(byteLength, path: path).toInt();

  /// Reads a strict Borsh boolean.
  bool readBool({String? path}) {
    final logicalPath = path ?? _path;
    final tag = readInt(1, path: path);
    return switch (tag) {
      0 => false,
      1 => true,
      _ => throw ExampleProgramBorshException(
        code: 'BORSH_INVALID_BOOL',
        message: 'Boolean tag must be 0 or 1.',
        offset: _offset - 1,
        path: logicalPath,
        expected: '0 or 1',
        actual: '$tag',
      ),
    };
  }

  /// Reads a strict Option or COption tag.
  bool readOptionTag(int byteLength, {String? path}) {
    final logicalPath = path ?? _path;
    final tag = readInt(byteLength, path: path);
    return switch (tag) {
      0 => false,
      1 => true,
      _ => throw ExampleProgramBorshException(
        code: 'BORSH_INVALID_OPTION',
        message: 'Option tag must be 0 or 1.',
        offset: _offset - byteLength,
        path: logicalPath,
        expected: '0 or 1',
        actual: '$tag',
      ),
    };
  }

  /// Reads an IEEE-754 floating-point value.
  double readFloat(int byteLength, {String? path}) {
    final logicalPath = path ?? _path;
    final bytes = readBytes(byteLength, path: path);
    final data = ByteData.sublistView(bytes);
    final value = byteLength == 4
        ? data.getFloat32(0, Endian.little)
        : data.getFloat64(0, Endian.little);
    if (value.isNaN) {
      throw ExampleProgramBorshException(
        code: 'BORSH_NAN',
        message: 'NaN is not a canonical Borsh value.',
        offset: _offset - byteLength,
        path: logicalPath,
      );
    }
    return value;
  }

  /// Reads a strict UTF-8 Borsh string.
  String readString({String? path}) {
    final logicalPath = path ?? _path;
    final length = readInt(4, path: path);
    if (length > limits.maxStringBytes) {
      throw ExampleProgramBorshException(
        code: 'BORSH_STRING_LIMIT',
        message: 'String exceeds maxStringBytes.',
        offset: _offset - 4,
        path: logicalPath,
      );
    }
    try {
      return utf8.decode(readBytes(length, path: path), allowMalformed: false);
    } on FormatException catch (error) {
      throw ExampleProgramBorshException(
        code: 'BORSH_INVALID_UTF8',
        message: 'String is not valid UTF-8.',
        offset: _offset - length,
        path: logicalPath,
        cause: error.message,
      );
    }
  }

  /// Validates a collection length before allocation.
  int collectionLength({String? path}) {
    final length = readInt(4, path: path);
    return fixedLength(length, path: path);
  }

  /// Validates a fixed or already-decoded collection length.
  int fixedLength(int length, {String? path}) {
    if (length < 0 ||
        length > limits.maxCollectionLength ||
        _totalElements + length > limits.maxTotalElements) {
      throw ExampleProgramBorshException(
        code: 'BORSH_COLLECTION_LIMIT',
        message: 'Collection exceeds configured decode limits.',
        offset: _offset,
        path: path ?? _path,
      );
    }
    _totalElements += length;
    return length;
  }
}

/// Mutable Borsh writer scoped to one encode operation.
final class ExampleProgramBorshWriter {
  final BytesBuilder _builder = BytesBuilder(copy: false);

  /// Writes raw bytes after validating byte values.
  void writeBytes(List<int> bytes) {
    for (final byte in bytes) {
      if (byte < 0 || byte > 255) {
        throw RangeError.range(byte, 0, 255, 'bytes');
      }
    }
    _builder.add(bytes);
  }

  /// Writes an unsigned little-endian integer with overflow checking.
  void writeUnsigned(BigInt value, int byteLength) {
    final maximum = BigInt.one << (byteLength * 8);
    if (value < BigInt.zero || value >= maximum) {
      throw ArgumentError.value(value, 'value', 'Unsigned integer overflow.');
    }
    var remaining = value;
    for (var index = 0; index < byteLength; index++) {
      _builder.addByte((remaining & BigInt.from(255)).toInt());
      remaining >>= 8;
    }
  }

  /// Writes a signed two's-complement little-endian integer.
  void writeSigned(BigInt value, int byteLength) {
    final bits = byteLength * 8;
    final minimum = -(BigInt.one << (bits - 1));
    final maximum = (BigInt.one << (bits - 1)) - BigInt.one;
    if (value < minimum || value > maximum) {
      throw ArgumentError.value(value, 'value', 'Signed integer overflow.');
    }
    writeUnsigned(
      value < BigInt.zero ? (BigInt.one << bits) + value : value,
      byteLength,
    );
  }

  /// Writes a strict Borsh boolean.
  void writeBool(bool value) => _builder.addByte(value ? 1 : 0);

  /// Writes an IEEE-754 floating-point value and rejects NaN.
  void writeFloat(double value, int byteLength) {
    if (value.isNaN) {
      throw ArgumentError.value(value, 'value', 'NaN is not canonical Borsh.');
    }
    final bytes = Uint8List(byteLength);
    final data = ByteData.sublistView(bytes);
    if (byteLength == 4) {
      data.setFloat32(0, value, Endian.little);
    } else {
      data.setFloat64(0, value, Endian.little);
    }
    _builder.add(bytes);
  }

  /// Writes a length-prefixed UTF-8 string.
  void writeString(String value) {
    final bytes = utf8.encode(value);
    writeUnsigned(BigInt.from(bytes.length), 4);
    writeBytes(bytes);
  }

  /// Returns an immutable copy of encoded bytes.
  Uint8List takeBytes() =>
      Uint8List.fromList(_builder.takeBytes()).asUnmodifiableView();
}

/// Base class for deterministic Borsh codecs.
abstract base class ExampleProgramBorshCodec<T> {
  /// Creates a codec.
  const ExampleProgramBorshCodec();

  /// Reads one value from [reader].
  T read(ExampleProgramBorshReader reader);

  /// Writes one [value] to [writer].
  void write(ExampleProgramBorshWriter writer, T value);

  /// Encodes [value] into an immutable byte array.
  Uint8List encode(T value) {
    final writer = ExampleProgramBorshWriter();
    write(writer, value);
    return writer.takeBytes();
  }

  /// Decodes one value and requires complete input consumption.
  T decodeExact(
    List<int> input, {
    ExampleProgramDecodeLimits limits = ExampleProgramDecodeLimits.defaults,
  }) {
    final result = decodePrefix(input, limits: limits);
    if (result.consumed != input.length) {
      throw ExampleProgramBorshException(
        code: 'BORSH_TRAILING_BYTES',
        message: 'Input contains trailing bytes.',
        offset: result.consumed,
        path: r'$',
        expected: '${result.consumed} bytes',
        actual: '${input.length} bytes',
      );
    }
    return result.value;
  }

  /// Decodes one value and returns its consumed byte count.
  ({T value, int consumed}) decodePrefix(
    List<int> input, {
    ExampleProgramDecodeLimits limits = ExampleProgramDecodeLimits.defaults,
  }) {
    final reader = ExampleProgramBorshReader(input, limits: limits);
    return (value: read(reader), consumed: reader.offset);
  }
}

/// Codec assembled from injected read and write functions.
final class ExampleProgramFunctionalBorshCodec<T>
    extends ExampleProgramBorshCodec<T> {
  /// Creates a codec from [reader] and [writer].
  const ExampleProgramFunctionalBorshCodec(this.reader, this.writer);

  /// Function that reads one value.
  final T Function(ExampleProgramBorshReader reader) reader;

  /// Function that writes one value.
  final void Function(ExampleProgramBorshWriter writer, T value) writer;

  @override
  T read(ExampleProgramBorshReader reader) => this.reader(reader);

  @override
  void write(ExampleProgramBorshWriter writer, T value) =>
      this.writer(writer, value);
}

/// Neutral transaction failure supplied by an application adapter.
final class ExampleProgramTransactionFailure {
  /// Creates a failure.
  const ExampleProgramTransactionFailure({
    required this.code,
    required this.message,
  });

  /// Adapter-defined stable code.
  final String code;

  /// Human-readable failure message.
  final String message;
}

/// Typed account read, ownership, decoding, or capability failure.
final class ExampleProgramAccountException implements Exception {
  /// Creates a failure with a stable machine-readable [code].
  const ExampleProgramAccountException({
    required this.code,
    required this.message,
  });

  /// Stable generated SDK error code.
  final String code;

  /// Human-readable failure description.
  final String message;

  @override
  String toString() => 'ExampleProgramAccountException($code: $message)';
}

/// Typed view simulation or return-data failure.
final class ExampleProgramViewException implements Exception {
  /// Creates a failure with a stable machine-readable [code].
  const ExampleProgramViewException({
    required this.code,
    required this.message,
  });

  /// Stable generated SDK error code.
  final String code;

  /// Human-readable failure description.
  final String message;

  @override
  String toString() => 'ExampleProgramViewException($code: $message)';
}

/// Immutable account state returned by an application adapter.
final class ExampleProgramAccountSnapshot {
  /// Creates an account snapshot and copies [data].
  ExampleProgramAccountSnapshot({
    required this.address,
    required this.owner,
    required List<int> data,
    required this.lamports,
    required this.executable,
    required this.rentEpoch,
    required this.slot,
  }) : data = Uint8List.fromList(data).asUnmodifiableView();

  /// Account address.
  final ExampleProgramAddress address;

  /// Owning program address.
  final ExampleProgramAddress owner;

  /// Immutable account data.
  final Uint8List data;

  /// Account balance.
  final BigInt lamports;

  /// Whether the account contains executable code.
  final bool executable;

  /// Rent epoch reported by the transport.
  final BigInt rentEpoch;

  /// Context slot.
  final BigInt slot;
}

/// Commitment used by generated account reads.
enum ExampleProgramCommitment {
  /// Processed commitment.
  processed,

  /// Confirmed commitment.
  confirmed,

  /// Finalized commitment.
  finalized,
}

/// Transport-neutral account read options.
final class ExampleProgramAccountReadOptions {
  /// Creates account read options.
  const ExampleProgramAccountReadOptions({
    this.commitment = ExampleProgramCommitment.confirmed,
    this.minContextSlot,
  });

  /// Requested commitment.
  final ExampleProgramCommitment commitment;

  /// Optional minimum context slot.
  final BigInt? minContextSlot;
}

/// Base class for transport-neutral account scanner filters.
sealed class ExampleProgramAccountFilter {
  /// Creates an account scanner filter.
  const ExampleProgramAccountFilter();
}

/// Immutable memcmp scanner filter.
final class ExampleProgramMemcmpFilter extends ExampleProgramAccountFilter {
  /// Creates a memcmp filter and copies [bytes].
  ExampleProgramMemcmpFilter({required this.offset, required List<int> bytes})
    : bytes = Uint8List.fromList(bytes).asUnmodifiableView() {
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset');
    }
  }

  /// Byte offset.
  final int offset;

  /// Bytes to compare.
  final Uint8List bytes;
}

/// Immutable account data-size scanner filter.
final class ExampleProgramDataSizeFilter extends ExampleProgramAccountFilter {
  /// Creates a data-size filter.
  const ExampleProgramDataSizeFilter(this.size) : assert(size >= 0);

  /// Required byte length.
  final int size;
}

/// Port used by generated account clients to read addresses.
abstract interface class ExampleProgramAccountReader {
  /// Reads one account or returns `null` when it does not exist.
  Future<ExampleProgramAccountSnapshot?> readAccount(
    ExampleProgramAddress address, {
    ExampleProgramAccountReadOptions options =
        const ExampleProgramAccountReadOptions(),
  });

  /// Reads accounts while preserving input order and missing positions.
  Future<List<ExampleProgramAccountSnapshot?>> readAccounts(
    List<ExampleProgramAddress> addresses, {
    ExampleProgramAccountReadOptions options =
        const ExampleProgramAccountReadOptions(),
  });
}

/// Callback adapter for [ExampleProgramAccountReader].
final class ExampleProgramAccountReaderCallback
    implements ExampleProgramAccountReader {
  /// Creates an adapter from callbacks.
  const ExampleProgramAccountReaderCallback({
    required this.readOne,
    required this.readMany,
  });

  /// Single-account callback.
  final Future<ExampleProgramAccountSnapshot?> Function(
    ExampleProgramAddress,
    ExampleProgramAccountReadOptions,
  )
  readOne;

  /// Multi-account callback.
  final Future<List<ExampleProgramAccountSnapshot?>> Function(
    List<ExampleProgramAddress>,
    ExampleProgramAccountReadOptions,
  )
  readMany;

  @override
  Future<ExampleProgramAccountSnapshot?> readAccount(
    ExampleProgramAddress address, {
    ExampleProgramAccountReadOptions options =
        const ExampleProgramAccountReadOptions(),
  }) => readOne(address, options);

  @override
  Future<List<ExampleProgramAccountSnapshot?>> readAccounts(
    List<ExampleProgramAddress> addresses, {
    ExampleProgramAccountReadOptions options =
        const ExampleProgramAccountReadOptions(),
  }) async =>
      List.unmodifiable(await readMany(List.unmodifiable(addresses), options));
}

/// Port used to scan program-owned accounts.
abstract interface class ExampleProgramAccountScanner {
  /// Scans accounts using ordered transport-neutral [filters].
  Future<List<ExampleProgramAccountSnapshot>> scanAccounts(
    ExampleProgramAddress programAddress, {
    List<ExampleProgramAccountFilter> filters = const [],
    ExampleProgramAccountReadOptions options =
        const ExampleProgramAccountReadOptions(),
  });
}

/// Callback adapter for [ExampleProgramAccountScanner].
final class ExampleProgramAccountScannerCallback
    implements ExampleProgramAccountScanner {
  /// Creates an adapter from [callback].
  const ExampleProgramAccountScannerCallback(this.callback);

  /// Scanner callback.
  final Future<List<ExampleProgramAccountSnapshot>> Function(
    ExampleProgramAddress,
    List<ExampleProgramAccountFilter>,
    ExampleProgramAccountReadOptions,
  )
  callback;

  @override
  Future<List<ExampleProgramAccountSnapshot>> scanAccounts(
    ExampleProgramAddress programAddress, {
    List<ExampleProgramAccountFilter> filters = const [],
    ExampleProgramAccountReadOptions options =
        const ExampleProgramAccountReadOptions(),
  }) async => List.unmodifiable(
    await callback(programAddress, List.unmodifiable(filters), options),
  );
}

/// Immutable raw log notification.
final class ExampleProgramLogBatch {
  /// Creates a batch and copies ordered [logs].
  ExampleProgramLogBatch({
    required this.programAddress,
    required this.signature,
    required this.slot,
    required this.failure,
    required List<String> logs,
  }) : logs = List.unmodifiable(logs);

  /// Program address associated with the subscription.
  final ExampleProgramAddress programAddress;

  /// Transaction signature.
  final String signature;

  /// Context slot.
  final BigInt slot;

  /// Optional neutral transaction failure.
  final ExampleProgramTransactionFailure? failure;

  /// Ordered program logs.
  final List<String> logs;
}

/// Closeable raw event subscription.
abstract interface class ExampleProgramEventSubscription {
  /// Raw log stream. Transport failures are delivered as stream errors.
  Stream<ExampleProgramLogBatch> get batches;

  /// Closes the subscription. Implementations must be idempotent.
  Future<void> close();
}

/// Port used by generated event clients.
abstract interface class ExampleProgramEventSubscriber {
  /// Subscribes to logs for [programAddress].
  Future<ExampleProgramEventSubscription> subscribe(
    ExampleProgramAddress programAddress,
  );
}

/// Callback adapter for [ExampleProgramEventSubscriber].
final class ExampleProgramEventSubscriberCallback
    implements ExampleProgramEventSubscriber {
  /// Creates an adapter from [callback].
  const ExampleProgramEventSubscriberCallback(this.callback);

  /// Subscription callback.
  final Future<ExampleProgramEventSubscription> Function(ExampleProgramAddress)
  callback;

  @override
  Future<ExampleProgramEventSubscription> subscribe(
    ExampleProgramAddress programAddress,
  ) => callback(programAddress);
}

/// Immutable result of simulating one instruction.
final class ExampleProgramSimulationResult {
  /// Creates a simulation result and copies byte/log collections.
  ExampleProgramSimulationResult({
    required this.failure,
    required List<String> logs,
    required this.returnProgramAddress,
    required List<int>? returnData,
    required this.unitsConsumed,
    required this.slot,
  }) : logs = List.unmodifiable(logs),
       returnData = returnData == null
           ? null
           : Uint8List.fromList(returnData).asUnmodifiableView();

  /// Optional transaction failure.
  final ExampleProgramTransactionFailure? failure;

  /// Ordered logs.
  final List<String> logs;

  /// Program that supplied return data.
  final ExampleProgramAddress? returnProgramAddress;

  /// Immutable return bytes.
  final Uint8List? returnData;

  /// Optional compute units consumed.
  final BigInt? unitsConsumed;

  /// Context slot.
  final BigInt slot;
}

/// Port used by generated view clients.
abstract interface class ExampleProgramTransactionSimulator {
  /// Simulates exactly one [instruction].
  Future<ExampleProgramSimulationResult> simulate(
    ExampleProgramInstruction instruction,
  );
}

/// Callback adapter for [ExampleProgramTransactionSimulator].
final class ExampleProgramTransactionSimulatorCallback
    implements ExampleProgramTransactionSimulator {
  /// Creates an adapter from [callback].
  const ExampleProgramTransactionSimulatorCallback(this.callback);

  /// Simulation callback.
  final Future<ExampleProgramSimulationResult> Function(
    ExampleProgramInstruction,
  )
  callback;

  @override
  Future<ExampleProgramSimulationResult> simulate(
    ExampleProgramInstruction instruction,
  ) => callback(instruction);
}

/// Typed PDA seed or derivation failure.
final class ExampleProgramPdaException implements Exception {
  /// Creates a PDA failure.
  const ExampleProgramPdaException({
    required this.code,
    required this.message,
    this.seedIndex,
  });

  /// Stable failure code.
  final String code;

  /// Human-readable explanation.
  final String message;

  /// Optional failing seed index.
  final int? seedIndex;

  @override
  String toString() => 'ExampleProgramPdaException($code: $message)';
}

/// Immutable program-derived address and canonical bump.
final class ExampleProgramPdaResult {
  /// Creates a PDA result.
  ExampleProgramPdaResult({required this.address, required this.bump}) {
    if (bump < 0 || bump > 255) {
      throw RangeError.range(bump, 0, 255, 'bump');
    }
  }

  /// Derived address.
  final ExampleProgramAddress address;

  /// Canonical bump in the range 0–255.
  final int bump;
}

/// Port used for canonical program-derived-address calculation.
abstract interface class ExampleProgramPdaDeriver {
  /// Derives an address from at most 15 IDL [seeds].
  Future<ExampleProgramPdaResult> derive({
    required ExampleProgramAddress programAddress,
    required List<Uint8List> seeds,
  });
}

/// Callback adapter for [ExampleProgramPdaDeriver].
final class ExampleProgramPdaDeriverCallback
    implements ExampleProgramPdaDeriver {
  /// Creates an adapter from [callback].
  const ExampleProgramPdaDeriverCallback(this.callback);

  /// Derivation callback.
  final Future<ExampleProgramPdaResult> Function(
    ExampleProgramAddress,
    List<Uint8List>,
  )
  callback;

  @override
  Future<ExampleProgramPdaResult> derive({
    required ExampleProgramAddress programAddress,
    required List<Uint8List> seeds,
  }) => callback(
    programAddress,
    List.unmodifiable(
      seeds.map((seed) => Uint8List.fromList(seed).asUnmodifiableView()),
    ),
  );
}

/// Port used for application-specific account relation resolution.
abstract interface class ExampleProgramRelationResolver {
  /// Resolves [relationPath] or returns `null` for the current resolved account set.
  /// Implementations should be deterministic for the supplied arguments.
  Future<ExampleProgramAddress?> resolveRelation({
    required String accountPath,
    required String relationPath,
    required Map<String, ExampleProgramAddress> resolvedAccounts,
  });
}

/// Port used to decode a PDA seed from application-owned external account data.
abstract interface class ExampleProgramExternalAccountSeedResolver {
  /// Returns encoded seed bytes for the declared external account field.
  Future<Uint8List> resolve({
    required String accountPath,
    required String fieldPath,
    required String declaredType,
    required ExampleProgramAddress address,
    required ExampleProgramAccountSnapshot snapshot,
  });
}

/// Callback adapter for [ExampleProgramExternalAccountSeedResolver].
final class ExampleProgramExternalAccountSeedResolverCallback
    implements ExampleProgramExternalAccountSeedResolver {
  /// Creates an adapter from [callback].
  const ExampleProgramExternalAccountSeedResolverCallback(this.callback);

  /// External seed callback.
  final Future<Uint8List> Function(
    String accountPath,
    String fieldPath,
    String declaredType,
    ExampleProgramAddress address,
    ExampleProgramAccountSnapshot snapshot,
  )
  callback;

  @override
  Future<Uint8List> resolve({
    required String accountPath,
    required String fieldPath,
    required String declaredType,
    required ExampleProgramAddress address,
    required ExampleProgramAccountSnapshot snapshot,
  }) async => Uint8List.fromList(
    await callback(accountPath, fieldPath, declaredType, address, snapshot),
  ).asUnmodifiableView();
}

bool _programBytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

const _programBase58Alphabet =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
Uint8List _programBuildBase58Indexes() {
  final result = Uint8List(128)..fillRange(0, 128, 255);
  for (var index = 0; index < _programBase58Alphabet.length; index++) {
    result[_programBase58Alphabet.codeUnitAt(index)] = index;
  }
  return result;
}

final Uint8List _programBase58Indexes = _programBuildBase58Indexes();
Uint8List _programDecodeBase58(String value) {
  if (value.isEmpty) {
    throw const FormatException('Base58 value is empty.');
  }
  final codeUnits = value.codeUnits;
  for (final codeUnit in codeUnits) {
    if (codeUnit >= _programBase58Indexes.length) {
      throw const FormatException('Invalid Base58 character.');
    }
  }
  var leadingZeros = 0;
  while (leadingZeros < codeUnits.length && codeUnits[leadingZeros] == 49) {
    leadingZeros++;
  }
  final capacity = ((codeUnits.length - leadingZeros) * 733 ~/ 1000) + 1;
  final base256 = Uint8List(capacity);
  var significantLength = 0;
  for (var index = leadingZeros; index < codeUnits.length; index++) {
    final digit = _programBase58Indexes[codeUnits[index]];
    if (digit == 255) {
      throw const FormatException('Invalid Base58 character.');
    }
    var carry = digit;
    var outputIndex = capacity - 1;
    for (
      var processed = 0;
      processed < significantLength;
      processed++, outputIndex--
    ) {
      carry += 58 * base256[outputIndex];
      base256[outputIndex] = carry & 0xff;
      carry >>= 8;
    }
    while (carry > 0) {
      base256[outputIndex] = carry & 0xff;
      carry >>= 8;
      outputIndex--;
      significantLength++;
    }
  }
  var firstSignificant = 0;
  while (firstSignificant < capacity && base256[firstSignificant] == 0) {
    firstSignificant++;
  }
  final result = Uint8List(leadingZeros + capacity - firstSignificant);
  result.setRange(leadingZeros, result.length, base256, firstSignificant);
  return result;
}

String _programEncodeBase58(List<int> bytes) {
  var number = BigInt.zero;
  for (final byte in bytes) {
    number = number * BigInt.from(256) + BigInt.from(byte);
  }
  final encoded = StringBuffer();
  while (number > BigInt.zero) {
    final digit = (number % BigInt.from(58)).toInt();
    encoded.write(_programBase58Alphabet[digit]);
    number ~/= BigInt.from(58);
  }
  for (final byte in bytes) {
    if (byte != 0) {
      break;
    }
    encoded.write('1');
  }
  return encoded.toString().split('').reversed.join();
}
