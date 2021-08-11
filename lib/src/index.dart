import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/index.dart' as bindings;
import 'oid.dart';
import 'types.dart';
import 'util.dart';

class Index {
  /// Initializes a new instance of [Index] class from provided
  /// pointer to index object in memory.
  ///
  /// Should be freed with `free()` to release allocated memory.
  Index(this._indexPointer) {
    libgit2.git_libgit2_init();
  }

  /// Pointer to memory address for allocated index object.
  late final Pointer<git_index> _indexPointer;

  /// Returns index entry located at provided 0-based position or string path.
  ///
  /// Throws error if position is out of bounds or entry isn't found at path.
  IndexEntry operator [](Object value) {
    if (value is int) {
      return IndexEntry(bindings.getByIndex(_indexPointer, value));
    } else {
      return IndexEntry(bindings.getByPath(_indexPointer, value as String, 0));
    }
  }

  /// Checks whether entry at provided [path] is in the git index or not.
  bool contains(String path) => bindings.find(_indexPointer, path);

  /// Returns the count of entries currently in the index.
  int get count => bindings.entryCount(_indexPointer);

  /// Clears the contents (all the entries) of an index object.
  ///
  /// This clears the index object in memory; changes must be explicitly written to
  /// disk for them to take effect persistently.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void clear() => bindings.clear(_indexPointer);

  /// Adds or updates an index entry from an [IndexEntry] or from a file on disk.
  ///
  /// If a previous index entry exists that has the same path and stage as the given `entry`,
  /// it will be replaced. Otherwise, the `entry` will be added.
  ///
  /// The file path must be relative to the repository's working folder and must be readable.
  ///
  /// This method will fail in bare index instances.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void add(Object entry) {
    if (entry is IndexEntry) {
      bindings.add(_indexPointer, entry._indexEntryPointer);
    } else {
      bindings.addByPath(_indexPointer, entry as String);
    }
  }

  /// Adds or updates index entries matching files in the working directory.
  ///
  /// This method will fail in bare index instances.
  ///
  /// The `pathspec` is a list of file names or shell glob patterns that will be matched
  /// against files in the repository's working directory. Each file that matches will be
  /// added to the index (either updating an existing entry or adding a new entry).
  ///
  /// Throws a [LibGit2Error] if error occured.
  void addAll(List<String> pathspec) {
    bindings.addAll(_indexPointer, pathspec);
  }

  /// Updates the contents of an existing index object in memory by reading from the hard disk.
  ///
  /// If force is true (default), this performs a "hard" read that discards in-memory changes and
  /// always reloads the on-disk index data. If there is no on-disk version,
  /// the index will be cleared.
  ///
  /// If force is false, this does a "soft" read that reloads the index data from disk only
  /// if it has changed since the last time it was loaded. Purely in-memory index data
  /// will be untouched. Be aware: if there are changes on disk, unwritten in-memory changes
  /// are discarded.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void read({bool force = true}) => bindings.read(_indexPointer, force);

  /// Writes an existing index object from memory back to disk using an atomic file lock.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void write() => bindings.write(_indexPointer);

  /// Removes an entry from the index.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void remove(String path, [int stage = 0]) =>
      bindings.remove(_indexPointer, path, stage);

  /// Remove all matching index entries.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void removeAll(List<String> path) => bindings.removeAll(_indexPointer, path);

  /// Releases memory allocated for index object.
  void free() {
    bindings.free(_indexPointer);
    libgit2.git_libgit2_shutdown();
  }
}

class IndexEntry {
  /// Initializes a new instance of [IndexEntry] class.
  IndexEntry(this._indexEntryPointer);

  /// Pointer to memory address for allocated index entry object.
  late final Pointer<git_index_entry> _indexEntryPointer;

  /// Unique identity of the index entry.
  Oid get id => Oid.fromSHA(sha);

  set id(Oid oid) => _indexEntryPointer.ref.id = oid.pointer.ref;

  /// Path of the index entry.
  String get path => _indexEntryPointer.ref.path.cast<Utf8>().toDartString();

  set path(String path) =>
      _indexEntryPointer.ref.path = path.toNativeUtf8().cast<Int8>();

  /// Returns id of the index entry as sha-1 hex.
  String get sha => _oidToHex(_indexEntryPointer.ref.id);

  GitFilemode get mode {
    switch (_indexEntryPointer.ref.mode) {
      case 0:
        return GitFilemode.undreadable;
      case 16384:
        return GitFilemode.tree;
      case 33188:
        return GitFilemode.blob;
      case 33261:
        return GitFilemode.blobExecutable;
      case 40960:
        return GitFilemode.link;
      case 57344:
        return GitFilemode.commit;
      default:
        return GitFilemode.undreadable;
    }
  }

  set mode(GitFilemode mode) {
    switch (mode) {
      case GitFilemode.undreadable:
        _indexEntryPointer.ref.mode = 0;
        break;
      case GitFilemode.tree:
        _indexEntryPointer.ref.mode = 16384;
        break;
      case GitFilemode.blob:
        _indexEntryPointer.ref.mode = 33188;
        break;
      case GitFilemode.blobExecutable:
        _indexEntryPointer.ref.mode = 33261;
        break;
      case GitFilemode.link:
        _indexEntryPointer.ref.mode = 40960;
        break;
      case GitFilemode.commit:
        _indexEntryPointer.ref.mode = 57344;
        break;
    }
  }

  String _oidToHex(git_oid oid) {
    var hex = StringBuffer();
    for (var i = 0; i < 20; i++) {
      hex.write(oid.id[i].toRadixString(16));
    }
    return hex.toString();
  }
}