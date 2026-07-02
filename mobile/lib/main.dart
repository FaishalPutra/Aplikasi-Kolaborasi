import 'package:flutter/material.dart';
import 'modules/auth.dart';
import 'modules/people_to_people.dart';
import 'modules/people_to_project.dart';
import 'modules/team_formation.dart';

void main() => runApp(const CollabApp());

class CollabApp extends StatefulWidget {
  const CollabApp({super.key});
  @override
  State<CollabApp> createState() => _CollabAppState();
}

class _CollabAppState extends State<CollabApp> {
  // Navigasi ke HomeShell dilakukan langsung via Navigator (bukan lewat setState
  // yang mengganti `home`), karena mengganti `home` tidak memengaruhi halaman
  // yang sudah ditumpuk oleh Navigator.push (Login/Register).
  void _masukKeApp(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Aplikasi Kolaborasi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: const Color(0xFFF4F6FB),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            primary: const Color(0xFF2563EB),
          ),
          cardTheme: const CardThemeData(
            elevation: 0,
            color: Colors.white,
            margin: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
              side: BorderSide(color: Color(0x11000000)),
            ),
          ),
        ),
        home: Builder(
          builder: (context) => WelcomePage(onLoggedIn: () => _masukKeApp(context)),
        ),
      );
}

// Titik gabung 3 modul lewat bottom navigation.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _pages = const [
    PeopleToPeoplePage(),
    PeopleToProjectPage(),
    TeamFormationPage(),
    _ProfilPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _pages[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Orang'),
            NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Proyek'),
            NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Tim'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      );
}

// Placeholder tab Profil — layar lengkap (mockup ke-4) menyusul.
class _ProfilPlaceholder extends StatelessWidget {
  const _ProfilPlaceholder();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Profil — segera hadir')),
      );
}
