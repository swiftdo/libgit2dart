import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Read the reflog for the given reference.
///
/// If there is no reflog file for the given reference yet, an empty reflog
/// object will be returned.
///
/// The reflog must be freed manually.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reflog> read({
  required Pointer<git_repository> repoPointer,
  required String name,
}) {
  final out = calloc<Pointer<git_reflog>>();
  final nameC = name.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_reflog_read(out, repoPointer, nameC);

  calloc.free(nameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Get the number of log entries in a reflog.
int entryCount(Pointer<git_reflog> reflog) =>
    libgit2.git_reflog_entrycount(reflog);

/// Lookup an entry by its index.
///
/// Requesting the reflog entry with an index of 0 (zero) will return
/// the most recently created entry.
Pointer<git_reflog_entry> getByIndex({
  required Pointer<git_reflog> reflogPointer,
  required int index,
}) {
  return libgit2.git_reflog_entry_byindex(reflogPointer, index);
}

/// Get the log message.
String entryMessage(Pointer<git_reflog_entry> entry) {
  final result = libgit2.git_reflog_entry_message(entry);
  return result.cast<Utf8>().toDartString();
}

/// Get the committer of this entry.
Pointer<git_signature> entryCommiter(Pointer<git_reflog_entry> entry) {
  return libgit2.git_reflog_entry_committer(entry);
}

/// Free the reflog.
void free(Pointer<git_reflog> reflog) => libgit2.git_reflog_free(reflog);
