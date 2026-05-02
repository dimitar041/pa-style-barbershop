import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../data/repositories.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  final _repo = AppRepository();

  Future<void> _upsertDialog([ServiceModel? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.nameBg ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(2) : '',
    );
    final durationCtrl = TextEditingController(
      text: existing?.durationMinutes.toString() ?? '30',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Нова услуга' : 'Редакция на услуга'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Име')),
            TextField(
              controller: priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Цена'),
            ),
            TextField(
              controller: durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Продължителност (мин)'),
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
    final price = double.tryParse(priceCtrl.text.replaceAll(',', '.'));
    final duration = int.tryParse(durationCtrl.text);
    if (name.isEmpty || price == null || duration == null || duration <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Попълни валидни име, цена и продължителност.')),
      );
      return;
    }
    await _repo.saveService(
      serviceId: existing?.id,
      nameBg: name,
      price: price,
      durationMinutes: duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ServiceModel>>(
      stream: _repo.watchServices(),
      builder: (context, snap) {
        final items = snap.data ?? const <ServiceModel>[];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _upsertDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Нова услуга'),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                separatorBuilder: (context, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final s = items[i];
                  return ListTile(
                    tileColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: Text(s.nameBg),
                    subtitle: Text(
                      '${s.price.toStringAsFixed(2)} лв. • ${s.durationMinutes} мин',
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          onPressed: () => _upsertDialog(s),
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          onPressed: () => _repo.deleteService(s.id),
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
