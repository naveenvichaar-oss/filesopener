import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hash calculation result for a file.
class HashResult {
  final String md5Hash;
  final String sha1Hash;
  final String sha256Hash;
  final String sha512Hash;
  final int fileSizeBytes;

  const HashResult({
    required this.md5Hash,
    required this.sha1Hash,
    required this.sha256Hash,
    required this.sha512Hash,
    required this.fileSizeBytes,
  });

  static Future<HashResult> compute(File file) async {
    final bytes = await file.readAsBytes();
    final md5Val = md5.convert(bytes).toString();
    final sha1Val = sha1.convert(bytes).toString();
    final sha256Val = sha256.convert(bytes).toString();
    final sha512Val = sha512.convert(bytes).toString();
    return HashResult(
      md5Hash: md5Val,
      sha1Hash: sha1Val,
      sha256Hash: sha256Val,
      sha512Hash: sha512Val,
      fileSizeBytes: bytes.length,
    );
  }
}

/// A modal bottom sheet / dialog to inspect and verify file checksums.
class HashCalculatorSheet extends StatefulWidget {
  final File file;
  final String fileName;

  const HashCalculatorSheet({
    super.key,
    required this.file,
    required this.fileName,
  });

  @override
  State<HashCalculatorSheet> createState() => _HashCalculatorSheetState();
}

class _HashCalculatorSheetState extends State<HashCalculatorSheet> {
  HashResult? _result;
  bool _loading = true;
  String? _error;
  final _compareController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _computeHashes();
  }

  @override
  void dispose() {
    _compareController.dispose();
    super.dispose();
  }

  Future<void> _computeHashes() async {
    try {
      final res = await HashResult.compute(widget.file);
      if (mounted) {
        setState(() {
          _result = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = _compareController.text.trim().toLowerCase();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: Colors.indigo),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'चेकसम व हैश सत्यापन (${widget.fileName})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('त्रुटि: $_error', style: const TextStyle(color: Colors.red)),
            )
          else if (_result != null) ...[
            TextField(
              controller: _compareController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'तुलना के लिए अपेक्षित हैश दर्ज करें',
                hintText: 'अपेक्षित MD5 या SHA-256 यहाँ पेस्ट करें...',
                prefixIcon: Icon(Icons.compare_arrows),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            _buildHashTile('SHA-256', _result!.sha256Hash, target),
            _buildHashTile('MD5', _result!.md5Hash, target),
            _buildHashTile('SHA-1', _result!.sha1Hash, target),
            _buildHashTile('SHA-512', _result!.sha512Hash, target),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHashTile(String label, String value, String target) {
    final matches = target.isNotEmpty && target == value.toLowerCase();
    final mismatch = target.isNotEmpty && target.length == value.length && target != value.toLowerCase();

    Color? bg;
    if (matches) bg = Colors.green.withValues(alpha: 0.15);
    if (mismatch) bg = Colors.red.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg ?? Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: matches
              ? Colors.green
              : mismatch
                  ? Colors.red
                  : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
          if (matches)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.check_circle, color: Colors.green, size: 18),
            ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            tooltip: 'कॉपी करें',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label कॉपी किया गया!'), duration: const Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
    );
  }
}

