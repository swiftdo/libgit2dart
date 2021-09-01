import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'libgit2_bindings.dart';
import '../error.dart';
import '../util.dart';

/// Parse a revision string for from, to, and intent.
///
/// See `man gitrevisions` or https://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
/// for information on the syntax accepted.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_revspec> revParse(
  Pointer<git_repository> repo,
  String spec,
) {
  final out = calloc<git_revspec>();
  final specC = spec.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_revparse(out, repo, specC);

  calloc.free(specC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Find a single object, as specified by a [spec] revision string.
/// See `man gitrevisions`, or https://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
/// for information on the syntax accepted.
///
/// The returned object should be released when no longer needed.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_object> revParseSingle(Pointer<git_repository> repo, String spec) {
  final out = calloc<Pointer<git_object>>();
  final specC = spec.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_revparse_single(
    out,
    repo,
    specC,
  );

  calloc.free(specC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Find a single object and intermediate reference by a [spec] revision string.
///
/// See `man gitrevisions`, or https://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
/// for information on the syntax accepted.
///
/// In some cases (@{<-n>} or <branchname>@{upstream}), the expression may point to an
/// intermediate reference. When such expressions are being passed in, reference_out will be
/// valued as well.
///
/// The returned object and reference should be released when no longer needed.
///
/// Throws a [LibGit2Error] if error occured.
List revParseExt(Pointer<git_repository> repo, String spec) {
  final objectOut = calloc<Pointer<git_object>>();
  final referenceOut = calloc<Pointer<git_reference>>();
  final specC = spec.toNativeUtf8().cast<Int8>();
  var result = [];
  final error = libgit2.git_revparse_ext(objectOut, referenceOut, repo, specC);

  calloc.free(specC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    result.add(objectOut.value);
    if (referenceOut.value != nullptr) {
      result.add(referenceOut.value);
    }
    return result;
  }
}