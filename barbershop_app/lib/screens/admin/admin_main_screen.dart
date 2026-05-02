import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/pa_screen_shell.dart';
import 'tabs/barbers_tab.dart';
import 'tabs/schedule_tab.dart';
import 'tabs/services_tab.dart';

class AdminMainScreen extends StatelessWidget {
  const AdminMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Админ панел'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_month_rounded), text: 'График'),
              Tab(icon: Icon(Icons.groups_rounded), text: 'Фризьори'),
              Tab(icon: Icon(Icons.content_cut_rounded), text: 'Услуги'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Изход',
            ),
          ],
        ),
        body: const PaPageBackground(
          child: TabBarView(
            physics: NeverScrollableScrollPhysics(),
            children: [
              ScheduleTab(),
              BarbersTab(),
              ServicesTab(),
            ],
          ),
        ),
      ),
    );
  }
}
