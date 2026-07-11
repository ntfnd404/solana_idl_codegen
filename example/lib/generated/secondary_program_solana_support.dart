// GENERATED CODE - DO NOT MODIFY BY HAND.
// tool: solana_idl_codegen
// generator-version: 0.1.0
// source-sha256: bfba19c124c33b827b5c139cc62b583f9c36aafb5951f72e02387a67705816a7
// semantic-ir-sha256: 116502c850c55b1b16510193442452e33c2161adb8e40f36a00d8c66826e6b0a
// SPDX-License-Identifier: MIT
// ignore_for_file: curly_braces_in_flow_control_structures, empty_constructor_bodies, prefer_initializing_formals, unused_element, unused_import, use_super_parameters

/// Generated runtime support for `secondary_program`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

/// Immutable 32-byte Solana address used by the generated SDK.
final class SecondaryProgramAddress {
  SecondaryProgramAddress._(Uint8List bytes)
    : _bytes = Uint8List.fromList(bytes);

  /// Creates an address from exactly 32 bytes.
  factory SecondaryProgramAddress.fromBytes(List<int> bytes) {
    if (bytes.length != 32) {
      throw ArgumentError.value(bytes.length, 'bytes', 'Expected 32 bytes.');
    }
    for (final byte in bytes) {
      if (byte < 0 || byte > 255) {
        throw ArgumentError.value(byte, 'bytes', 'Expected byte values.');
      }
    }
    return SecondaryProgramAddress._(Uint8List.fromList(bytes));
  }

  /// Decodes a canonical Base58 address.
  factory SecondaryProgramAddress.fromBase58(String value) {
    final decoded = _programDecodeBase58(value);
    if (decoded.length != 32) {
      throw FormatException('Address must decode to exactly 32 bytes.');
    }
    final address = SecondaryProgramAddress.fromBytes(decoded);
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
      other is SecondaryProgramAddress &&
          _programBytesEqual(_bytes, other._bytes);

  @override
  int get hashCode => Object.hashAll(_bytes);

  @override
  String toString() => toBase58();
}

/// Immutable account metadata for one instruction account position.
final class SecondaryProgramAccountMeta {
  /// Creates account metadata.
  const SecondaryProgramAccountMeta({
    required this.address,
    required this.isSigner,
    required this.isWritable,
  });

  /// Account address.
  final SecondaryProgramAddress address;

  /// Whether the transaction requires this account to sign.
  final bool isSigner;

  /// Whether the instruction may write this account.
  final bool isWritable;
}

/// Immutable transport-neutral Solana instruction.
final class SecondaryProgramInstruction {
  /// Creates an instruction and defensively copies collections.
  SecondaryProgramInstruction({
    required this.programAddress,
    required List<SecondaryProgramAccountMeta> accounts,
    required List<int> data,
  }) : accounts = List.unmodifiable(accounts),
       data = Uint8List.fromList(data).asUnmodifiableView();

  /// Program invoked by this instruction.
  final SecondaryProgramAddress programAddress;

