import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/contributor.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// This replaces the old "card modal" - the designed invitation card is
/// gone. What we show/download now is ONLY the QR code (plus a text code
/// backup for guests without a smartphone), sized generously so the
/// external card designer can embed it cleanly.
class ContributorQrScreen extends StatefulWidget {
  final Contributor contributor;
  const ContributorQrScreen({super.key, required this.contributor});

  @override
  State<ContributorQrScreen> createState() => _ContributorQrScreenState();
}

class _ContributorQrScreenState extends State<ContributorQrScreen> {
  bool _downloading = false;
  bool _generatingCode = false;
  String? _textCode;

  @override
  void initState() {
    super.initState();
    _textCode = widget.contributor.textCode;
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final painter = QrPainter(
        data: widget.contributor.qrPayload,
        version: QrVersions.auto,
        gapless: true,
        color: const Color(0xFF2A1220),
        emptyColor: const Color(0xFFFFFFFF),
      );
      final imageData = await painter.toImageData(1024);
      if (imageData == null) return;
      final bytes = imageData.buffer.asUint8List();
      await FileSaver.instance.saveFile(
        name: '${widget.contributor.id}_${widget.contributor.fullName}'
            .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_'),
        bytes: bytes,
        fileExtension: 'png',
        mimeType: MimeType.png,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('QR code downloaded.')));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _generateCode() async {
    setState(() => _generatingCode = true);
    final code = await FirestoreService.instance.ensureTextCode(widget.contributor.id);
    if (!mounted) return;
    setState(() {
      _textCode = code;
      _generatingCode = false;
    });
  }

  void _copyCode() {
    if (_textCode == null) return;
    Clipboard.setData(ClipboardData(text: _textCode!));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Code copied - paste it into your SMS.')));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contributor;
    return Scaffold(
      appBar: AppBar(title: const Text('Contributor QR code')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c.fullName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('${c.cardType} card · ${formatMoney(c.amount)}'),
                  Text(formatDateIso(c.date), style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.gold, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: c.qrPayload,
                      version: QrVersions.auto,
                      size: 220,
                      gapless: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(c.id, style: const TextStyle(letterSpacing: 1, color: Colors.black54)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _downloading ? null : _download,
                    icon: _downloading
                        ? const SizedBox(
                            height: 16, width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download),
                    label: const Text('Download QR (PNG)'),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Text code (no smartphone needed)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Share this by SMS or phone call. At the gate, enter it '
                    'on the Verify Code screen instead of scanning.',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if (_textCode != null)
                    InkWell(
                      onTap: _copyCode,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _textCode!,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 6,
                                color: AppColors.teal,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.copy, size: 18, color: Colors.black45),
                          ],
                        ),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _generatingCode ? null : _generateCode,
                      icon: _generatingCode
                          ? const SizedBox(
                              height: 16, width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.pin),
                      label: const Text('Generate text code'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
