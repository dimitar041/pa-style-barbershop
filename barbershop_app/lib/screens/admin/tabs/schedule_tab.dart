import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../constants/work_schedule.dart';
import '../../../data/models.dart';
import '../../../data/repositories.dart';
import '../../../utils/error_utils.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  final _repo = AppRepository();
  late DateTime _selectedDay;
  Map<String, String> _serviceNames = {};
  List<BarberProductModel> _barbers = [];
  String? _selectedBarberId;
  bool _catalogLoading = true;
  final Map<String, Map<String, dynamic>> _profiles = {};

  static const String _busyReason = 'Зает';

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() => _catalogLoading = true);
    try {
      final services = await _repo.getServicesOnce();
      final barbers = await _repo.getBarberProductsOnce();
      if (!mounted) return;
      setState(() {
        _serviceNames = {for (final s in services) s.id: s.nameBg};
        _barbers = barbers;
        if (_selectedBarberId == null && barbers.isNotEmpty) {
          _selectedBarberId = barbers.first.id;
        } else if (_selectedBarberId != null &&
            !barbers.any((b) => b.id == _selectedBarberId)) {
          _selectedBarberId = barbers.isNotEmpty ? barbers.first.id : null;
        }
        _catalogLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _catalogLoading = false);
    }
  }

  Future<void> _loadProfiles(List<String> clientIds) async {
    final missing = clientIds.where((id) => !_profiles.containsKey(id)).toList();
    if (missing.isEmpty) return;
    final fetched = await _repo.fetchProfiles(missing);
    if (!mounted) return;
    setState(() {
      for (final entry in fetched.entries) {
        _profiles[entry.key] = entry.value as Map<String, dynamic>;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      locale: const Locale('bg', 'BG'),
    );
    if (picked == null) return;
    setState(() => _selectedDay = picked);
  }

  Future<String?> _reasonDialog({required String title, required String hint}) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, decoration: InputDecoration(labelText: hint)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отказ')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Запази')),
        ],
      ),
    );
    if (ok != true) return null;
    return ctrl.text.trim();
  }

  Future<void> _blockSlot({
    required String barberId,
    required DateTime slotLocal,
    required String reason,
    required bool blocked,
  }) async {
    await _repo.setBlockedSlot(
      barberProductId: barberId,
      slotStartLocal: slotLocal,
      blockedByUid: _repo.currentUid,
      reason: reason,
      blocked: blocked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return const Center(child: Text('Няма активна сесия.'));
    }

    final slots = WorkSchedule.generateSlotsForLocalDate(_selectedDay);
    final barberId = _selectedBarberId;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_selectedDay.day.toString().padLeft(2, '0')}.${_selectedDay.month.toString().padLeft(2, '0')}.${_selectedDay.year}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(onPressed: _pickDate, icon: const Icon(Icons.calendar_month)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _barbers.isEmpty
              ? const Text('Няма фризьори в barberProducts.')
              : InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Фризьор',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: barberId,
                      items: _barbers
                          .map((b) => DropdownMenuItem(
                                value: b.id,
                                child: Text(b.nameBg.isNotEmpty ? b.nameBg : b.id),
                              ))
                          .toList(),
                      onChanged: _catalogLoading
                          ? null
                          : (id) {
                              if (id == null) return;
                              setState(() => _selectedBarberId = id);
                            },
                    ),
                  ),
                ),
        ),
        Expanded(
          child: barberId == null
              ? const Center(child: Text('Избери фризьор.'))
              : StreamBuilder<List<BlockedSlotModel>>(
                  stream: _repo.watchBlockedSlotsForDay(
                    barberProductId: barberId,
                    dayLocal: _selectedDay,
                  ),
                  builder: (context, blockedSnap) {
                    if (blockedSnap.connectionState != ConnectionState.active &&
                        blockedSnap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final blocked = blockedSnap.data ?? [];
                    final blockedByMs = <String, String>{
                      for (final b in blocked)
                        b.startAtUtc.millisecondsSinceEpoch.toString(): b.reason,
                    };

                    return StreamBuilder<List<AppointmentModel>>(
                      stream: _repo.watchBarberProductAppointmentsForDay(
                        barberProductId: barberId,
                        dayLocal: _selectedDay,
                      ),
                      builder: (context, apSnap) {
                        if (apSnap.connectionState != ConnectionState.active &&
                            apSnap.connectionState != ConnectionState.done) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final appts = apSnap.data ?? [];
                        final confirmedByMs = <String, AppointmentModel>{
                          for (final a in appts)
                            if (a.status == AppointmentStatus.confirmed)
                              a.startAtUtc.millisecondsSinceEpoch.toString(): a,
                        };

                        final clientIds = appts
                            .where((a) => a.status == AppointmentStatus.confirmed)
                            .map((a) => a.clientId)
                            .toSet()
                            .toList();
                        _loadProfiles(clientIds);

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: slots.length,
                          separatorBuilder: (context, _) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final slotLocal = slots[i];
                            final slotKeyMs =
                                slotLocal.toUtc().millisecondsSinceEpoch.toString();
                            final isBlocked = blockedByMs.containsKey(slotKeyMs);
                            final appt = confirmedByMs[slotKeyMs];

                            if (appt != null) {
                              final profile = _profiles[appt.clientId] ?? {};
                              final clientName =
                                  (profile['displayName'] ?? appt.clientId).toString();
                              final clientPhone = (profile['phone'] ?? '').toString();
                              final serviceName =
                                  _serviceNames[appt.serviceId] ?? appt.serviceId;

                              return ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                tileColor: Colors.orange.withValues(alpha: 0.15),
                                title: Text(WorkSchedule.formatSlot(slotLocal)),
                                subtitle: Text(
                                  'Запазен • $clientName'
                                  '${clientPhone.isNotEmpty ? ' • $clientPhone' : ''}\n'
                                  'Услуга: $serviceName',
                                ),
                                isThreeLine: true,
                                trailing: ElevatedButton(
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final reason = await _reasonDialog(
                                      title: 'Анулирай запис',
                                      hint: 'Причина',
                                    );
                                    if (reason == null || reason.isEmpty) return;
                                    try {
                                      await _repo.cancelAppointment(
                                        appointmentId: appt.id,
                                        cancelledByUid: currentUid,
                                        cancelReason: reason,
                                      );
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        const SnackBar(content: Text('Записът е анулиран.')),
                                      );
                                    } on CancellationTooLateException catch (e) {
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(content: Text(e.message)),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Грешка при анулиране: ${formatFirebaseError(e)}',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Анулирай'),
                                ),
                              );
                            }

                            if (isBlocked) {
                              return ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                tileColor: Colors.red.withValues(alpha: 0.12),
                                title: Text(WorkSchedule.formatSlot(slotLocal)),
                                subtitle: const Text(_busyReason),
                                trailing: OutlinedButton(
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    try {
                                      await _blockSlot(
                                        barberId: barberId,
                                        slotLocal: slotLocal,
                                        blocked: false,
                                        reason: '',
                                      );
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        const SnackBar(content: Text('Слотът е освободен.')),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Грешка при освобождаване: ${formatFirebaseError(e)}',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Освободи'),
                                ),
                              );
                            }

                            return ElevatedButton(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  await _blockSlot(
                                    barberId: barberId,
                                    slotLocal: slotLocal,
                                    blocked: true,
                                    reason: _busyReason,
                                  );
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Слотът е блокиран.')),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Грешка при маркиране: ${formatFirebaseError(e)}',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text('Блокирай: ${WorkSchedule.formatSlot(slotLocal)}'),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
