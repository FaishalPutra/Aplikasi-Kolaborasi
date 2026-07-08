import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'api.dart';
import 'design_system.dart';
import 'modules/auth.dart';
import 'modules/people_to_people.dart';
import 'modules/people_to_project.dart';
import 'modules/profil.dart';
import 'modules/team_formation.dart';

void main() => runApp(const CollabApp());

// Navigasi ke HomeShell dilakukan langsung via Navigator (bukan lewat setState
// yang mengganti `home`), karena mengganti `home` tidak memengaruhi halaman
// yang sudah ditumpuk oleh Navigator.push (Login/Register).
// showTour: true dipakai sekali saja tepat setelah user baru selesai daftar akun,
// supaya langsung diberi tur singkat mengenalkan fitur-fitur utama.
void masukKeApp(BuildContext context, {bool showTour = false}) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => HomeShell(showTour: showTour)),
    (route) => false,
  );
}

// Dipanggil dari tab Profil saat pengguna menekan "Keluar".
void keluarDariApp(BuildContext context) {
  authToken = null;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (ctx) => WelcomePage(onLoggedIn: () => masukKeApp(ctx))),
    (route) => false,
  );
}

class CollabApp extends StatefulWidget {
  const CollabApp({super.key});
  @override
  State<CollabApp> createState() => _CollabAppState();
}

class _CollabAppState extends State<CollabApp> {
  @override
  Widget build(BuildContext context) => ShowCaseWidget(
        // onComplete diteruskan ke HomeShell lewat callback global _onTourStepComplete
        // (lihat di bawah) karena ShowCaseWidget cuma bisa dipasang sekali di akar app,
        // sedangkan yang perlu bereaksi (pindah tab) adalah HomeShell di bawahnya.
        onComplete: (_, key) => _onTourStepComplete?.call(key),
        builder: (context) => MaterialApp(
          title: 'Aplikasi Kolaborasi',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            textTheme: DS.font.fontFamily != null
                ? Typography.blackMountainView.apply(fontFamily: DS.font.fontFamily)
                : null,
            fontFamily: DS.font.fontFamily,
            scaffoldBackgroundColor: DS.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: DS.active,
              primary: DS.active,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: DS.background,
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                side: BorderSide(color: DS.divider),
              ),
            ),
          ),
          home: Builder(
            builder: (context) => WelcomePage(onLoggedIn: () => masukKeApp(context)),
          ),
        ),
      );
}

// Jembatan sederhana dari ShowCaseWidget (di akar app) ke HomeShell (di bawahnya) —
// diisi oleh HomeShell selama ia hidup, supaya tahu kapan harus pindah tab
// mengikuti langkah tur yang baru saja selesai.
void Function(GlobalKey)? _onTourStepComplete;

// Titik gabung 3 modul lewat bottom navigation.
class HomeShell extends StatefulWidget {
  final bool showTour;
  const HomeShell({super.key, this.showTour = false});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _pages = const [
    PeopleToPeoplePage(),
    PeopleToProjectPage(),
    TeamFormationPage(),
    ProfilPage(),
  ];

  // Key nav bar didefinisikan sekali di sini (instance field, bukan dibuat ulang
  // tiap build) supaya identitasnya stabil selama HomeShell hidup.
  final _navOrangKey = GlobalKey();
  final _navProyekKey = GlobalKey();
  final _navTimKey = GlobalKey();
  final _navProfilKey = GlobalKey();

  // Urutan langkah tur + tab yang wajib aktif sebelum langkah itu tampil
  // (null = tidak perlu pindah tab, karena nav bar selalu kelihatan apa pun tabnya).
  // Catatan: tourP2PPFilterKey sengaja TIDAK diikutkan — ikon filter itu cuma
  // muncul kalau profil user sudah lengkap, jadi kalau user skip survei saat
  // onboarding, target langkah itu tidak ada dan tur jadi macet/nyangkut (baru
  // "muncul tiba-tiba" belakangan begitu profil akhirnya dilengkapi).
  late final _tourTabForKey = <GlobalKey, int?>{
    _navOrangKey: null,
    tourP2PPToggleKey: 0,
    _navProyekKey: null,
    tourP2PToggleKey: 1,
    _navTimKey: null,
    tourTimToggleKey: 2,
    _navProfilKey: null,
    tourProfilEditKey: 3,
  };

  @override
  void initState() {
    super.initState();
    _onTourStepComplete = _lanjutkanTur;
    if (widget.showTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _mulaiTur());
    }
  }

  @override
  void dispose() {
    if (identical(_onTourStepComplete, _lanjutkanTur)) _onTourStepComplete = null;
    super.dispose();
  }

  // Sebelum coach-mark tur langsung tampil, beri tahu dulu lewat dialog singkat —
  // supaya tidak tiba-tiba muncul highlight tanpa konteks buat user yang baru daftar.
  Future<void> _mulaiTur() async {
    if (!mounted) return;
    final mau = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kenalan dulu, yuk!'),
        content: const Text(
            'Sebelum mulai, kami akan tunjukkan beberapa fitur utama biar kamu tidak bingung memakai aplikasi ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Lewati')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Mulai')),
        ],
      ),
    );
    if (mau != true || !mounted) return;
    ShowCaseWidget.of(context).startShowCase(_tourTabForKey.keys.toList());
  }

  // Dipanggil tiap satu langkah tur selesai — kalau langkah BERIKUTNYA butuh tab
  // lain, pindah dulu sebelum overlay tur lanjut mengukur posisi targetnya.
  void _lanjutkanTur(GlobalKey selesai) {
    if (!mounted) return;
    final urutan = _tourTabForKey.keys.toList();
    final i = urutan.indexOf(selesai);
    if (i == -1 || i + 1 >= urutan.length) {
      // tur selesai semua — kembali ke tab Orang
      if (_index != 0) setState(() => _index = 0);
      return;
    }
    final tabBerikutnya = _tourTabForKey[urutan[i + 1]];
    if (tabBerikutnya != null && tabBerikutnya != _index) {
      setState(() => _index = tabBerikutnya);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        // IndexedStack (bukan index langsung) — keempat modul tetap hidup di balik
        // layar saat pindah tab, jadi tidak fetch ulang/kedip tiap kali pindah.
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: DsFloatingNavBar(
          index: _index,
          onTap: (i) => setState(() => _index = i),
          items: [
            DsNavItem(Icons.people_outline, 'Orang',
                showcaseKey: _navOrangKey,
                showcaseTitle: 'Orang',
                showcaseDesc: 'Cari & kelola koneksi dengan mahasiswa lain.'),
            DsNavItem(Icons.work_outline, 'Proyek',
                showcaseKey: _navProyekKey,
                showcaseTitle: 'Proyek',
                showcaseDesc: 'Temukan proyek/kegiatan yang cocok denganmu.'),
            DsNavItem(Icons.groups_outlined, 'Tim',
                showcaseKey: _navTimKey,
                showcaseTitle: 'Tim',
                showcaseDesc: 'Bentuk atau gabung tim untuk ikut lomba.'),
            DsNavItem(Icons.person_outline, 'Profil',
                showcaseKey: _navProfilKey,
                showcaseTitle: 'Profil',
                showcaseDesc: 'Lihat & lengkapi profil kolaboratifmu.'),
          ],
        ),
      );
}
