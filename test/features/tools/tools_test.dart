import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_studio/features/tools/duplicate_finder.dart';
import 'package:file_studio/features/tools/hash_calculator.dart';

void main() {
  group('DuplicateFinder Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('file_studio_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('detects duplicate files with identical content', () async {
      final file1 = File('${tempDir.path}/a.txt');
      final file2 = File('${tempDir.path}/b.txt');
      final file3 = File('${tempDir.path}/c.txt');

      await file1.writeAsString('नमस्ते फाइल स्टूडियो');
      await file2.writeAsString('नमस्ते फाइल स्टूडियो'); // duplicate
      await file3.writeAsString('अलग सामग्री'); // unique

      final duplicates = await DuplicateFinder.scanFiles([file1, file2, file3]);

      expect(duplicates.length, equals(1));
      expect(duplicates.first.files.length, equals(2));
      expect(duplicates.first.wastedBytes, greaterThan(0));
    });

    test('ignores unique files', () async {
      final file1 = File('${tempDir.path}/x.txt');
      final file2 = File('${tempDir.path}/y.txt');

      await file1.writeAsString('File 1 content');
      await file2.writeAsString('File 2 different content');

      final duplicates = await DuplicateFinder.scanFiles([file1, file2]);
      expect(duplicates, isEmpty);
    });
  });

  group('HashResult Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hash_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('computes valid hashes', () async {
      final file = File('${tempDir.path}/hello.txt');
      await file.writeAsString('hello world');

      final result = await HashResult.compute(file);

      // Known sha256 for "hello world" is b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9
      expect(result.sha256Hash, equals('b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9'));
      // Known md5 for "hello world" is 5eb63bbbe01eeed093cb22bb8f5acdc3
      expect(result.md5Hash, equals('5eb63bbbe01eeed093cb22bb8f5acdc3'));
      expect(result.fileSizeBytes, equals(11));
    });
  });
}

