import 'package:code_builder/code_builder.dart';

import '../../section_emitter.dart';
import 'reader_collection_methods_fragment.dart';
import 'reader_path_methods_fragment.dart';
import 'reader_primitive_methods_fragment.dart';

/// Coordinates method groups used by the generated Borsh reader class.
final class BorshReaderMethodsFragment extends SectionEmitter {
  /// Creates reader method helpers for [context].
  const BorshReaderMethodsFragment(super.context);

  /// This helper contributes methods to `BorshReader`, not top-level specs.
  @override
  List<Spec> emit() => const [];

  /// Emits logical path and nesting helper methods.
  List<Method> pathMethods(String error) =>
      BorshReaderPathMethodsFragment(context).methods(error);

  /// Emits primitive read methods.
  List<Method> primitiveMethods(String error) =>
      BorshReaderPrimitiveMethodsFragment(context).methods(error);

  /// Emits string and collection read methods.
  List<Method> collectionMethods(String error) =>
      BorshReaderCollectionMethodsFragment(context).methods(error);
}
