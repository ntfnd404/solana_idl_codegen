import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import 'generated/example_program_solana.dart';

/// Optional application-owned adapter from `package:solana` to the generated
/// account-reader port.
///
/// The generator itself does not import or require `package:solana`.
final class SolanaExampleAccountReader implements ExampleProgramAccountReader {
  /// Creates an adapter around the application's [client].
  const SolanaExampleAccountReader(this.client);

  /// RPC client selected by the application.
  final RpcClient client;

  @override
  Future<ExampleProgramAccountSnapshot?> readAccount(
    ExampleProgramAddress address, {
    ExampleProgramAccountReadOptions options =
        const ExampleProgramAccountReadOptions(),
  }) async {
    final result = await client.getAccountInfo(
      address.toBase58(),
      commitment: _commitment(options.commitment),
      encoding: Encoding.base64,
      minContextSlot: options.minContextSlot?.toInt(),
    );
    final account = result.value;
    if (account == null) return null;
    final data = switch (account.data) {
      BinaryAccountData(:final data) => data,
      _ => const <int>[],
    };
    return ExampleProgramAccountSnapshot(
      address: address,
      owner: ExampleProgramAddress.fromBase58(account.owner),
      data: data,
      lamports: BigInt.from(account.lamports),
      executable: account.executable,
      rentEpoch: account.rentEpoch,
      slot: result.context.slot,
    );
  }

  @override
  Future<List<ExampleProgramAccountSnapshot?>> readAccounts(
    List<ExampleProgramAddress> addresses, {
    ExampleProgramAccountReadOptions options =
        const ExampleProgramAccountReadOptions(),
  }) async => Future.wait(
    addresses.map((address) => readAccount(address, options: options)),
  );

  Commitment _commitment(ExampleProgramCommitment value) => switch (value) {
    ExampleProgramCommitment.processed => Commitment.processed,
    ExampleProgramCommitment.confirmed => Commitment.confirmed,
    ExampleProgramCommitment.finalized => Commitment.finalized,
  };
}
