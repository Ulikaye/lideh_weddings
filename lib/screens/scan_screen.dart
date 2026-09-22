import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/contributor.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

enum _ScanState { scanning, checking, result }

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController();
  _ScanState _state = _ScanState.scanning;
  Contributor? _found;
  String? _message; // shown when not found / already checked in
  bool _ok = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_state != _ScanState.scanning) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _state = _ScanState.checking);
    // The scanner only trusts the id (first field) - it re-reads the live
    // Firestore record rather than the possibly-stale text in the QR.
    final id = raw.split('|').first;
    final contributor = await FirestoreService.instance.getContributor(id);

    if (contributor == null) {
      setState(() {
        _state = _ScanState.result;
        _found = null;
        _ok = false;
        _message = 'Not recognised. This QR code does not match any contributor.';
      });
      return;
    }

    if (contributor.checkedIn) {
      setState(() {
        _state = _ScanState.result;
        _found = contributor;
        _ok = false;
        _message = 'Already checked in at ${formatDateIso(contributor.checkedInTime)}.';
      });
      return;
    }

    final success = await FirestoreService.instance.checkIn(id);
    final refreshed = success ? await FirestoreService.instance.getContributor(id) : contributor;
    setState(() {
      _state = _ScanState.result;
      _found = refreshed;
      _ok = success;
      _message = success ? 'Checked in successfully.' : 'Could not check in - please retry.';
    });
  }

  void _scanNext() {
    setState(() {
      _state = _ScanState.scanning;
      _found = null;
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _ScanState.scanning || _state == _ScanState.checking) {
      return Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _handleDetect),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gold, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (_state == _ScanState.checking)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Text(
              'Point the camera at a guest\'s QR code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                shadows: [Shadow(blurRadius: 6, color: Colors.black)],
              ),
            ),
          ),
        ],
      );
    }

    // result
    final c = _found;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _ok ? Icons.check_circle : Icons.error_outline,
                  color: _ok ? Colors.green : Colors.red,
                  size: 56,
                ),
                const SizedBox(height: 12),
                if (c != null) ...[
                  Text(c.fullName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('${c.id} · ${c.cardType} · ${formatMoney(c.amount)}'),
                  const SizedBox(height: 8),
                ],
                Text(_message ?? '', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _scanNext,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan next'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
