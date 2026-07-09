import 'package:code_builder/code_builder.dart';

import 'account_decoder_emitter.dart';
import 'accounts_client_emitter.dart';
import 'section_emitter.dart';

/// Emits typed account decoders and account-client declarations.
final class AccountsEmitter extends SectionEmitter {
  /// Creates an account emitter for [context].
  const AccountsEmitter(super.context);

  /// Emits account-related declarations for the current program.
  @override
  List<Spec> emit() => List.unmodifiable([
    ...AccountDecoderEmitter(context).emit(),
    ...AccountsClientEmitter(context).emit(),
  ]);
}
