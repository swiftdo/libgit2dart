import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../error.dart';
import '../util.dart';
import 'libgit2_bindings.dart';

/// Get the type of a reference.
///
/// Either direct or symbolic.
int referenceType(Pointer<git_reference> ref) =>
    libgit2.git_reference_type(ref);

/// Get the OID pointed to by a direct reference.
///
/// Only available if the reference is direct (i.e. an object id reference, not a symbolic one).
Pointer<git_oid> target(Pointer<git_reference> ref) =>
    libgit2.git_reference_target(ref);

/// Resolve a symbolic reference to a direct reference.
///
/// This method iteratively peels a symbolic reference until it resolves
/// to a direct reference to an OID.
///
/// The peeled reference must be freed manually once it's no longer needed.
///
/// If a direct reference is passed as an argument, a copy of that reference is returned.
/// This copy must be manually freed too.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reference> resolve(Pointer<git_reference> ref) {
  final out = calloc<Pointer<git_reference>>();
  final error = libgit2.git_reference_resolve(out, ref);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Lookup a reference by name in a repository.
///
/// The returned reference must be freed by the user.
///
/// The name will be checked for validity.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reference> lookup({
  required Pointer<git_repository> repoPointer,
  required String name,
}) {
  final out = calloc<Pointer<git_reference>>();
  final nameC = name.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_reference_lookup(out, repoPointer, nameC);

  calloc.free(nameC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Get the full name of a reference.
String name(Pointer<git_reference> ref) {
  return libgit2.git_reference_name(ref).cast<Utf8>().toDartString();
}

/// Get the reference's short name.
///
/// This will transform the reference name into a name "human-readable" version.
/// If no shortname is appropriate, it will return the full name.
String shorthand(Pointer<git_reference> ref) {
  return libgit2.git_reference_shorthand(ref).cast<Utf8>().toDartString();
}

/// Rename an existing reference.
///
/// This method works for both direct and symbolic references.
///
/// The new name will be checked for validity.
///
/// If the force flag is not enabled, and there's already a reference with the given name,
/// the renaming will fail.
///
/// IMPORTANT: The user needs to write a proper reflog entry if the reflog is enabled for
/// the repository. We only rename the reflog if it exists.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reference> rename({
  required Pointer<git_reference> refPointer,
  required String newName,
  required bool force,
  String? logMessage,
}) {
  final out = calloc<Pointer<git_reference>>();
  final newNameC = newName.toNativeUtf8().cast<Int8>();
  final forceC = force == true ? 1 : 0;
  final logMessageC = logMessage?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final error = libgit2.git_reference_rename(
    out,
    refPointer,
    newNameC,
    forceC,
    logMessageC,
  );

  calloc.free(newNameC);
  calloc.free(logMessageC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Fill a list with all the references that can be found in a repository.
///
/// Throws a [LibGit2Error] if error occured.
List<String> list(Pointer<git_repository> repo) {
  var array = calloc<git_strarray>();
  final error = libgit2.git_reference_list(array, repo);
  var result = <String>[];

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    for (var i = 0; i < array.ref.count; i++) {
      result.add(
          array.ref.strings.elementAt(i).value.cast<Utf8>().toDartString());
    }
  }

  calloc.free(array);

  return result;
}

/// Check if a reflog exists for the specified reference.
bool hasLog({
  required Pointer<git_repository> repoPointer,
  required String name,
}) {
  final refname = name.toNativeUtf8().cast<Int8>();
  final result = libgit2.git_reference_has_log(repoPointer, refname);

  calloc.free(refname);

  return result == 1 ? true : false;
}

/// Check if a reference is a local branch.
bool isBranch(Pointer<git_reference> ref) {
  return libgit2.git_reference_is_branch(ref) == 1 ? true : false;
}

/// Check if a reference is a note.
bool isNote(Pointer<git_reference> ref) {
  return libgit2.git_reference_is_note(ref) == 1 ? true : false;
}

/// Check if a reference is a remote tracking branch.
bool isRemote(Pointer<git_reference> ref) {
  return libgit2.git_reference_is_remote(ref) == 1 ? true : false;
}

/// Check if a reference is a tag.
bool isTag(Pointer<git_reference> ref) {
  return libgit2.git_reference_is_tag(ref) == 1 ? true : false;
}

/// Create a new direct reference.
///
/// A direct reference (also called an object id reference) refers directly to a
/// specific object id (a.k.a. OID or SHA) in the repository. The id permanently refers to
/// the object (although the reference itself can be moved). For example, in libgit2
/// the direct ref "refs/tags/v0.17.0" refers to OID 5b9fac39d8a76b9139667c26a63e6b3f204b3977.
///
/// The direct reference will be created in the repository and written to the disk.
/// The generated reference object must be freed by the user.
///
/// Valid reference names must follow one of two patterns:
///
/// Top-level names must contain only capital letters and underscores, and must begin and end
/// with a letter. (e.g. "HEAD", "ORIG_HEAD").
/// Names prefixed with "refs/" can be almost anything. You must avoid the characters
/// '~', '^', ':', '\', '?', '[', and '*', and the sequences ".." and "@{" which have
/// special meaning to revparse.
/// This function will throw a [LibGit2Error] if a reference already exists with the given name
/// unless force is true, in which case it will be overwritten.
///
/// The message for the reflog will be ignored if the reference does not belong in the
/// standard set (HEAD, branches and remote-tracking branches) and it does not have a reflog.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reference> createDirect({
  required Pointer<git_repository> repoPointer,
  required String name,
  required Pointer<git_oid> oidPointer,
  required bool force,
  String? logMessage,
}) {
  final out = calloc<Pointer<git_reference>>();
  final nameC = name.toNativeUtf8().cast<Int8>();
  final forceC = force == true ? 1 : 0;
  final logMessageC = logMessage?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final error = libgit2.git_reference_create(
    out,
    repoPointer,
    nameC,
    oidPointer,
    forceC,
    logMessageC,
  );

  calloc.free(nameC);
  calloc.free(logMessageC);

  if (error < 0) {
    calloc.free(out);
    throw (LibGit2Error(libgit2.git_error_last()));
  } else {
    return out.value;
  }
}

