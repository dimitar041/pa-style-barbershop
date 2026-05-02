import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../constants/work_schedule.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../widgets/pa_screen_shell.dart';
import 'choose_service_for_slot_screen.dart';

class _DayData {
  _DayData({required this.blocked, required this.appointments});

  final List<BlockedSlotModel> blocked;
  final List<AppointmentModel> appointments;
}

class SelectTimeScreen extends StatefulWidget {
  const SelectTimeScreen({
    super.key,
    required this.barberProductId,
    required this.barberNameBg,
  });

  final String barberProductId;
  final String barberNameBg;

  @override
  State<SelectTimeScreen> createState() => _SelectTimeScreenState();
}

class _SelectTimeScreenState extends State<SelectTimeScreen> {
  final _repo = AppRepository();
  late DateTime _selectedDay;
  bool _creating = false;
  Future<_DayData>? _dayDataFuture;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _dayDataFuture = _loadDayData();
  }

  Future<_DayData> _loadDayData() async {
    final results = await Future.wait([
      _repo.getBlockedSlotsForDayOnce(
        barberProductId: widget.barberProductId,
        dayLocal: _selectedDay,
      ),
      _repo.getBarberProductAppointmentsForDayOnce(
        barberProductId: widget.barberProductId,
        dayLocal: _selectedDay,
      ),
    ]);
    return _DayData(
      blocked: results[0] as List<BlockedSlotModel>,
      appointments: results[1] as List<AppointmentModel>,
    );
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
    setState(() {
      _selectedDay = picked;
      _dayDataFuture = _loadDayData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final slots = WorkSchedule.generateSlotsForLocalDate(_selectedDay);
    final cs = Theme.of(context).colorScheme;
    final dateStr =
        '${_selectedDay.day.toString().padLeft(2, '0')}.${_selectedDay.month.toString().padLeft(2, '0')}.${_selectedDay.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Часове — ${widget.barberNameBg}'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Изход',
          ),
        ],
      ),
      body: PaScreenShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Избери ден и час',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.barberNameBg,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Material(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: cs.primary, size: 26),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Дата',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.55),
                                  ),
                            ),
                            Text(
                              dateStr,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_calendar_outlined,
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<_DayData>(
                future: _dayDataFuture,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final dayData = snap.data;
                  if (dayData == null) {
                    return Center(
                      child: Text(
                        'Грешка при зареждане.',
                        style: TextStyle(color: cs.error),
                      ),
                    );
                  }

                  final blockedByMs = <String, String>{
                    for (final b in dayData.blocked)
                      b.startAtUtc.millisecondsSinceEpoch.toString(): b.reason,
                  };
                  final confirmedByMs = <String, AppointmentModel>{
                    for (final a in dayData.appointments)
                      if (a.status == AppointmentStatus.confirmed)
                        a.startAtUtc.millisecondsSinceEpoch.toString(): a,
                  };

                  if (slots.isEmpty) {
                    return Center(
                      child: Text(
                        'Няма слотове за този ден.',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: slots.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final slotLocal = slots[i];
                      final slotKeyMs =
                          slotLocal.toUtc().millisecondsSinceEpoch.toString();
                      final existing = confirmedByMs[slotKeyMs];
                      final blockedReason = blockedByMs[slotKeyMs];

                      if (existing != null) {
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          tileColor: cs.secondary.withValues(alpha: 0.22),
                          title: Text(
                            WorkSchedule.formatSlot(slotLocal),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text('Запазен'),
                          leading:
                              Icon(Icons.event_busy_rounded, color: cs.secondary),
                        );
                      }

                      if (blockedReason != null) {
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          tileColor: cs.error.withValues(alpha: 0.12),
                          title: Text(
                            WorkSchedule.formatSlot(slotLocal),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text('Зает'),
                          leading: Icon(
                            Icons.block_rounded,
                            color: cs.error.withValues(alpha: 0.9),
                          ),
                        );
                      }

                      return FilledButton(
                        onPressed: _creating
                            ? null
                            : () {
                                setState(() => _creating = true);
                                Navigator.of(context)
                                    .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => ChooseServiceForSlotScreen(
                                      barberProductId: widget.barberProductId,
                                      slotStartLocal: slotLocal,
                                    ),
                                  ),
                                )
                                    .then((booked) {
                                  if (!mounted) return;
                                  setState(() {
                                    _creating = false;
                                    if (booked == true) {
                                      _dayDataFuture = _loadDayData();
                                    }
                                  });
                                });
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          child: Text(
                            'Свободен • ${WorkSchedule.formatSlot(slotLocal)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
