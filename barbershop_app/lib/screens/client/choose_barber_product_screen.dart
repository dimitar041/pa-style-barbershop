import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../widgets/pa_screen_shell.dart';
import 'select_time_screen.dart';

class ChooseBarberProductScreen extends StatefulWidget {
  const ChooseBarberProductScreen({super.key});

  @override
  State<ChooseBarberProductScreen> createState() =>
      _ChooseBarberProductScreenState();
}

class _ChooseBarberProductScreenState extends State<ChooseBarberProductScreen> {
  final _repo = AppRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Избери фризьор'),
        actions: [
          IconButton(
            onPressed: FirebaseAuth.instance.signOut,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Изход',
          ),
        ],
      ),
      body: StreamBuilder<List<BarberProductModel>>(
        stream: _repo.watchBarberProducts(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.active &&
              snap.connectionState != ConnectionState.done) {
            return const PaScreenShell(child: Center(child: CircularProgressIndicator()));
          }
          final products = snap.data ?? [];
          if (products.isEmpty) {
            final cs = Theme.of(context).colorScheme;
            return PaScreenShell(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 64,
                        color: cs.primary.withValues(alpha: 0.65),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Няма фризьори в каталога',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Администраторът трябва да добави документи в колекция barberProducts '
                        '(nameBg, imageUrl, sortOrder).',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.65),
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final cs = Theme.of(context).colorScheme;
          return PaScreenShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.content_cut_rounded, color: cs.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Избери фризьор и продължи към свободните часове',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${products.length}',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 10.0;
                      final shouldScroll = products.length > 4;
                      final rows = products.length <= 2 ? 1 : 2;
                      final itemWidth = (constraints.maxWidth - spacing) / 2;
                      final itemHeight = shouldScroll
                          ? itemWidth * 1.05
                          : (constraints.maxHeight - (rows - 1) * spacing) / rows;
                      final aspectRatio = itemWidth / itemHeight;

                      return GridView.builder(
                        physics: shouldScroll
                            ? const AlwaysScrollableScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, i) {
                          final p = products[i];
                          return Material(
                            elevation: 0,
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SelectTimeScreen(
                                      barberProductId: p.id,
                                      barberNameBg:
                                          p.nameBg.isNotEmpty ? p.nameBg : p.id,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      cs.surfaceContainerHighest,
                                      cs.surfaceContainerHighest.withValues(alpha: 0.88),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: cs.outline.withValues(alpha: 0.28),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.18),
                                      blurRadius: 14,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: Container(
                                          width: 78,
                                          height: 78,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: cs.surface,
                                            border: Border.all(
                                              color: cs.outline.withValues(alpha: 0.45),
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: p.imageUrl.isNotEmpty
                                                ? Image.network(
                                                    p.imageUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (context, error, stackTrace) =>
                                                            Icon(
                                                      Icons.person_rounded,
                                                      size: 34,
                                                      color: cs.primary,
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.person_rounded,
                                                    size: 34,
                                                    color: cs.primary,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
                                      child: Column(
                                        children: [
                                          Text(
                                            p.nameBg.isNotEmpty ? p.nameBg : p.id,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(fontWeight: FontWeight.w700),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Виж часове',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: cs.primary
                                                          .withValues(alpha: 0.95),
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 11,
                                                    ),
                                              ),
                                              const SizedBox(width: 2),
                                              Icon(
                                                Icons.chevron_right_rounded,
                                                size: 14,
                                                color: cs.primary.withValues(alpha: 0.95),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
          );
        },
      ),
    );
  }
}
