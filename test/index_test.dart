import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Index index;
  late Directory tmpDir;

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
    index = repo.index;
  });

  tearDown(() {
    index.free();
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Index', () {
    const fileSha = 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391';
    const featureFileSha = '9c78c21d6680a7ffebc76f7ac68cacc11d8f48bc';

    test('returns number of entries', () {
      expect(index.length, 4);
    });

    test('returns mode of index entry', () {
      for (final entry in index) {
        expect(entry.mode, GitFilemode.blob);
      }
    });

    test('returns index entry at provided position', () {
      expect(index[3].path, 'file');
      expect(index[3].sha, fileSha);
    });

    test('returns index entry at provided path', () {
      expect(index['file'].path, 'file');
      expect(index['file'].sha, fileSha);
    });

    test('throws if provided entry position is out of bounds', () {
      expect(() => index[10], throwsA(isA<RangeError>()));
    });

    test('throws if provided entry path is not found', () {
      expect(() => index[10], throwsA(isA<ArgumentError>()));
    });

    test('successfully changes attributes', () {
      final entry = index['file'];
      final otherEntry = index['feature_file'];

      expect(entry.oid == otherEntry.oid, false);
      expect(entry.mode, isNot(GitFilemode.blobExecutable));

      entry.path = 'some.txt';
      entry.oid = otherEntry.oid;
      entry.mode = GitFilemode.blobExecutable;

      expect(entry.path, 'some.txt');
      expect(entry.oid == otherEntry.oid, true);
      expect(entry.mode, GitFilemode.blobExecutable);
    });

    test('clears the contents', () {
      expect(index.length, 4);
      index.clear();
      expect(index.length, 0);
    });

    group('add()', () {
      test('successfully adds with provided IndexEntry', () {
        final entry = index['file'];

        index.add(entry);
        expect(index['file'].sha, fileSha);
        expect(index.length, 4);
      });

      test('successfully adds with provided path string', () {
        index.add('file');
        expect(index['file'].sha, fileSha);
        expect(index.length, 4);
      });

      test('throws if file not found at provided path', () {
        expect(() => index.add('not_there'), throwsA(isA<LibGit2Error>()));
      });

      test('throws if index of bare repository', () {
        final bare = Repository.open('test/assets/empty_bare.git');
        final bareIndex = bare.index;

        expect(() => bareIndex.add('config'), throwsA(isA<LibGit2Error>()));

        bareIndex.free();
        bare.free();
      });
    });

    group('addAll()', () {
      test('successfully adds with provided pathspec', () {
        index.clear();
        index.addAll(['file', 'feature_file']);

        expect(index.length, 2);
        expect(index['file'].sha, fileSha);
        expect(index['feature_file'].sha, featureFileSha);

        index.clear();
        index.addAll(['[f]*']);

        expect(index.length, 2);
        expect(index['file'].sha, fileSha);
        expect(index['feature_file'].sha, featureFileSha);

        index.clear();
        index.addAll(['feature_f???']);

        expect(index.length, 1);
        expect(index['feature_file'].sha, featureFileSha);
      });
    });

    test('writes to disk', () {
      expect(index.length, 4);

      File('${tmpDir.path}/new_file').createSync();

      index.add('new_file');
      index.write();

      index.clear();
      index.read();
      expect(index['new_file'].path, 'new_file');
      expect(index.length, 5);
    });

    test('removes an entry', () {
      expect(index.find('feature_file'), true);
      index.remove('feature_file');
      expect(index.find('feature_file'), false);
    });

    test('removes all entries with matching pathspec', () {
      expect(index.find('file'), true);
      expect(index.find('feature_file'), true);

      index.removeAll(['[f]*']);

      expect(index.find('file'), false);
      expect(index.find('feature_file'), false);
    });

    test('successfully reads tree with provided SHA hex', () {
      final tree = repo.lookupTree(
        repo['df2b8fc99e1c1d4dbc0a854d9f72157f1d6ea078'],
      );
      expect(index.length, 4);
      index.readTree(tree);

      expect(index.length, 1);

      // make sure the index is only modified in memory
      index.read();
      expect(index.length, 4);
    });

    test('successfully writes tree', () {
      final oid = index.writeTree();
      expect(oid.sha, 'a8ae3dd59e6e1802c6f78e05e301bfd57c9f334f');
    });

    test('returns conflicts with ancestor, our and their present', () {
      final repoDir = setupRepo(Directory('test/assets/mergerepo/'));
      final conflictRepo = Repository.open(repoDir.path);

      final conflictBranch = conflictRepo.lookupBranch('ancestor-conflict');

      conflictRepo.checkout(refName: 'refs/heads/feature');

      conflictRepo.merge(conflictBranch.target);

      final index = conflictRepo.index;
      final conflictedFile = index.conflicts['feature_file']!;
      expect(conflictedFile.ancestor?.path, 'feature_file');
      expect(conflictedFile.our?.path, 'feature_file');
      expect(conflictedFile.their?.path, 'feature_file');
      expect(conflictedFile.toString(), contains('ConflictEntry{'));

      index.free();
      conflictBranch.free();
      conflictRepo.free();
      repoDir.deleteSync(recursive: true);
    });

    test('returns conflicts with our and their present and null ancestor', () {
      final repoDir = setupRepo(Directory('test/assets/mergerepo/'));
      final conflictRepo = Repository.open(repoDir.path);

      final conflictBranch = conflictRepo.lookupBranch('conflict-branch');

      conflictRepo.merge(conflictBranch.target);

      final index = conflictRepo.index;
      final conflictedFile = index.conflicts['conflict_file']!;
      expect(conflictedFile.ancestor?.path, null);
      expect(conflictedFile.our?.path, 'conflict_file');
      expect(conflictedFile.their?.path, 'conflict_file');
      expect(conflictedFile.toString(), contains('ConflictEntry{'));

      index.free();
      conflictBranch.free();
      conflictRepo.free();
      repoDir.deleteSync(recursive: true);
    });

    test('returns conflicts with ancestor and their present and null our', () {
      final repoDir = setupRepo(Directory('test/assets/mergerepo/'));
      final conflictRepo = Repository.open(repoDir.path);

      final conflictBranch = conflictRepo.lookupBranch('ancestor-conflict');

      conflictRepo.checkout(refName: 'refs/heads/our-conflict');

      conflictRepo.merge(conflictBranch.target);

      final index = conflictRepo.index;
      final conflictedFile = index.conflicts['feature_file']!;
      expect(conflictedFile.ancestor?.path, 'feature_file');
      expect(conflictedFile.our?.path, null);
      expect(conflictedFile.their?.path, 'feature_file');
      expect(conflictedFile.toString(), contains('ConflictEntry{'));

      index.free();
      conflictBranch.free();
      conflictRepo.free();
      repoDir.deleteSync(recursive: true);
    });

    test('returns conflicts with ancestor and our present and null their', () {
      final repoDir = setupRepo(Directory('test/assets/mergerepo/'));
      final conflictRepo = Repository.open(repoDir.path);

      final conflictBranch = conflictRepo.lookupBranch('their-conflict');

      conflictRepo.checkout(refName: 'refs/heads/feature');

      conflictRepo.merge(conflictBranch.target);

      final index = conflictRepo.index;
      final conflictedFile = index.conflicts['feature_file']!;
      expect(conflictedFile.ancestor?.path, 'feature_file');
      expect(conflictedFile.our?.path, 'feature_file');
      expect(conflictedFile.their?.path, null);
      expect(conflictedFile.toString(), contains('ConflictEntry{'));

      index.free();
      conflictBranch.free();
      conflictRepo.free();
      repoDir.deleteSync(recursive: true);
    });

    test('returns string representation of Index and IndexEntry objects', () {
      final index = repo.index;

      expect(index.toString(), contains('Index{'));
      expect(index['file'].toString(), contains('IndexEntry{'));

      index.free();
    });
  });
}