  /// Ordered account metadata. Duplicate positions are preserved.
  final List<SecondaryProgramAccountMeta> accounts;

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
final class SecondaryProgramAccountMetadata {
  /// Creates account metadata and copies byte lists.
  SecondaryProgramAccountMetadata({
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
final class SecondaryProgramInstructionAccountMetadata {
  /// Creates instruction account metadata.
  const SecondaryProgramInstructionAccountMetadata({
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
final class SecondaryProgramInstructionMetadata {
  /// Creates instruction metadata and copies collections.
  SecondaryProgramInstructionMetadata({
    required this.name,
    required List<int> discriminator,
    required List<SecondaryProgramInstructionAccountMetadata> accounts,
  }) : discriminator = List.unmodifiable(discriminator),
       accounts = List.unmodifiable(accounts);

  /// IDL instruction name.
  final String name;

  /// Instruction discriminator bytes.
  final List<int> discriminator;

  /// Ordered account metadata. Duplicate positions are preserved.
  final List<SecondaryProgramInstructionAccountMetadata> accounts;

  /// Number of discriminator bytes.
  int get discriminatorLength => discriminator.length;
}

/// Resource limits applied by every public Borsh decoder.
final class SecondaryProgramDecodeLimits {
  /// Creates explicit decoder limits.
  const SecondaryProgramDecodeLimits({
    required this.maxInputBytes,
    required this.maxStringBytes,
    required this.maxCollectionLength,
    required this.maxTotalElements,
    required this.maxNestingDepth,
  });

  /// Recommended limits for untrusted account and event data.
  static const defaults = SecondaryProgramDecodeLimits(
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
abstract final class SecondaryProgramFloatSemantics {
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
final class SecondaryProgramBorshException implements Exception {
  /// Creates a structured Borsh failure.
  const SecondaryProgramBorshException({
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
      'SecondaryProgramBorshException($code at $path+$offset: $message)';
}

/// Mutable, bounds-checked Borsh reader scoped to one decode operation.
final class SecondaryProgramBorshReader {
  /// Creates a reader over a defensive copy of [input].
  SecondaryProgramBorshReader(
    List<int> input, {
    this.limits = SecondaryProgramDecodeLimits.defaults,
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
      throw SecondaryProgramBorshException(
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
  final SecondaryProgramDecodeLimits limits;

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
      throw SecondaryProgramBorshException(
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
      throw SecondaryProgramBorshException(
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
      _ => throw SecondaryProgramBorshException(
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
      _ => throw SecondaryProgramBorshException(
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
      throw SecondaryProgramBorshException(
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
      throw SecondaryProgramBorshException(
        code: 'BORSH_STRING_LIMIT',
        message: 'String exceeds maxStringBytes.',
        offset: _offset - 4,
        path: logicalPath,
      );
    }
    try {
      return utf8.decode(readBytes(length, path: path), allowMalformed: false);
    } on FormatException catch (error) {
      throw SecondaryProgramBorshException(
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
      throw SecondaryProgramBorshException(
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
final class SecondaryProgramBorshWriter {
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
abstract base class SecondaryProgramBorshCodec<T> {
  /// Creates a codec.
  const SecondaryProgramBorshCodec();

  /// Reads one value from [reader].
  T read(SecondaryProgramBorshReader reader);

  /// Writes one [value] to [writer].
  void write(SecondaryProgramBorshWriter writer, T value);

  /// Encodes [value] into an immutable byte array.
  Uint8List encode(T value) {
    final writer = SecondaryProgramBorshWriter();
    write(writer, value);
    return writer.takeBytes();
  }

  /// Decodes one value and requires complete input consumption.
  T decodeExact(
    List<int> input, {
    SecondaryProgramDecodeLimits limits = SecondaryProgramDecodeLimits.defaults,
  }) {
    final result = decodePrefix(input, limits: limits);
    if (result.consumed != input.length) {
      throw SecondaryProgramBorshException(
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
    SecondaryProgramDecodeLimits limits = SecondaryProgramDecodeLimits.defaults,
  }) {
    final reader = SecondaryProgramBorshReader(input, limits: limits);
    return (value: read(reader), consumed: reader.offset);
  }
}

/// Codec assembled from injected read and write functions.
final class SecondaryProgramFunctionalBorshCodec<T>
    extends SecondaryProgramBorshCodec<T> {
  /// Creates a codec from [reader] and [writer].
  const SecondaryProgramFunctionalBorshCodec(this.reader, this.writer);

  /// Function that reads one value.
  final T Function(SecondaryProgramBorshReader reader) reader;

  /// Function that writes one value.
  final void Function(SecondaryProgramBorshWriter writer, T value) writer;

  @override
  T read(SecondaryProgramBorshReader reader) => this.reader(reader);

  @override
  void write(SecondaryProgramBorshWriter writer, T value) =>
      this.writer(writer, value);
}

/// Neutral transaction failure supplied by an application adapter.
final class SecondaryProgramTransactionFailure {
  /// Creates a failure.
  const SecondaryProgramTransactionFailure({
    required this.code,
    required this.message,
  });

  /// Adapter-defined stable code.
  final String code;

  /// Human-readable failure message.
  final String message;
}

/// Typed account read, ownership, decoding, or capability failure.
final class SecondaryProgramAccountException implements Exception {
  /// Creates a failure with a stable machine-readable [code].
  const SecondaryProgramAccountException({
    required this.code,
    required this.message,
  });

  /// Stable generated SDK error code.
  final String code;

  /// Human-readable failure description.
  final String message;

  @override
  String toString() => 'SecondaryProgramAccountException($code: $message)';
}

/// Typed view simulation or return-data failure.
final class SecondaryProgramViewException implements Exception {
  /// Creates a failure with a stable machine-readable [code].
  const SecondaryProgramViewException({
    required this.code,
    required this.message,
  });

  /// Stable generated SDK error code.
  final String code;

  /// Human-readable failure description.
  final String message;

  @override
  String toString() => 'SecondaryProgramViewException($code: $message)';
}

/// Immutable account state returned by an application adapter.
final class SecondaryProgramAccountSnapshot {
  /// Creates an account snapshot and copies [data].
  SecondaryProgramAccountSnapshot({
    required this.address,
    required this.owner,
    required List<int> data,
    required this.lamports,
    required this.executable,
    required this.rentEpoch,
    required this.slot,
  }) : data = Uint8List.fromList(data).asUnmodifiableView();

  /// Account address.
  final SecondaryProgramAddress address;

  /// Owning program address.
  final SecondaryProgramAddress owner;

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
enum SecondaryProgramCommitment {
  /// Processed commitment.
  processed,

  /// Confirmed commitment.
  confirmed,

  /// Finalized commitment.
  finalized,
}

/// Transport-neutral account read options.
final class SecondaryProgramAccountReadOptions {
  /// Creates account read options.
  const SecondaryProgramAccountReadOptions({
    this.commitment = SecondaryProgramCommitment.confirmed,
    this.minContextSlot,
  });

  /// Requested commitment.
  final SecondaryProgramCommitment commitment;

  /// Optional minimum context slot.
  final BigInt? minContextSlot;
}

/// Base class for transport-neutral account scanner filters.
sealed class SecondaryProgramAccountFilter {
  /// Creates an account scanner filter.
  const SecondaryProgramAccountFilter();
}

/// Immutable memcmp scanner filter.
final class SecondaryProgramMemcmpFilter extends SecondaryProgramAccountFilter {
  /// Creates a memcmp filter and copies [bytes].
  SecondaryProgramMemcmpFilter({required this.offset, required List<int> bytes})
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
final class SecondaryProgramDataSizeFilter
    extends SecondaryProgramAccountFilter {
  /// Creates a data-size filter.
  const SecondaryProgramDataSizeFilter(this.size) : assert(size >= 0);

  /// Required byte length.
  final int size;
}

/// Port used by generated account clients to read addresses.
abstract interface class SecondaryProgramAccountReader {
  /// Reads one account or returns `null` when it does not exist.
  Future<SecondaryProgramAccountSnapshot?> readAccount(
    SecondaryProgramAddress address, {
    SecondaryProgramAccountReadOptions options =
        const SecondaryProgramAccountReadOptions(),
  });

  /// Reads accounts while preserving input order and missing positions.
  Future<List<SecondaryProgramAccountSnapshot?>> readAccounts(
    List<SecondaryProgramAddress> addresses, {
    SecondaryProgramAccountReadOptions options =
        const SecondaryProgramAccountReadOptions(),
  });
}

/// Callback adapter for [SecondaryProgramAccountReader].
final class SecondaryProgramAccountReaderCallback
    implements SecondaryProgramAccountReader {
  /// Creates an adapter from callbacks.
  const SecondaryProgramAccountReaderCallback({
    required this.readOne,
    required this.readMany,
  });

  /// Single-account callback.
  final Future<SecondaryProgramAccountSnapshot?> Function(
    SecondaryProgramAddress,
    SecondaryProgramAccountReadOptions,
  )
  readOne;

  /// Multi-account callback.
  final Future<List<SecondaryProgramAccountSnapshot?>> Function(
    List<SecondaryProgramAddress>,
    SecondaryProgramAccountReadOptions,
  )
  readMany;

  @override
  Future<SecondaryProgramAccountSnapshot?> readAccount(
    SecondaryProgramAddress address, {
    SecondaryProgramAccountReadOptions options =
        const SecondaryProgramAccountReadOptions(),
  }) => readOne(address, options);

  @override
  Future<List<SecondaryProgramAccountSnapshot?>> readAccounts(
    List<SecondaryProgramAddress> addresses, {
    SecondaryProgramAccountReadOptions options =
        const SecondaryProgramAccountReadOptions(),
  }) async =>
      List.unmodifiable(await readMany(List.unmodifiable(addresses), options));
}

/// Port used to scan program-owned accounts.
abstract interface class SecondaryProgramAccountScanner {
  /// Scans accounts using ordered transport-neutral [filters].
  Future<List<SecondaryProgramAccountSnapshot>> scanAccounts(
    SecondaryProgramAddress programAddress, {
    List<SecondaryProgramAccountFilter> filters = const [],
    SecondaryProgramAccountReadOptions options =
        const SecondaryProgramAccountReadOptions(),
  });
}

/// Callback adapter for [SecondaryProgramAccountScanner].
final class SecondaryProgramAccountScannerCallback
    implements SecondaryProgramAccountScanner {
  /// Creates an adapter from [callback].
  const SecondaryProgramAccountScannerCallback(this.callback);

  /// Scanner callback.
  final Future<List<SecondaryProgramAccountSnapshot>> Function(
    SecondaryProgramAddress,
    List<SecondaryProgramAccountFilter>,
    SecondaryProgramAccountReadOptions,
  )
  callback;

  @override
  Future<List<SecondaryProgramAccountSnapshot>> scanAccounts(
    SecondaryProgramAddress programAddress, {
    List<SecondaryProgramAccountFilter> filters = const [],
    SecondaryProgramAccountReadOptions options =
        const SecondaryProgramAccountReadOptions(),
  }) async => List.unmodifiable(
    await callback(programAddress, List.unmodifiable(filters), options),
  );
}

/// Immutable raw log notification.
final class SecondaryProgramLogBatch {
  /// Creates a batch and copies ordered [logs].
  SecondaryProgramLogBatch({
    required this.programAddress,
    required this.signature,
    required this.slot,
    required this.failure,
    required List<String> logs,
  }) : logs = List.unmodifiable(logs);

  /// Program address associated with the subscription.
  final SecondaryProgramAddress programAddress;

  /// Transaction signature.
  final String signature;

  /// Context slot.
  final BigInt slot;

  /// Optional neutral transaction failure.
  final SecondaryProgramTransactionFailure? failure;

  /// Ordered program logs.
  final List<String> logs;
}

/// Closeable raw event subscription.
abstract interface class SecondaryProgramEventSubscription {
  /// Raw log stream. Transport failures are delivered as stream errors.
  Stream<SecondaryProgramLogBatch> get batches;

  /// Closes the subscription. Implementations must be idempotent.
  Future<void> close();
}

/// Port used by generated event clients.
abstract interface class SecondaryProgramEventSubscriber {
  /// Subscribes to logs for [programAddress].
  Future<SecondaryProgramEventSubscription> subscribe(
    SecondaryProgramAddress programAddress,
  );
}

/// Callback adapter for [SecondaryProgramEventSubscriber].
final class SecondaryProgramEventSubscriberCallback
    implements SecondaryProgramEventSubscriber {
  /// Creates an adapter from [callback].
  const SecondaryProgramEventSubscriberCallback(this.callback);

  /// Subscription callback.
  final Future<SecondaryProgramEventSubscription> Function(
    SecondaryProgramAddress,
  )
  callback;

  @override
  Future<SecondaryProgramEventSubscription> subscribe(
    SecondaryProgramAddress programAddress,
  ) => callback(programAddress);
}

/// Immutable result of simulating one instruction.
final class SecondaryProgramSimulationResult {
  /// Creates a simulation result and copies byte/log collections.
  SecondaryProgramSimulationResult({
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
  final SecondaryProgramTransactionFailure? failure;

  /// Ordered logs.
  final List<String> logs;

  /// Program that supplied return data.
  final SecondaryProgramAddress? returnProgramAddress;

  /// Immutable return bytes.
  final Uint8List? returnData;

  /// Optional compute units consumed.
  final BigInt? unitsConsumed;

  /// Context slot.
  final BigInt slot;
}

/// Port used by generated view clients.
abstract interface class SecondaryProgramTransactionSimulator {
  /// Simulates exactly one [instruction].
  Future<SecondaryProgramSimulationResult> simulate(
    SecondaryProgramInstruction instruction,
  );
}

/// Callback adapter for [SecondaryProgramTransactionSimulator].
final class SecondaryProgramTransactionSimulatorCallback
    implements SecondaryProgramTransactionSimulator {
  /// Creates an adapter from [callback].
  const SecondaryProgramTransactionSimulatorCallback(this.callback);

  /// Simulation callback.
  final Future<SecondaryProgramSimulationResult> Function(
    SecondaryProgramInstruction,
  )
  callback;

  @override
  Future<SecondaryProgramSimulationResult> simulate(
    SecondaryProgramInstruction instruction,
  ) => callback(instruction);
}

/// Typed PDA seed or derivation failure.
final class SecondaryProgramPdaException implements Exception {
  /// Creates a PDA failure.
  const SecondaryProgramPdaException({
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
  String toString() => 'SecondaryProgramPdaException($code: $message)';
}

/// Immutable program-derived address and canonical bump.
final class SecondaryProgramPdaResult {
  /// Creates a PDA result.
  SecondaryProgramPdaResult({required this.address, required this.bump}) {
    if (bump < 0 || bump > 255) {
      throw RangeError.range(bump, 0, 255, 'bump');
    }
  }

  /// Derived address.
  final SecondaryProgramAddress address;

  /// Canonical bump in the range 0–255.
  final int bump;
}

/// Port used for canonical program-derived-address calculation.
abstract interface class SecondaryProgramPdaDeriver {
  /// Derives an address from at most 15 IDL [seeds].
  Future<SecondaryProgramPdaResult> derive({
    required SecondaryProgramAddress programAddress,
    required List<Uint8List> seeds,
  });
}

/// Callback adapter for [SecondaryProgramPdaDeriver].
final class SecondaryProgramPdaDeriverCallback
    implements SecondaryProgramPdaDeriver {
  /// Creates an adapter from [callback].
  const SecondaryProgramPdaDeriverCallback(this.callback);

  /// Derivation callback.
  final Future<SecondaryProgramPdaResult> Function(
    SecondaryProgramAddress,
    List<Uint8List>,
  )
  callback;

  @override
  Future<SecondaryProgramPdaResult> derive({
    required SecondaryProgramAddress programAddress,
    required List<Uint8List> seeds,
  }) => callback(
    programAddress,
    List.unmodifiable(
      seeds.map((seed) => Uint8List.fromList(seed).asUnmodifiableView()),
    ),
  );
}

/// Port used for application-specific account relation resolution.
abstract interface class SecondaryProgramRelationResolver {
  /// Resolves [relationPath] or returns `null` for the current resolved account set.
  /// Implementations should be deterministic for the supplied arguments.
  Future<SecondaryProgramAddress?> resolveRelation({
    required String accountPath,
    required String relationPath,
    required Map<String, SecondaryProgramAddress> resolvedAccounts,
  });
}

/// Port used to decode a PDA seed from application-owned external account data.
abstract interface class SecondaryProgramExternalAccountSeedResolver {
  /// Returns encoded seed bytes for the declared external account field.
  Future<Uint8List> resolve({
    required String accountPath,
    required String fieldPath,
    required String declaredType,
    required SecondaryProgramAddress address,
    required SecondaryProgramAccountSnapshot snapshot,
  });
}

/// Callback adapter for [SecondaryProgramExternalAccountSeedResolver].
final class SecondaryProgramExternalAccountSeedResolverCallback
    implements SecondaryProgramExternalAccountSeedResolver {
  /// Creates an adapter from [callback].
  const SecondaryProgramExternalAccountSeedResolverCallback(this.callback);

  /// External seed callback.
  final Future<Uint8List> Function(
    String accountPath,
    String fieldPath,
    String declaredType,
    SecondaryProgramAddress address,
    SecondaryProgramAccountSnapshot snapshot,
  )
  callback;

  @override
  Future<Uint8List> resolve({
    required String accountPath,
    required String fieldPath,
    required String declaredType,
    required SecondaryProgramAddress address,
    required SecondaryProgramAccountSnapshot snapshot,
  }) async => Uint8List.fromList(
    await callback(accountPath, fieldPath, declaredType, address, snapshot),
  ).asUnmodifiableView();
}

bool _programBytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
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
    if (byte != 0) break;
    encoded.write('1');
  }
  return encoded.toString().split('').reversed.join();
}
