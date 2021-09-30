import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Tree tree;
  late Directory tmpDir;
  const treeSHA = 'a8ae3dd59e6e1802c6f78e05e301bfd57c9f334f';
  const fileSHA = '1377554ebea6f98a2c748183bc5a96852af12ac2';

  setUp(() async {
    tmpDir = await setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
    tree = Tree.lookup(repo: repo, sha: treeSHA);
  });

  tearDown(() async {
    tree.free();
    repo.free();
    await tmpDir.delete(recursive: true);
  });

  group('Tree', () {
    test('successfully initializes tree from provided Oid', () {
      expect(tree, isA<Tree>());
    });

    test('returns correct values', () {
      expect(tree.length, 4);
      expect(tree.entries.first.id.sha, fileSHA);
      expect(tree.entries[0].name, '.gitignore');
      expect(tree.entries[0].filemode, GitFilemode.blob);
    });

    test('returns tree entry with provided index position', () {
      expect(tree[0].id.sha, fileSHA);
    });

    test('throws when provided index position is outside of valid range', () {
      expect(() => tree[10], throwsA(isA<RangeError>()));
      expect(() => tree[-10], throwsA(isA<RangeError>()));
    });

    test('returns tree entry with provided filename', () {
      expect(tree['.gitignore'].id.sha, fileSHA);
    });

    test('throws when nothing found for provided filename', () {
      expect(() => tree['invalid'], throwsA(isA<ArgumentError>()));
    });

    test('returns tree entry with provided path to file', () {
      final entry = tree['dir/dir_file.txt'];
      expect(entry.id.sha, 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391');
      entry.free();
    });

    test('throws when nothing found for provided path', () {
      expect(() => tree['invalid/path'], throwsA(isA<LibGit2Error>()));
    });

    test('successfully creates tree', () {
      final fileOid = repo.createBlob('blob content');
      final builder = TreeBuilder(repo: repo);

      builder.add(
        filename: 'filename',
        oid: fileOid,
        filemode: GitFilemode.blob,
      );
      final newTree = Tree.lookup(repo: repo, sha: builder.write().sha);

      final entry = newTree['filename'];
      expect(newTree.length, 1);
      expect(entry.name, 'filename');
      expect(entry.filemode, GitFilemode.blob);
      expect(entry.id, fileOid);

      builder.free();
      entry.free();
      newTree.free();
    });
  });
}
