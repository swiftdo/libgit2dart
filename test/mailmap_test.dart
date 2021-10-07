import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  const testMailmap = """
# Simple Comment line
<cto@company.xx>                       <cto@coompany.xx>
Some Dude <some@dude.xx>         nick1 <bugs@company.xx>
Other Author <other@author.xx>    nick2 <bugs@company.xx>
Other Author <other@author.xx>         <nick2@company.xx>
Phil Hill <phil@company.xx>  # Comment at end of line
<joseph@company.xx>             Joseph <bugs@company.xx>
Santa Claus <santa.claus@northpole.xx> <me@company.xx>
""";

  const testEntries = [
    {
      'realName': null,
      'realEmail': "cto@company.xx",
      'name': null,
      'email': "cto@coompany.xx",
    },
    {
      'realName': "Some Dude",
      'realEmail': "some@dude.xx",
      'name': "nick1",
      'email': "bugs@company.xx",
    },
    {
      'realName': "Other Author",
      'realEmail': "other@author.xx",
      'name': "nick2",
      'email': "bugs@company.xx",
    },
    {
      'realName': "Other Author",
      'realEmail': "other@author.xx",
      'name': null,
      'email': "nick2@company.xx",
    },
    {
      'realName': "Phil Hill",
      'realEmail': null,
      'name': null,
      'email': "phil@company.xx",
    },
    {
      'realName': null,
      'realEmail': "joseph@company.xx",
      'name': "Joseph",
      'email': "bugs@company.xx",
    },
    {
      'realName': "Santa Claus",
      'realEmail': "santa.claus@northpole.xx",
      'name': null,
      'email': "me@company.xx",
    },
  ];

  const testResolve = [
    {
      'realName': "Brad",
      'realEmail': "cto@company.xx",
      'name': "Brad",
      'email': "cto@coompany.xx",
    },
    {
      'realName': "Brad L",
      'realEmail': "cto@company.xx",
      'name': "Brad L",
      'email': "cto@coompany.xx",
    },
    {
      'realName': "Some Dude",
      'realEmail': "some@dude.xx",
      'name': "nick1",
      'email': "bugs@company.xx",
    },
    {
      'realName': "Other Author",
      'realEmail': "other@author.xx",
      'name': "nick2",
      'email': "bugs@company.xx",
    },
    {
      'realName': "nick3",
      'realEmail': "bugs@company.xx",
      'name': "nick3",
      'email': "bugs@company.xx",
    },
    {
      'realName': "Other Author",
      'realEmail': "other@author.xx",
      'name': "Some Garbage",
      'email': "nick2@company.xx",
    },
    {
      'realName': "Phil Hill",
      'realEmail': "phil@company.xx",
      'name': "unknown",
      'email': "phil@company.xx",
    },
    {
      'realName': "Joseph",
      'realEmail': "joseph@company.xx",
      'name': "Joseph",
      'email': "bugs@company.xx",
    },
    {
      'realName': "Santa Claus",
      'realEmail': "santa.claus@northpole.xx",
      'name': "Clause",
      'email': "me@company.xx",
    },
    {
      'realName': "Charles",
      'realEmail': "charles@charles.xx",
      'name': "Charles",
      'email': "charles@charles.xx",
    },
  ];

  late Repository repo;
  late Directory tmpDir;

  setUp(() async {
    tmpDir = await setupRepo(Directory('test/assets/mailmaprepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() async {
    repo.free();
    await tmpDir.delete(recursive: true);
  });

  group('Mailmap', () {
    test('successfully initializes', () {
      final empty = Mailmap.empty();
      expect(empty, isA<Mailmap>());

      empty.free();
    });

    test('successfully initializes from provided buffer', () {
      final mailmap = Mailmap.fromBuffer(testMailmap);
      expect(mailmap, isA<Mailmap>());

      for (var entry in testResolve) {
        expect(
          mailmap.resolve(name: entry['name']!, email: entry['email']!),
          [entry['realName'], entry['realEmail']],
        );
      }

      mailmap.free();
    });

    test('successfully initializes from repository', () {
      final mailmap = Mailmap.fromRepository(repo);
      expect(mailmap, isA<Mailmap>());

      for (var entry in testResolve) {
        expect(
          mailmap.resolve(name: entry['name']!, email: entry['email']!),
          [entry['realName'], entry['realEmail']],
        );
      }

      mailmap.free();
    });

    test('successfully resolves names and emails when mailmap is empty', () {
      final mailmap = Mailmap.empty();

      for (var entry in testResolve) {
        expect(
          mailmap.resolve(name: entry['name']!, email: entry['email']!),
          [entry['name'], entry['email']],
        );
      }

      mailmap.free();
    });

    test('successfully adds entries and resolves them', () {
      final mailmap = Mailmap.empty();

      for (var entry in testEntries) {
        mailmap.addEntry(
          realName: entry['realName'],
          realEmail: entry['realEmail'],
          replaceName: entry['name'],
          replaceEmail: entry['email']!,
        );
      }

      for (var entry in testResolve) {
        expect(
          mailmap.resolve(name: entry['name']!, email: entry['email']!),
          [entry['realName'], entry['realEmail']],
        );
      }

      mailmap.free();
    });
  });
}