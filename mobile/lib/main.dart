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
  bool _login = false;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Collab Platform',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF4F46E5), // indigo
          cardTheme: const CardThemeData(
            elevation: 0,
            margin: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              side: BorderSide(color: Color(0x14000000)),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            filled: true,
          ),
        ),
        home: _login
            ? const HomeShell()
            : AuthPage(onLogin: () => setState(() => _login = true)),
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
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _pages[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.people), label: 'People'),
            NavigationDestination(icon: Icon(Icons.work), label: 'Project'),
            NavigationDestination(icon: Icon(Icons.groups), label: 'Team'),
          ],
        ),
      );
}
