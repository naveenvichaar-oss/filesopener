import 'dart:io';
import 'package:crypto/crypto.dart';

/// Represents a set of files that share identical content (identical hash).
class DuplicateGroup {
  final String sha256Hash;
  final int fileSizeBytes;
  final List<File> files;

  const DuplicateGroup({
    required this.sha256Hash,
    required this.fileSizeBytes,
    required this.files,
  });

  /// Total wasted storage bytes (excluding 1 original copy).
  int get wastedBytes => fileSizeBytes * (files.length - 1);
}

/// Utility for scanning and identifying duplicate files across a directory or file list.
class DuplicateFinder {
  /// Scans a directory and returns all groups of duplicate files.
  static Future<List<DuplicateGroup>> scanDirectory(
    Directory dir, {
    bool recursive = true,
  }) async {
    final List<File> allFiles = [];
    try {
      await for (final entity in dir.list(recursive: recursive, followLinks: false)) {
        if (entity is File) {
          allFiles.add(entity);
        }
      }
    } catch (_) {}

    return scanFiles(allFiles);
  }

  /// Scans a given list of files and identifies duplicates.
  static Future<List<DuplicateGroup>> scanFiles(List<File> files) async {
    // 1. Group by file length first (fast O(N) pre-filter)
    final Map<int, List<File>> sizeBuckets = {};

    for (final f in files) {
      try {
        final len = await f.length();
        if (len == 0) continue; // Skip 0-byte files
        sizeBuckets.putIfAbsent(len, () => []).add(f);
      } catch (_) {}
    }

    // 2. Hash files only when multiple files have identical lengths
    final List<DuplicateGroup> duplicates = [];

    for (final entry in sizeBuckets.entries) {
      if (entry.value.length < 2) continue;

      final Map<String, List<File>> hashBuckets = {};

      for (final file in entry.value) {
        try {
          final hash = await _computeSha256(file);
          hashBuckets.putIfAbsent(hash, () => []).add(file);
        } catch (_) {}
      }

      for (final hashEntry in hashBuckets.entries) {
        if (hashEntry.value.length > 1) {
          duplicates.add(DuplicateGroup(
            sha256Hash: hashEntry.key,
            fileSizeBytes: entry.key,
            files: hashEntry.value,
          ));
        }
      }
    }

    // Sort by largest wasted space first
    duplicates.sort((a, b) => b.wastedBytes.compareTo(a.wastedBytes));
    return duplicates;
  }

  static Future<String> _computeSha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }
}

