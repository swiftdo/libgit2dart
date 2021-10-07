import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'libgit2_bindings.dart';
import '../error.dart';
import '../util.dart';

/// Initializes a rebase operation to rebase the changes in [branchPointer] relative
/// to [upstreamPointer] onto [ontoPointer] another branch. To begin the rebase process, call
/// `next()`. When you have finished with this object, call `free()`.
///
/// [branchPointer] is the terminal commit to rebase, or null to rebase the current branch.
///
/// [upstreamPointer] is the commit to begin rebasing from, or null to rebase all
/// reachable commits.
///
/// [ontoPointer] is the branch to rebase onto, or null to rebase onto the given upstream.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_rebase> init({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_annotated_commit>? branchPointer,
  required Pointer<git_annotated_commit>? upstreamPointer,
  required Pointer<git_annotated_commit>? ontoPointer,
}) {
  final out = calloc<Pointer<git_rebase>>();
  final opts = calloc<git_rebase_options>();

  final optsError = libgit2.git_rebase_options_init(
    opts,
    GIT_REBASE_OPTIONS_VERSION,
  );

  if (optsError < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  final error = libgit2.git_rebase_init(
    out,
    repoPointer,
    branchPointer ?? nullptr,
    upstreamPointer ?? nullptr,
    ontoPointer ?? nullptr,
    opts,
  );

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Gets the count of rebase operations that are to be applied.
int operationsCount(Pointer<git_rebase> rebase) {
  return libgit2.git_rebase_operation_entrycount(rebase);
}

/// Performs the next rebase operation and returns the information about it.
/// If the operation is one that applies a patch (which is any operation except
/// GIT_REBASE_OPERATION_EXEC) then the patch will be applied and the index and
/// working directory will be updated with the changes. If there are conflicts,
/// you will need to address those before committing the changes.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_rebase_operation> next(Pointer<git_rebase> rebase) {
  final operation = calloc<Pointer<git_rebase_operation>>();
  final error = libgit2.git_rebase_next(operation, rebase);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return operation.value;
  }
}

/// Commits the current patch. You must have resolved any conflicts that were
/// introduced during the patch application from the `next()` invocation.
///
/// Throws a [LibGit2Error] if error occured.
void commit({
  required Pointer<git_rebase> rebasePointer,
  required Pointer<git_signature>? authorPointer,
  required Pointer<git_signature> committerPointer,
  required String? message,
}) {
  final id = calloc<git_oid>();
  final messageC = message?.toNativeUtf8().cast<Int8>() ?? nullptr;

  final error = libgit2.git_rebase_commit(
    id,
    rebasePointer,
    authorPointer ?? nullptr,
    committerPointer,
    nullptr,
    messageC,
  );

  calloc.free(messageC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Finishes a rebase that is currently in progress once all patches have been applied.
///
/// Throws a [LibGit2Error] if error occured.
void finish(Pointer<git_rebase> rebase) {
  final error = libgit2.git_rebase_finish(rebase, nullptr);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Aborts a rebase that is currently in progress, resetting the repository and working
/// directory to their state before rebase began.
///
/// Throws a [LibGit2Error] if error occured.
void abort(Pointer<git_rebase> rebase) {
  final error = libgit2.git_rebase_abort(rebase);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Free memory allocated for rebase object.
void free(Pointer<git_rebase> rebase) => libgit2.git_rebase_free(rebase);