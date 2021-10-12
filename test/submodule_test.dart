import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const testSubmodule = 'TestGitRepository';
  const submoduleUrl = 'https://github.com/libgit2/TestGitRepository';
  const submoduleHeadSha = '49322bb17d3acc9146f98c97d078513228bbf3c0';

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/submodulerepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Submodule', () {
    test('returns list of all submodules paths', () {
      expect(repo.submodules.length, 1);
      expect(repo.submodules.first, testSubmodule);
    });

    test('successfully finds submodule with provided name/path', () {
      final submodule = repo.lookupSubmodule(testSubmodule);

      expect(submodule.name, testSubmodule);
      expect(submodule.path, testSubmodule);
      expect(submodule.url, submoduleUrl);
      expect(submodule.branch, '');
      expect(submodule.headId?.sha, submoduleHeadSha);
      expect(submodule.indexId?.sha, submoduleHeadSha);
      expect(submodule.workdirId?.sha, null);
      expect(submodule.ignore, GitSubmoduleIgnore.none);
      expect(submodule.updateRule, GitSubmoduleUpdate.checkout);

      submodule.free();
    });

    test('successfully inits and updates', () {
      final submoduleFilePath = '${repo.workdir}$testSubmodule/master.txt';
      expect(File(submoduleFilePath).existsSync(), false);

      repo.initSubmodule(submodule: testSubmodule);
      repo.updateSubmodule(submodule: testSubmodule);

      expect(File(submoduleFilePath).existsSync(), true);
    });

    test('successfully updates with provided init flag', () {
      final submoduleFilePath = '${repo.workdir}$testSubmodule/master.txt';
      expect(File(submoduleFilePath).existsSync(), false);

      repo.updateSubmodule(submodule: testSubmodule, init: true);

      expect(File(submoduleFilePath).existsSync(), true);
    });

    test('successfully opens repository for a submodule', () {
      final submodule = repo.lookupSubmodule(testSubmodule);
      repo.initSubmodule(submodule: testSubmodule);
      repo.updateSubmodule(submodule: testSubmodule);

      final submoduleRepo = submodule.open();
      final subHead = submoduleRepo.head;
      expect(submoduleRepo, isA<Repository>());
      expect(subHead.target.sha, submoduleHeadSha);

      subHead.free();
      submoduleRepo.free();
      submodule.free();
    });

    test('successfully adds submodule', () {
      final submodule = repo.addSubmodule(
        url: submoduleUrl,
        path: 'test',
      );
      final submoduleRepo = submodule.open();

      expect(submodule.path, 'test');
      expect(submodule.url, submoduleUrl);
      expect(submoduleRepo.isEmpty, false);

      submoduleRepo.free();
      submodule.free();
    });

    test('successfully sets configuration values', () {
      final submodule = repo.lookupSubmodule(testSubmodule);
      expect(submodule.url, submoduleUrl);
      expect(submodule.branch, '');
      expect(submodule.ignore, GitSubmoduleIgnore.none);
      expect(submodule.updateRule, GitSubmoduleUpdate.checkout);

      submodule.url = 'updated';
      submodule.branch = 'updated';
      submodule.ignore = GitSubmoduleIgnore.all;
      submodule.updateRule = GitSubmoduleUpdate.rebase;

      final updatedSubmodule = repo.lookupSubmodule(testSubmodule);
      expect(updatedSubmodule.url, 'updated');
      expect(updatedSubmodule.branch, 'updated');
      expect(updatedSubmodule.ignore, GitSubmoduleIgnore.all);
      expect(updatedSubmodule.updateRule, GitSubmoduleUpdate.rebase);

      updatedSubmodule.free();
      submodule.free();
    });

    test('successfully syncs', () {
      repo.updateSubmodule(submodule: testSubmodule, init: true);
      final submodule = repo.lookupSubmodule(testSubmodule);
      final submRepo = submodule.open();
      final repoConfig = repo.config;
      final submRepoConfig = submRepo.config;

      expect(repoConfig['submodule.$testSubmodule.url'].value, submoduleUrl);
      expect(submRepoConfig['remote.origin.url'].value, submoduleUrl);

      submodule.url = 'https://updated.com/';
      submodule.branch = 'updated';

      final updatedSubmodule = repo.lookupSubmodule(testSubmodule);
      updatedSubmodule.sync();
      final updatedSubmRepo = updatedSubmodule.open();
      final updatedSubmRepoConfig = updatedSubmRepo.config;

      expect(
        repoConfig['submodule.$testSubmodule.url'].value,
        'https://updated.com/',
      );
      expect(
        updatedSubmRepoConfig['remote.origin.url'].value,
        'https://updated.com/',
      );

      updatedSubmRepoConfig.free();
      submRepo.free();
      updatedSubmRepo.free();
      updatedSubmodule.free();
      submRepoConfig.free();
      repoConfig.free();
      submodule.free();
    });

    test('successfully reloads info', () {
      final submodule = repo.lookupSubmodule(testSubmodule);
      expect(submodule.url, submoduleUrl);

      submodule.url = 'updated';
      submodule.reload();

      expect(submodule.url, 'updated');

      submodule.free();
    });

    test('returns status for a submodule', () {
      final submodule = repo.lookupSubmodule(testSubmodule);
      expect(
        submodule.status(),
        {
          GitSubmoduleStatus.inHead,
          GitSubmoduleStatus.inIndex,
          GitSubmoduleStatus.inConfig,
          GitSubmoduleStatus.workdirUninitialized,
        },
      );

      repo.updateSubmodule(submodule: testSubmodule, init: true);
      expect(
        submodule.status(),
        {
          GitSubmoduleStatus.inHead,
          GitSubmoduleStatus.inIndex,
          GitSubmoduleStatus.inConfig,
          GitSubmoduleStatus.inWorkdir,
          GitSubmoduleStatus.workdirUntracked,
        },
      );

      expect(
        submodule.status(ignore: GitSubmoduleIgnore.all),
        {
          GitSubmoduleStatus.inHead,
          GitSubmoduleStatus.inIndex,
          GitSubmoduleStatus.inConfig,
          GitSubmoduleStatus.inWorkdir,
        },
      );

      submodule.free();
    });
  });
}