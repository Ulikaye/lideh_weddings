import 'package:flutter/material.dart';

import '../models/event_details.dart';
import '../services/firestore_service.dart';
import '../utils/formatters.dart';
import '../widgets/app_form_card.dart';
import 'contributor_qr_screen.dart';

class AddContributorScreen extends StatefulWidget {
  const AddContributorScreen({super.key});

  @override
  State<AddContributorScreen> createState() => _AddContributorScreenState();
}

class _AddContributorScreenState extends State<AddContributorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _amount = TextEditingController();
  final _phone = TextEditingController();
  String _cardType = 'Single';
  DateTime _date = DateTime.now();
  EventDetails? _event;
  bool _saving = false;

  void _syncAmount() {
    final ev = _event;
    if (ev == null) return;
    _amount.text =
        (_cardType == 'Single' ? ev.singleAmount : ev.doubleAmount).toString();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final record = await FirestoreService.instance.addContributor(
      fullName: _fullName.text.trim(),
      cardType: _cardType,
      amount: num.tryParse(_amount.text) ?? 0,
      date: _date.toIso8601String().substring(0, 10),
      phone: _phone.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    _fullName.clear();
    _phone.clear();
    setState(() {
      _cardType = 'Single';
      _date = DateTime.now();
    });
    _syncAmount();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ContributorQrScreen(contributor: record)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EventDetails>(
      stream: FirestoreService.instance.streamEvent(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final firstLoad = _event == null;
          _event = snapshot.data;
          if (firstLoad) _syncAmount();
        }
        return AppFormCard(
          title: 'Add Contributor',
          subtitle: 'Record a new guest contribution.',
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppFieldLabel('Full name'),
                  TextFormField(
                    controller: _fullName,
                    decoration: const InputDecoration(hintText: 'Enter full name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 18),
                  const AppFieldLabel('Card type'),
                  DropdownButtonFormField<String>(
                    initialValue: _cardType,
                    decoration: const InputDecoration(),
                    items: const [
                      DropdownMenuItem(value: 'Single', child: Text('Single')),
                      DropdownMenuItem(value: 'Double', child: Text('Double')),
                    ],
                    onChanged: (v) {
                      setState(() => _cardType = v ?? 'Single');
                      _syncAmount();
                    },
                  ),
                  const SizedBox(height: 18),
                  const AppFieldLabel('Amount (TZS)'),
                  TextFormField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Amount'),
                  ),
                  const SizedBox(height: 18),
                  const AppFieldLabel('Date'),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(),
                      child: Text(_date.toIso8601String().substring(0, 10)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const AppFieldLabel('Phone (optional)'),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: 'Enter phone number'),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save & generate QR'),
                  ),
                  if (_event != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Single: ${formatMoney(_event!.singleAmount)}  ·  '
                      'Double: ${formatMoney(_event!.doubleAmount)}',
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
