import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Find a merge base between two commits.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> mergeBase({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_oid> aPointer,
  required Pointer<git_oid> bPointer,
}) {
  final out = calloc<git_oid>();
  final error = libgit2.git_merge_base(out, repoPointer, aPointer, bPointer);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Analyzes the given branch(es) and determines the opportunities for merging them
/// into a reference.
///
/// Throws a [LibGit2Error] if error occured.
List<int> analysis({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_reference> ourRefPointer,
  required Pointer<Pointer<git_annotated_commit>> theirHeadPointer,
  required int theirHeadsLen,
}) {
  final analysisOut = calloc<Int32>();
  final preferenceOut = calloc<Int32>();
  final error = libgit2.git_merge_analysis_for_ref(
    analysisOut,
    preferenceOut,
    repoPointer,
    ourRefPointer,
    theirHeadPointer,
    theirHeadsLen,
  );
  var result = <int>[];

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    result.add(analysisOut.value);
    result.add(preferenceOut.value);
    calloc.free(analysisOut);
    calloc.free(preferenceOut);
    return result;
  }
}

/// Merges the given commit(s) into HEAD, writing the results into the working directory.
/// Any changes are staged for commit and any conflicts are written to the index. Callers
/// should inspect the repository's index after this completes, resolve any conflicts and
/// prepare a commit.
///
/// Throws a [LibGit2Error] if error occured.
void merge({
  required Pointer<git_repository> repoPointer,
  required Pointer<Pointer<git_annotated_commit>> theirHeadsPointer,
  required int theirHeadsLen,
}) {
  final mergeOpts = calloc<git_merge_options>(sizeOf<git_merge_options>());
  libgit2.git_merge_options_init(mergeOpts, GIT_MERGE_OPTIONS_VERSION);

  final checkoutOpts =
      calloc<git_checkout_options>(sizeOf<git_checkout_options>());
  libgit2.git_checkout_options_init(checkoutOpts, GIT_CHECKOUT_OPTIONS_VERSION);
  checkoutOpts.ref.checkout_strategy =
      git_checkout_strategy_t.GIT_CHECKOUT_SAFE +
          git_checkout_strategy_t.GIT_CHECKOUT_RECREATE_MISSING;

  final error = libgit2.git_merge(
    repoPointer,
    theirHeadsPointer,
    theirHeadsLen,
    mergeOpts,
    checkoutOpts,
  );

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Merge two commits, producing a git_index that reflects the result of the merge.
/// The index may be written as-is to the working directory or checked out. If the index
/// is to be converted to a tree, the caller should resolve any conflicts that arose as
/// part of the merge.
///
/// The returned index must be freed explicitly.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_index> mergeCommits({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_commit> ourCommitPointer,
  required Pointer<git_commit> theirCommitPointer,
  required Map<String, int> opts,
}) {
  final out = calloc<Pointer<git_index>>();
  final optsC = calloc<git_merge_options>(sizeOf<git_merge_options>());
  optsC.ref.file_favor = opts['favor']!;
  optsC.ref.flags = opts['mergeFlags']!;
  optsC.ref.file_flags = opts['fileFlags']!;
  optsC.ref.version = GIT_MERGE_OPTIONS_VERSION;

  final error = libgit2.git_merge_commits(
    out,
    repoPointer,
    ourCommitPointer,
    theirCommitPointer,
    optsC,
  );

  calloc.free(optsC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Merge two trees, producing a git_index that reflects the result of the merge.
/// The index may be written as-is to the working directory or checked out. If the index
/// is to be converted to a tree, the caller should resolve any conflicts that arose as part
/// of the merge.
///
/// The returned index must be freed explicitly.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_index> mergeTrees({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_tree> ancestorTreePointer,
  required Pointer<git_tree> ourTreePointer,
  required Pointer<git_tree> theirTreePointer,
  required Map<String, int> opts,
}) {
  final out = calloc<Pointer<git_index>>();
  final optsC = calloc<git_merge_options>(sizeOf<git_merge_options>());
  optsC.ref.file_favor = opts['favor']!;
  optsC.ref.flags = opts['mergeFlags']!;
  optsC.ref.file_flags = opts['fileFlags']!;
  optsC.ref.version = GIT_MERGE_OPTIONS_VERSION;

  final error = libgit2.git_merge_trees(
    out,
    repoPointer,
    ancestorTreePointer,
    ourTreePointer,
    theirTreePointer,
    optsC,
  );

  calloc.free(optsC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Cherry-pick the given commit, producing changes in the index and working directory.
///
/// Throws a [LibGit2Error] if error occured.
void cherryPick({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_commit> commitPointer,
}) {
  final opts = calloc<git_cherrypick_options>(sizeOf<git_cherrypick_options>());
  libgit2.git_cherrypick_options_init(opts, GIT_CHERRYPICK_OPTIONS_VERSION);
  opts.ref.checkout_opts.checkout_strategy =
      git_checkout_strategy_t.GIT_CHECKOUT_SAFE;

  final error = libgit2.git_cherrypick(repoPointer, commitPointer, opts);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}
