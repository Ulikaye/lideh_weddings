import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/contributor.dart';
import '../services/firestore_service.dart';
import '../utils/formatters.dart';
import '../widgets/app_form_card.dart';

/// A separate, non-camera way to check a guest in: for guests without a
/// smartphone, you text them a 6-character code instead of a QR. Gate
/// staff type that code in here instead of scanning.
class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({super.key});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

enum _VerifyState { entry, checking, result }

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _codeCtrl = TextEditingController();
  _VerifyState _state = _VerifyState.entry;
  Contributor? _found;
  String? _message;
  bool _ok = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _state = _VerifyState.checking);

    final contributor = await FirestoreService.instance.getContributorByCode(code);

    if (contributor == null) {
      setState(() {
        _state = _VerifyState.result;
        _found = null;
        _ok = false;
        _message = 'Not recognised. No contributor matches that code.';
      });
      return;
    }

    if (contributor.checkedIn) {
      setState(() {
        _state = _VerifyState.result;
        _found = contributor;
        _ok = false;
        _message = 'Already checked in at ${formatDateIso(contributor.checkedInTime)}.';
      });
      return;
    }

    final success = await FirestoreService.instance.checkIn(contributor.id);
    final refreshed =
        success ? await FirestoreService.instance.getContributor(contributor.id) : contributor;
    setState(() {
      _state = _VerifyState.result;
      _found = refreshed;
      _ok = success;
      _message = success ? 'Checked in successfully.' : 'Could not check in - please retry.';
    });
  }

  void _verifyAnother() {
    _codeCtrl.clear();
    setState(() {
      _state = _VerifyState.entry;
      _found = null;
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _VerifyState.result) {
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
                    onPressed: _verifyAnother,
                    icon: const Icon(Icons.pin),
                    label: const Text('Verify another code'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AppFormCard(
      title: 'Verify Code',
      subtitle: "For guests without a smartphone - enter the code you texted them.",
      children: [
        const AppFieldLabel('Contributor code'),
        TextField(
          controller: _codeCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
            UpperCaseTextFormatter(),
          ],
          style: const TextStyle(fontSize: 22, letterSpacing: 6, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(counterText: '', hintText: 'e.g. 7K2RXQ'),
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _state == _VerifyState.checking ? null : _verify,
          child: _state == _VerifyState.checking
              ? const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Verify & check in'),
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
