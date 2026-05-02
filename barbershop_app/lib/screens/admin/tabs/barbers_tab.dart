import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../data/repositories.dart';

class BarbersTab extends StatefulWidget {
  const BarbersTab({super.key});

  @override
  State<BarbersTab> createState() => _BarbersTabState();
}

class _BarbersTabState extends State<BarbersTab> {
  final _repo = AppRepository();

  Future<void> _upsertDialog([BarberProductModel? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.nameBg ?? '');
    final imageCtrl = TextEditingController(text: existing?.imageUrl ?? '');
    final sortCtrl = TextEditingController(text: existing?.sortOrder.toString() ?? '0');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Нов фризьор' : 'Редакция на фризьор'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Име')),
            TextField(
              controller: imageCtrl,
              decoration: const InputDecoration(labelText: 'Image URL'),
            ),
            TextField(
              controller: sortCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sort order'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отказ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Запази'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final name = nameCtrl.text.trim();
    final sort = int.tryParse(sortCtrl.text);
    if (name.isEmpty || sort == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Попълни валидни име и sort order.')),
      );
      return;
    }
    await _repo.saveBarberProduct(
      productId: existing?.id,
      nameBg: name,
      imageUrl: imageCtrl.text.trim(),
      sortOrder: sort,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BarberProductModel>>(
      stream: _repo.watchBarberProducts(),
      builder: (context, snap) {
        final items = snap.data ?? const <BarberProductModel>[];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _upsertDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Нов фризьор'),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                separatorBuilder: (context, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final p = items[i];
                  return ListTile(
                    tileColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: Text(p.nameBg),
                    subtitle: Text('sortOrder: ${p.sortOrder}\n${p.imageUrl}'),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          onPressed: () => _upsertDialog(p),
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          onPressed: () => _repo.deleteBarberProduct(p.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
