import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/pa_screen_shell.dart';
import 'choose_barber_product_screen.dart';
import 'my_appointments_screen.dart';
import 'salon_location_screen.dart';

class ClientMainScreen extends StatefulWidget {
  const ClientMainScreen({super.key});

  @override
  State<ClientMainScreen> createState() => _ClientMainScreenState();
}

class _ClientMainScreenState extends State<ClientMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Начало' : 'Локация'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Изход',
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          SalonLocationScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Начало',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on_rounded),
            label: 'Локация',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PaScreenShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'PA Style Studio',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Запази час при любимия фризьор или виж предстоящите си посещения.',
            style: textTheme.bodyLarge?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.7),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 28),
          _MainActionCard(
            icon: Icons.event_available_rounded,
            title: 'Запази час',
            subtitle: 'Избери фризьор, час и услуга',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChooseBarberProductScreen()),
              );
            },
          ),
          const SizedBox(height: 14),
          _MainActionCard(
            icon: Icons.history_rounded,
            title: 'Моите часове',
            subtitle: 'Преглед и анулиране',
            filled: false,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyAppointmentsScreen()),
              );
            },
          ),
          const Spacer(),
          Text(
            'Приятно преживяване',
            textAlign: TextAlign.center,
            style: textTheme.labelMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _MainActionCard extends StatelessWidget {
  const _MainActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.filled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: filled ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: filled ? cs.primary.withValues(alpha: 0.2) : cs.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: filled ? cs.primary : cs.onSurface),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.65),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.45)),
            ],
          ),
        ),
      ),
    );
  }
}
