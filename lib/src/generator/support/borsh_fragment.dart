import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';
import 'borsh/codec_fragment.dart';
import 'borsh/error_fragment.dart';
import 'borsh/float_semantics_fragment.dart';
import 'borsh/limits_fragment.dart';
import 'borsh/reader_fragment.dart';
import 'borsh/writer_fragment.dart';

/// Coordinates focused generated Borsh runtime fragments.
final class BorshSupportFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const BorshSupportFragment(super.context);

  @override
  List<Spec> emit() => <Spec>[
    ...BorshLimitsFragment(context).emit(),
    ...BorshFloatSemanticsFragment(context).emit(),
    ...BorshErrorFragment(context).emit(),
    ...BorshReaderFragment(context).emit(),
    ...BorshWriterFragment(context).emit(),
    ...BorshCodecFragment(context).emit(),
  ];
}
