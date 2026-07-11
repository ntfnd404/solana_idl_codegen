import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'generated/example_program_solana.dart';
import 'generated/secondary_program_solana.dart';

void main() => runApp(const GeneratorExampleApp());

/// Neutral Flutter example that composes two generated SDKs.
final class GeneratorExampleApp extends StatelessWidget {
  /// Creates the example application.
  const GeneratorExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'solana_idl_codegen',
    theme: ThemeData(colorSchemeSeed: Colors.indigo),
    home: const _ExampleScreen(),
  );
}

final class _ExampleScreen extends StatefulWidget {
  const _ExampleScreen();

  @override
  State<_ExampleScreen> createState() => _ExampleScreenState();
}

final class _ExampleScreenState extends State<_ExampleScreen> {
  String _result = 'Press Build to create two transport-neutral instructions.';

  void _buildInstructions() {
    final address = ExampleProgramProgram.programAddress;
    final create = ExampleProgramCreateMessageRequest(
      args: ExampleProgramCreateMessageArgs(
        id: BigInt.from(7),
        text: 'hello from Flutter',
      ),
      accounts: ExampleProgramCreateMessageAccounts(
        authority: address,
        stateMessage: address,
        optionalReferrer: null,
        systemProgram: address,
      ),
    ).instruction();
    final consume = SecondaryProgramConsumeRequest(
      args: SecondaryProgramConsumeArgs(payload: create.data),
      accounts: SecondaryProgramConsumeAccounts(
        authority: SecondaryProgramProgram.programAddress,
      ),
    ).instruction();

    final transaction = <_ApplicationInstruction>[
      _ApplicationInstruction.fromExample(create.toWire()),
      _ApplicationInstruction.fromSecondary(consume.toWire()),
    ];
    setState(() {
      _result =
          'Application transaction: ${transaction.length} instructions, '
          '${transaction.fold<int>(0, (sum, item) => sum + item.data.length)} bytes.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Anchor IDL → Dart SDK')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The generated SDK owns serialization and typed accounts. '
            'The application owns RPC, wallets, transactions, and sending.',
          ),
          const SizedBox(height: 24),
          Text(_result),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _buildInstructions,
            child: const Text('Build instructions'),
          ),
        ],
      ),
    ),
  );
}

final class _ApplicationInstruction {
  _ApplicationInstruction({
    required List<int> programAddress,
    required this.accountCount,
    required List<int> data,
  }) : programAddress = Uint8List.fromList(programAddress),
       data = Uint8List.fromList(data);

  factory _ApplicationInstruction.fromExample(
    ({
      Uint8List programAddress,
      List<({Uint8List address, bool isSigner, bool isWritable})> accounts,
      Uint8List data,
    })
    value,
  ) => _ApplicationInstruction(
    programAddress: value.programAddress,
    accountCount: value.accounts.length,
    data: value.data,
  );

  factory _ApplicationInstruction.fromSecondary(
    ({
      Uint8List programAddress,
      List<({Uint8List address, bool isSigner, bool isWritable})> accounts,
      Uint8List data,
    })
    value,
  ) => _ApplicationInstruction(
    programAddress: value.programAddress,
    accountCount: value.accounts.length,
    data: value.data,
  );

  final Uint8List programAddress;
  final int accountCount;
  final Uint8List data;
}
