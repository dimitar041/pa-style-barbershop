import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../widgets/pa_screen_shell.dart';

class ChooseServiceForSlotScreen extends StatefulWidget {
  const ChooseServiceForSlotScreen({
    super.key,
    required this.barberProductId,
    required this.slotStartLocal,
  });

  final String barberProductId;
  final DateTime slotStartLocal;

  @override
  State<ChooseServiceForSlotScreen> createState() =>
      _ChooseServiceForSlotScreenState();
}

class _ChooseServiceForSlotScreenState
    extends State<ChooseServiceForSlotScreen> {
  final _repo = AppRepository();
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Избери услуга'),
        actions: [
          IconButton(
            onPressed: FirebaseAuth.instance.signOut,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Изход',
          ),
        ],
      ),
      body: StreamBuilder<List<ServiceModel>>(
        stream: _repo.watchServices(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.active &&
              snap.connectionState != ConnectionState.done) {
            return const PaScreenShell(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final services = snap.data ?? [];
          if (services.isEmpty) {
            final cs = Theme.of(context).colorScheme;
            return PaScreenShell(
              child: Center(
                child: Text(
                  'Няма създадени услуги. Администраторът трябва да ги добави в колекция services.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
                ),
              ),
            );
          }

          final cs = Theme.of(context).colorScheme;
          final timeStr =
              '${widget.slotStartLocal.hour.toString().padLeft(2, '0')}:${widget.slotStartLocal.minute.toString().padLeft(2, '0')}';

          return PaScreenShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Избери услуга',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: cs.primary, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Избран час',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.6),
                                  ),
                            ),
                            Text(
                              timeStr,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: cs.primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: services.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final s = services[i];
                      return Material(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          title: Text(
                            s.nameBg,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${s.price.toStringAsFixed(2)} лв.',
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                          onTap: _creating
                              ? null
                              : () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final navigator = Navigator.of(context);
                                  setState(() => _creating = true);
                                  try {
                                    await _repo.createAppointment(
                                      clientUid: _repo.currentUid,
                                      barberProductId: widget.barberProductId,
                                      serviceId: s.id,
                                      slotStartLocal: widget.slotStartLocal,
                                    );
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Часът е запазен!')),
                                    );
                                    if (!mounted) return;
                                    navigator.pop(true);
                                  } on SlotUnavailableException catch (e) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(content: Text(e.message)),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(content: Text('Грешка: $e')),
                                    );
                                  } finally {
                                    if (mounted) setState(() => _creating = false);
                                  }
                                },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
