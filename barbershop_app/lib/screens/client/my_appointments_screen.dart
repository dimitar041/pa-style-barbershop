import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../utils/error_utils.dart';
import '../../widgets/pa_screen_shell.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final _repo = AppRepository();

  Map<String, String> _serviceNameById = {};
  Map<String, double> _servicePriceById = {};
  Map<String, String> _productNameById = {};
  bool _metaLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    final services = await _repo.getServicesOnce();
    final products = await _repo.getBarberProductsOnce();
    if (!mounted) return;
    setState(() {
      _serviceNameById  = {for (final s in services) s.id: s.nameBg};
      _servicePriceById = {for (final s in services) s.id: s.price};
      _productNameById  = {for (final p in products) p.id: p.nameBg};
      _metaLoaded = true;
    });
  }

  Future<void> _cancelDialog(BuildContext context, AppointmentModel appt) async {
    final messenger = ScaffoldMessenger.of(context);
    final reasonCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Анулирай часа'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Причина',
            hintText: 'Напр. промяна на плановете',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отказ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Анулирай'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final reason = reasonCtrl.text.trim();
    if (reason.isEmpty) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Добави причина за анулиране.')),
      );
      return;
    }

    try {
      await _repo.cancelAppointment(
        appointmentId: appt.id,
        cancelledByUid: _repo.currentUid,
        cancelReason: reason,
      );
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Часът е анулиран.')));
    } on CancellationTooLateException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Грешка при анулиране: ${formatFirebaseError(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Моите часове'),
        actions: [
          IconButton(
            onPressed: FirebaseAuth.instance.signOut,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Изход',
          ),
        ],
      ),
      body: !_metaLoaded
          ? const PaScreenShell(child: Center(child: CircularProgressIndicator()))
          : StreamBuilder<List<AppointmentModel>>(
              stream: _repo.watchClientAppointments(_repo.currentUid),
              builder: (context, snap) {
                final cs = Theme.of(context).colorScheme;

                if (snap.connectionState == ConnectionState.waiting) {
                  return const PaScreenShell(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final list = snap.data ?? [];

                if (list.isEmpty) {
                  return PaScreenShell(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available_outlined,
                            size: 64,
                            color: cs.primary.withValues(alpha: 0.55),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Нямаш запазени часове',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Запази час от началния екран.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final nowUtc = DateTime.now().toUtc();

                return PaScreenShell(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: list.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final ap = list[i];
                      final startLocal = ap.startAtUtc.toLocal();
                      final canCancel = ap.status == AppointmentStatus.confirmed &&
                          ap.startAtUtc.difference(nowUtc) >= const Duration(hours: 2);
                      final svc = _serviceNameById[ap.serviceId] ?? ap.serviceId;
                      final price = _servicePriceById[ap.serviceId];
                      final priceStr =
                          price != null ? ' • ${price.toStringAsFixed(2)} лв.' : '';
                      final barber =
                          _productNameById[ap.barberProductId] ?? ap.barberProductId;
                      final confirmed = ap.status == AppointmentStatus.confirmed;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            title: Text(
                              '${startLocal.day.toString().padLeft(2, '0')}.${startLocal.month.toString().padLeft(2, '0')}.${startLocal.year} • '
                              '${startLocal.hour.toString().padLeft(2, '0')}:${startLocal.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                confirmed
                                    ? 'Статус: Потвърден\n$svc$priceStr • Фризьор: $barber'
                                    : 'Статус: Анулиран${ap.cancelReason != null ? ' • ${ap.cancelReason}' : ''}\n$svc • Фризьор: $barber',
                                style: TextStyle(
                                  height: 1.35,
                                  color: cs.onSurface.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                            isThreeLine: true,
                            leading: Icon(
                              confirmed
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.cancel_outlined,
                              color: confirmed
                                  ? cs.primary
                                  : cs.onSurface.withValues(alpha: 0.45),
                            ),
                            trailing: ap.status == AppointmentStatus.confirmed
                                ? FilledButton.tonal(
                                    onPressed:
                                        canCancel ? () => _cancelDialog(context, ap) : null,
                                    child: Text(canCancel ? 'Анулирай' : 'Късно'),
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