/// Create a new symbolic reference.
///
/// A symbolic reference is a reference name that refers to another reference name.
/// If the other name moves, the symbolic name will move, too. As a simple example,
/// the "HEAD" reference might refer to "refs/heads/master" while on the "master" branch
/// of a repository.
///
/// The symbolic reference will be created in the repository and written to the disk.
/// The generated reference object must be freed by the user.
///
/// Valid reference names must follow one of two patterns:
///
/// Top-level names must contain only capital letters and underscores, and must begin and end
/// with a letter. (e.g. "HEAD", "ORIG_HEAD").
/// Names prefixed with "refs/" can be almost anything. You must avoid the characters
/// '~', '^', ':', '\', '?', '[', and '*', and the sequences ".." and "@{" which have special
/// meaning to revparse.
/// This function will throw an [LibGit2Error] if a reference already exists with the given
/// name unless force is true, in which case it will be overwritten.
///
/// The message for the reflog will be ignored if the reference does not belong in the standard
/// set (HEAD, branches and remote-tracking branches) and it does not have a reflog.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reference> createSymbolic({
  required Pointer<git_repository> repoPointer,
  required String name,
  required String target,
  required bool force,
  String? logMessage,
}) {
  final out = calloc<Pointer<git_reference>>();
  final nameC = name.toNativeUtf8().cast<Int8>();
  final targetC = target.toNativeUtf8().cast<Int8>();
  final forceC = force == true ? 1 : 0;
  final logMessageC = logMessage?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final error = libgit2.git_reference_symbolic_create(
    out,
    repoPointer,
    nameC,
    targetC,
    forceC,
    logMessageC,
  );

  calloc.free(nameC);
  calloc.free(targetC);
  calloc.free(logMessageC);

  if (error < 0) {
    calloc.free(out);
    throw (LibGit2Error(libgit2.git_error_last()));
  } else {
    return out.value;
  }
}

/// Delete an existing reference.
///
/// This method works for both direct and symbolic references.
/// The reference will be immediately removed on disk but the memory will not be freed.
void delete(Pointer<git_reference> ref) => libgit2.git_reference_delete(ref);

/// Get the repository where a reference resides.
Pointer<git_repository> owner(Pointer<git_reference> ref) {
  return libgit2.git_reference_owner(ref);
}

/// Conditionally create a new reference with the same name as the given reference
/// but a different OID target. The reference must be a direct reference, otherwise this will fail.
///
/// The new reference will be written to disk, overwriting the given reference.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reference> setTarget({
  required Pointer<git_reference> refPointer,
  required Pointer<git_oid> oidPointer,
  String? logMessage,
}) {
  final out = calloc<Pointer<git_reference>>();
  final logMessageC = logMessage?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final error = libgit2.git_reference_set_target(
    out,
    refPointer,
    oidPointer,
    logMessageC,
  );

  calloc.free(logMessageC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Create a new reference with the same name as the given reference but a different
/// symbolic target. The reference must be a symbolic reference, otherwise this will fail.
///
/// The new reference will be written to disk, overwriting the given reference.
///
/// The target name will be checked for validity.
///
/// The message for the reflog will be ignored if the reference does not belong in the
/// standard set (HEAD, branches and remote-tracking branches) and and it does not have a reflog.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reference> setTargetSymbolic({
  required Pointer<git_reference> refPointer,
  required String target,
  String? logMessage,
}) {
  final out = calloc<Pointer<git_reference>>();
  final targetC = target.toNativeUtf8().cast<Int8>();
  final logMessageC = logMessage?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final error = libgit2.git_reference_symbolic_set_target(
    out,
    refPointer,
    targetC,
    logMessageC,
  );

  calloc.free(targetC);
  calloc.free(logMessageC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Compare two references.
bool compare({
  required Pointer<git_reference> ref1Pointer,
  required Pointer<git_reference> ref2Pointer,
}) {
  return libgit2.git_reference_cmp(ref1Pointer, ref2Pointer) == 0
      ? true
      : false;
}

/// Recursively peel reference until object of the specified type is found.
///
/// The retrieved peeled object is owned by the repository and should be closed to release memory.
///
/// If you pass GIT_OBJECT_ANY as the target type, then the object will be peeled until a
/// non-tag object is met.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_object> peel({
  required Pointer<git_reference> refPointer,
  required int type,
}) {
  final out = calloc<Pointer<git_object>>();
  final error = libgit2.git_reference_peel(out, refPointer, type);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Free the given reference.
void free(Pointer<git_reference> ref) => libgit2.git_reference_free(ref);
