import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Tree tree;
  late Directory tmpDir;

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
    tree = repo.lookupTree(repo['a8ae3dd59e6e1802c6f78e05e301bfd57c9f334f']);
  });

  tearDown(() {
    tree.free();
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('TreeBuilder', () {
    test('successfully initializes tree builder when no tree is provided', () {
      final builder = TreeBuilder(repo: repo);
      expect(builder, isA<TreeBuilder>());
      expect(builder.toString(), contains('TreeBuilder{'));
      builder.free();
    });

    test('successfully initializes tree builder with provided tree', () {
      final builder = TreeBuilder(repo: repo, tree: tree);
      final oid = builder.write();

      expect(builder, isA<TreeBuilder>());
      expect(builder.length, tree.length);
      expect(oid, tree.oid);

      builder.free();
    });

    test('clears all the entries in the builder', () {
      final builder = TreeBuilder(repo: repo, tree: tree);

      expect(builder.length, 4);
      builder.clear();
      expect(builder.length, 0);

      builder.free();
    });

    test('successfully builds the tree builder from entry of tree', () {
      final builder = TreeBuilder(repo: repo);
      final entry = tree.entries[0];

      expect(() => builder[entry.name], throwsA(isA<ArgumentError>()));

      builder.add(
        filename: entry.name,
        oid: entry.oid,
        filemode: entry.filemode,
      );
      expect(builder[entry.name].name, entry.name);

      builder.free();
    });

    test('successfully removes an entry', () {
      final builder = TreeBuilder(repo: repo, tree: tree);

      expect(builder.length, tree.length);

      builder.remove('.gitignore');
      expect(() => builder['.gitignore'], throwsA(isA<ArgumentError>()));
      expect(builder.length, tree.length - 1);

      builder.free();
    });
  });
}
