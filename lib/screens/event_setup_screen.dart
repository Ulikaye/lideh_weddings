import 'package:flutter/material.dart';

import '../models/event_details.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class EventSetupScreen extends StatefulWidget {
  const EventSetupScreen({super.key});

  @override
  State<EventSetupScreen> createState() => _EventSetupScreenState();
}

class _EventSetupScreenState extends State<EventSetupScreen> {
  final _brideName = TextEditingController();
  final _groomName = TextEditingController();
  final _venue = TextEditingController();
  final _singleAmount = TextEditingController();
  final _doubleAmount = TextEditingController();
  DateTime? _weddingDate;

  bool _loadedOnce = false;
  bool _saving = false;
  String? _savedNote;

  void _applyEvent(EventDetails ev) {
    if (_loadedOnce) return; // don't clobber what the admin is typing
    _loadedOnce = true;
    _brideName.text = ev.brideName;
    _groomName.text = ev.groomName;
    _venue.text = ev.venue;
    _singleAmount.text = ev.singleAmount.toString();
    _doubleAmount.text = ev.doubleAmount.toString();
    if (ev.weddingDate.isNotEmpty) {
      _weddingDate = DateTime.tryParse(ev.weddingDate);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weddingDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _weddingDate = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final event = EventDetails(
      brideName: _brideName.text.trim(),
      groomName: _groomName.text.trim(),
      weddingDate: _weddingDate == null
          ? ''
          : _weddingDate!.toIso8601String().substring(0, 10),
      venue: _venue.text.trim(),
      singleAmount: num.tryParse(_singleAmount.text) ?? 0,
      doubleAmount: num.tryParse(_doubleAmount.text) ?? 0,
    );
    await FirestoreService.instance.saveEvent(event);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _savedNote = 'Saved.';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _savedNote = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EventDetails>(
      stream: FirestoreService.instance.streamEvent(),
      builder: (context, snapshot) {
        if (snapshot.hasData) _applyEvent(snapshot.data!);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _brideName,
                decoration: const InputDecoration(labelText: "Bride's name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _groomName,
                decoration: const InputDecoration(labelText: "Groom's name"),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Wedding date'),
                  child: Text(_weddingDate == null
                      ? 'Select a date'
                      : _weddingDate!.toIso8601String().substring(0, 10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _venue,
                decoration: const InputDecoration(labelText: 'Venue'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _singleAmount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Single card amount (TZS)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _doubleAmount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Double card amount (TZS)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save event details'),
              ),
              if (_savedNote != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_savedNote!,
                      style: const TextStyle(color: AppColors.teal),
                      textAlign: TextAlign.center),
                ),
              const SizedBox(height: 12),
              const Text(
                'Note: the invitation card itself is designed outside this '
                'app - what you save here just feeds the QR code details and '
                "records list. Send your designer the guest's QR (from Add "
                'or Records) to embed in the printed card.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
