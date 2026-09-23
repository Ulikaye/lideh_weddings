import 'package:flutter/material.dart';

import '../models/contributor.dart';
import '../services/export_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'contributor_qr_screen.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  String _query = '';

  Future<void> _confirmDelete(Contributor c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove record?'),
        content: Text('Delete ${c.fullName} (${c.id})? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await FirestoreService.instance.deleteContributor(c.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Contributor>>(
      stream: FirestoreService.instance.streamContributors(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final filtered = _query.isEmpty
            ? all
            : all.where((c) {
                final q = _query.toLowerCase();
                return c.fullName.toLowerCase().contains(q) ||
                    c.id.toLowerCase().contains(q) ||
                    c.phone.toLowerCase().contains(q);
              }).toList();

        final totalAmount = all.fold<num>(0, (sum, c) => sum + c.amount);
        final checkedInCount = all.where((c) => c.checkedIn).length;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by name, ID or phone',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _StatChip(label: 'Guests', value: '${all.length}'),
                  const SizedBox(width: 8),
                  _StatChip(label: 'Checked in', value: '$checkedInCount'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(label: 'Total', value: formatMoney(totalAmount)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: all.isEmpty
                          ? null
                          : () => ExportService.instance.exportCsv(all),
                      icon: const Icon(Icons.description_outlined),
                      label: const Text('CSV'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: all.isEmpty
                          ? null
                          : () => ExportService.instance.exportXlsx(all),
                      icon: const Icon(Icons.grid_on),
                      label: const Text('Excel'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        all.isEmpty ? 'No contributors yet.' : 'No matches.',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final c = filtered[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                c.checkedIn ? AppColors.teal : AppColors.gold.withOpacity(0.3),
                            child: Icon(
                              c.checkedIn ? Icons.check : Icons.qr_code,
                              color: c.checkedIn ? Colors.white : AppColors.ink,
                              size: 18,
                            ),
                          ),
                          title: Text(c.fullName),
                          subtitle: Text('${c.id} · ${c.cardType} · ${formatMoney(c.amount)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _confirmDelete(c),
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => ContributorQrScreen(contributor: c)),
                          ),
                        );
                      },
                    ),
            ),
          ],
            ),
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
