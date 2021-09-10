import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  const mergeCommit = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8';

  late Repository repo;
  final tmpDir = '${Directory.systemTemp.path}/commit_testrepo/';

  const message = "Commit message.\n\nSome description.\n";
  const tree = '7796359a96eb722939c24bafdb1afe9f07f2f628';
  late Signature author;
  late Signature commiter;

  setUp(() async {
    if (await Directory(tmpDir).exists()) {
      await Directory(tmpDir).delete(recursive: true);
    }
    await copyRepo(
      from: Directory('test/assets/testrepo/'),
      to: await Directory(tmpDir).create(),
    );
    repo = Repository.open(tmpDir);
    author = Signature.create(
      name: 'Author Name',
      email: 'author@email.com',
      time: 123,
    );
    commiter = Signature.create(
      name: 'Commiter',
      email: 'commiter@email.com',
      time: 124,
    );
  });

  tearDown(() async {
    author.free();
    commiter.free();
    repo.free();
    await Directory(tmpDir).delete(recursive: true);
  });

  group('Commit', () {
    test('successfully returns when 40 char sha hex is provided', () {
      final commit = repo[mergeCommit] as Commit;
      expect(commit, isA<Commit>());
      commit.free();
    });

    test('successfully returns when sha hex is short', () {
      final commit = repo[mergeCommit.substring(0, 5)] as Commit;
      expect(commit, isA<Commit>());
      commit.free();
    });

    test('successfully creates commit', () {
      final oid = Commit.create(
        repo: repo,
        message: message,
        author: author,
        commiter: commiter,
        treeSHA: tree,
        parents: [mergeCommit],
      );

      final commit = repo[oid.sha] as Commit;

      expect(commit.id.sha, oid.sha);
      expect(commit.message, message);
      expect(commit.messageEncoding, 'utf-8');
      expect(commit.author, author);
      expect(commit.committer, commiter);
      expect(commit.time, 124);
      expect(commit.tree.id.sha, tree);
      expect(commit.parents.length, 1);
      expect(commit.parents[0].sha, mergeCommit);

      commit.free();
    }, skip: 'skipped because of flaky segfaults');

    test('successfully creates commit without parents', () {
      final oid = Commit.create(
        repo: repo,
        message: message,
        author: author,
        commiter: commiter,
        treeSHA: tree,
        parents: [],
      );

      final commit = repo[oid.sha] as Commit;

      expect(commit.id.sha, oid.sha);
      expect(commit.message, message);
      expect(commit.messageEncoding, 'utf-8');
      expect(commit.author, author);
      expect(commit.committer, commiter);
      expect(commit.time, 124);
      expect(commit.tree.id.sha, tree);
      expect(commit.parents.length, 0);

      commit.free();
    }, skip: 'skipped because of flaky segfaults');

    test('successfully creates commit with 2 parents', () {
      final oid = Commit.create(
        repo: repo,
        message: message,
        author: author,
        commiter: commiter,
        treeSHA: tree,
        parents: [mergeCommit, 'fc38877b2552ab554752d9a77e1f48f738cca79b'],
      );

      final commit = repo[oid.sha] as Commit;

      expect(commit.id.sha, oid.sha);
      expect(commit.message, message);
      expect(commit.messageEncoding, 'utf-8');
      expect(commit.author, author);
      expect(commit.committer, commiter);
      expect(commit.time, 124);
      expect(commit.tree.id.sha, tree);
      expect(commit.parents.length, 2);
      expect(commit.parents[0].sha, mergeCommit);
      expect(commit.parents[1].sha, 'fc38877b2552ab554752d9a77e1f48f738cca79b');

      commit.free();
    }, skip: 'skipped because of flaky segfaults');

    test('successfully creates commit with short sha of tree', () {
      final oid = Commit.create(
        repo: repo,
        message: message,
        author: author,
        commiter: commiter,
        treeSHA: tree.substring(0, 5),
        parents: [mergeCommit],
      );

      final commit = repo[oid.sha] as Commit;

      expect(commit.id.sha, oid.sha);
      expect(commit.message, message);
      expect(commit.messageEncoding, 'utf-8');
      expect(commit.author, author);
      expect(commit.committer, commiter);
      expect(commit.time, 124);
      expect(commit.tree.id.sha, tree);
      expect(commit.parents.length, 1);
      expect(commit.parents[0].sha, mergeCommit);

      commit.free();
    }, skip: 'skipped because of flaky segfaults');
  });
}
