import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import '../api.dart';
import '../design_system.dart';

// Modul People-to-People (Ahmad). Tersambung ke backend /api/people-to-people.
// Desain mengikuti design system bersama (lihat design_system.dart).

const _biru = DS.active;
const _navy = DS.primaryText;
const _abu = DS.secondaryText;
const _hijau = DS.success;
const _pink = DS.pink; // status "Tertarik" — perpaduan merah & pink
const _pinkMuda = DS.pinkMuda;

// Dipakai tur onboarding (lihat main.dart) — target elemen statis yang selalu ada.
final GlobalKey tourP2PPToggleKey = GlobalKey();
final GlobalKey tourP2PPFilterKey = GlobalKey();

// mahasiswaId koneksi yang sudah pernah dilihat di sesi berjalan (reset kalau app di-restart)
final Set<String> _koneksiTerlihat = <String>{};

const _avatarPalette = [
  _biru,
  _hijau,
  Color(0xFF9333EA),
  Color(0xFF0D9488),
  Color(0xFF475569),
  Color(0xFFDB2777),
];

Color _avatarColor(String key) {
  var h = 0;
  for (final c in key.codeUnits) {
    h = (h + c) % _avatarPalette.length;
  }
  return _avatarPalette[h];
}

String _inisial(String nama) {
  final parts = nama.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

// ---------- WIDGET UMUM ----------
// Warna bar RINCIAN KECOCOKAN mengikuti tingkat bobot atribut itu di AffinityEngine
// (bobot makin besar -> makin gelap/pekat, bobot kecil -> makin pudar) — supaya
// atribut yang paling berpengaruh terlihat paling menonjol.
Color _warnaBobot(double bobot, double minBobot, double maxBobot) {
  final t = (maxBobot == minBobot) ? 1.0 : ((bobot - minBobot) / (maxBobot - minBobot)).clamp(0.0, 1.0);
  return Color.lerp(const Color(0xFFB6C2D9), _biru, t)!;
}

Color _labelBg(String b) => (b == 'Sangat Cocok')
    ? const Color(0xFFDCFCE7)
    : (b == 'Cocok' ? const Color(0xFFFEF3C7) : DS.chipInactiveBg);
Color _labelFg(String b) =>
    (b == 'Sangat Cocok') ? _hijau : (b == 'Cocok' ? DS.warning : _navy);

Widget _badge(String teks) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: _labelBg(teks), borderRadius: BorderRadius.circular(999)),
      child: Text(teks, style: TextStyle(color: _labelFg(teks), fontWeight: FontWeight.w700, fontSize: 12)),
    );

Widget _avatar(String nama, String key, {double size = 52}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: _avatarColor(key), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(_inisial(nama),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.34)),
    );

class _Donut extends StatelessWidget {
  final num persen;
  final double size;
  const _Donut(this.persen, {this.size = 108});
  @override
  Widget build(BuildContext context) {
    final warna = persen >= 60 ? _hijau : _abu;
    return DsRadialGauge(
      percent: persen,
      size: size,
      filledColor: warna,
      center: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${persen.round()}%',
            style: TextStyle(fontSize: size * 0.2, fontWeight: FontWeight.bold, color: _navy)),
        Text('COCOK', style: TextStyle(fontSize: size * 0.09, color: _abu, letterSpacing: 1)),
      ]),
    );
  }
}

Widget _chipList(List<String> items) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(color: DS.chipInactiveBg, borderRadius: BorderRadius.circular(999)),
                child: Text(s, style: const TextStyle(color: _navy, fontSize: 13, fontWeight: FontWeight.w500)),
              ))
          .toList(),
    );

Widget _sectionTitle(String t) =>
    Text(t, style: const TextStyle(color: _biru, fontWeight: FontWeight.bold, letterSpacing: 0.5));

void _snack(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

Widget _lihatProfil(BuildContext context, String mahasiswaId) => Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => PartnerDetailPage(mahasiswaId: mahasiswaId))),
        child: const Text('Lihat profil lengkap →', style: TextStyle(color: _biru, fontWeight: FontWeight.bold)),
      ),
    );

// ---------- HALAMAN UTAMA ----------
class PeopleToPeoplePage extends StatefulWidget {
  const PeopleToPeoplePage({super.key});
  @override
  State<PeopleToPeoplePage> createState() => _PeopleToPeoplePageState();
}

class _PeopleToPeoplePageState extends State<PeopleToPeoplePage> {
  int _tab = 0;
  int _jumlahPermintaan = 0;
  int _jumlahKoneksiBaru = 0;

  @override
  void initState() {
    super.initState();
    _muatBadge();
  }

  Future<void> _muatBadge() async {
    if (authToken == null) return;
    try {
      final r = await apiGet('/people-to-people/requests');
      final permintaan = (r is Map && r['permintaan'] is List) ? r['permintaan'] as List : [];
      final c = await apiGet('/people-to-people/connections');
      final koneksi = (c is Map && c['koneksi'] is List) ? c['koneksi'] as List : [];
      final baru = koneksi.where((k) => !_koneksiTerlihat.contains((k as Map)['mahasiswaId'].toString())).length;
      if (mounted) {
        setState(() {
          _jumlahPermintaan = permintaan.length;
          _jumlahKoneksiBaru = baru;
        });
      }
    } catch (_) {
      // biarkan angka yang lama kalau gagal memuat
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            const SizedBox(height: 8),
            Showcase(
              key: tourP2PPToggleKey,
              title: 'Orang',
              description: 'Lihat rekomendasi partner kolaborasi yang cocok, atau kelola koneksi & permintaanmu di sini.',
              child: _toggleAtas(),
            ),
            const SizedBox(height: 16),
            Expanded(
              // IndexedStack (bukan ternary) — kedua tab tetap hidup di balik layar
              // saat berpindah, jadi tidak ada kedipan/loading ulang & posisi
              // swipe/scroll tidak hilang. Konsisten dengan modul lain.
              child: IndexedStack(
                index: _tab,
                children: [
                  const _RekomendasiTab(),
                  _KoneksiTab(
                    onJumlahBerubah: (p, k) => setState(() {
                      _jumlahPermintaan = p;
                      _jumlahKoneksiBaru = k;
                    }),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _toggleAtas() {
    Widget seg(String label, int i, {int badge = 0}) {
      final aktif = _tab == i;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() => _tab = i);
            _muatBadge();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: aktif ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: aktif ? [const BoxShadow(color: Color(0x14000000), blurRadius: 8)] : null,
            ),
            alignment: Alignment.center,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: aktif ? _biru : _abu)),
              if (badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text('$badge',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ]),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFEEF2F7), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [seg('Rekomendasi', 0), seg('Koneksi', 1, badge: _jumlahPermintaan + _jumlahKoneksiBaru)]),
    );
  }
}

// ---------- TAB REKOMENDASI ----------
class _RekomendasiTab extends StatefulWidget {
  const _RekomendasiTab();
  @override
  State<_RekomendasiTab> createState() => _RekomendasiTabState();
}

// Opsi atribut untuk filter lapis-2 (harus sinkron dengan opsi di halaman Profil).
const _minatOpsiFilter = [
  'AI', 'Riset', 'Pengembangan Web', 'Pengembangan Mobile', 'Desain', 'Data Science',
  'Kewirausahaan', 'UI/UX',
];
const _peranOpsiFilter = ['Leader/Coordinator', 'Contributor/Executor', 'Supporter/Facilitator'];
const _gayaOpsiFilter = ['Terstruktur', 'Fleksibel'];
const _waktuOpsiFilter = [
  'Senin malam', 'Selasa sore', 'Rabu sore', 'Kamis malam', 'Jumat sore', 'Sabtu pagi', 'Minggu malam',
];

class _RekomendasiTabState extends State<_RekomendasiTab> {
  final _filter = const [
    {'label': 'Semua', 'key': 'semua'},
    {'label': 'Sangat Cocok', 'key': 'sangat'},
    {'label': 'Cocok', 'key': 'cocok'},
    {'label': 'Cukup Cocok', 'key': 'cukup'},
  ];
  int _filterAktif = 0;
  int _index = 0;
  bool _loading = true;
  String? _pesan;
  bool _profilBelumLengkap = false;
  List<dynamic> _feed = [];

  // Filter lapis-2 (atribut)
  final Set<String> _minatFilter = {};
  final Set<String> _waktuFilter = {};
  String? _peranFilter;
  String? _gayaFilter;

  int get _jumlahFilterAktif =>
      _minatFilter.length + _waktuFilter.length + (_peranFilter != null ? 1 : 0) + (_gayaFilter != null ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    if (authToken == null) {
      setState(() {
        _loading = false;
        _pesan = 'Silakan login dulu.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _pesan = null;
    });
    try {
      final tier = _filter[_filterAktif]['key'];
      final q = <String, String>{'tier': tier ?? 'semua'};
      if (_minatFilter.isNotEmpty) q['minat'] = _minatFilter.join(',');
      if (_waktuFilter.isNotEmpty) q['waktu'] = _waktuFilter.join(',');
      if (_peranFilter != null) q['peran'] = _peranFilter!;
      if (_gayaFilter != null) q['gaya'] = _gayaFilter!;
      final qs = q.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
      final res = await apiGet('/people-to-people/feed?$qs');
      final feed = (res is Map && res['feed'] is List) ? res['feed'] as List : [];
      final error = res is Map ? res['error']?.toString() : null;
      setState(() {
        _feed = feed;
        _index = 0;
        _profilBelumLengkap = error != null;
        if (feed.isEmpty) {
          _pesan = error ?? 'Belum ada rekomendasi.';
        }
      });
    } catch (_) {
      setState(() => _pesan = 'Gagal memuat. Pastikan backend jalan.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _chipPilih(String label, bool aktif, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: aktif ? _biru : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: aktif ? _biru : const Color(0xFFE2E8F0)),
          ),
          child: Text(label, style: TextStyle(color: aktif ? Colors.white : _navy, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      );

  void _bukaFilterSheet() {
    // salinan sementara supaya bisa dibatalkan tanpa mengubah filter yang aktif
    final minat = Set<String>.from(_minatFilter);
    final waktu = Set<String>.from(_waktuFilter);
    String? peran = _peranFilter;
    String? gaya = _gayaFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Filter Rekomendasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
                TextButton(
                  onPressed: () => setSheet(() {
                    minat.clear();
                    waktu.clear();
                    peran = null;
                    gaya = null;
                  }),
                  child: const Text('Reset', style: TextStyle(color: _abu, fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 12),
              _sectionTitle('MINAT'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _minatOpsiFilter
                    .map((m) => _chipPilih(m, minat.contains(m),
                        () => setSheet(() => minat.contains(m) ? minat.remove(m) : minat.add(m))))
                    .toList(),
              ),
              const SizedBox(height: 18),
              _sectionTitle('PREFERENSI PERAN'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _peranOpsiFilter
                    .map((p) => _chipPilih(p, peran == p, () => setSheet(() => peran = (peran == p) ? null : p)))
                    .toList(),
              ),
              const SizedBox(height: 18),
              _sectionTitle('GAYA KERJA'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _gayaOpsiFilter
                    .map((g) => _chipPilih(g, gaya == g, () => setSheet(() => gaya = (gaya == g) ? null : g)))
                    .toList(),
              ),
              const SizedBox(height: 18),
              _sectionTitle('KETERSEDIAAN WAKTU'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _waktuOpsiFilter
                    .map((w) => _chipPilih(w, waktu.contains(w),
                        () => setSheet(() => waktu.contains(w) ? waktu.remove(w) : waktu.add(w))))
                    .toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      _minatFilter
                        ..clear()
                        ..addAll(minat);
                      _waktuFilter
                        ..clear()
                        ..addAll(waktu);
                      _peranFilter = peran;
                      _gayaFilter = gaya;
                    });
                    Navigator.of(ctx).pop();
                    _muat();
                  },
                  style: FilledButton.styleFrom(
                      backgroundColor: _biru,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                  child: const Text('Terapkan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habis = _index >= _feed.length;
    // Kalau profil belum lengkap, sembunyikan kontrol filter (percuma difilter,
    // belum ada data) supaya tampilannya bersih & simetris seperti modul lain.
    final tampilkanKontrol = !_profilBelumLengkap;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Rekomendasi orang',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _navy)),
            Text(_feed.isEmpty ? '0 kandidat' : (habis ? '${_feed.length} kandidat' : 'Kandidat ${_index + 1} dari ${_feed.length}'),
                style: const TextStyle(color: _abu)),
          ]),
        ),
        if (tampilkanKontrol) ...[
          Stack(clipBehavior: Clip.none, children: [
            Showcase(
              key: tourP2PPFilterKey,
              title: 'Filter Rekomendasi',
              description: 'Atur rekomendasi berdasarkan skor kecocokan, minat, preferensi peran, gaya kerja, atau waktu luang.',
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0))),
                child: IconButton(onPressed: _bukaFilterSheet, icon: const Icon(Icons.tune, color: _biru)),
              ),
            ),
            if (_jumlahFilterAktif > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text('$_jumlahFilterAktif',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
          ]),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0))),
            child: IconButton(onPressed: _muat, icon: const Icon(Icons.refresh, color: _biru)),
          ),
        ],
      ]),
      if (tampilkanKontrol) ...[
        const SizedBox(height: 14),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filter.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => DsChip(
              label: _filter[i]['label']!,
              aktif: i == _filterAktif,
              onTap: () {
                setState(() => _filterAktif = i);
                _muat();
              },
            ),
          ),
        ),
      ],
      const SizedBox(height: 16),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_feed.isEmpty || habis)
                ? ListView(children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: _EmptyState(
                        icon: Icons.auto_awesome,
                        judul: _feed.isEmpty ? (_pesan ?? 'Belum ada rekomendasi') : 'Kamu sudah lihat semua',
                        subtitle: 'Cek koneksi & profil tersimpan, atau ubah filter untuk lihat lagi.',
                        tombol: 'Muat ulang',
                        onTombol: _muat,
                      ),
                    ),
                  ])
                : _KartuRekomendasi(
                    // key beda per kandidat supaya status tombol (disimpan/tertarik) tidak
                    // ikut terbawa saat pindah ke kandidat berikutnya
                    key: ValueKey(_feed[_index]['mahasiswaId']),
                    item: _feed[_index] as Map,
                    onSkip: () => setState(() => _index++),
                  ),
      ),
    ]);
  }
}

class _KartuRekomendasi extends StatefulWidget {
  final Map item;
  final VoidCallback onSkip;
  const _KartuRekomendasi({super.key, required this.item, required this.onSkip});

  @override
  State<_KartuRekomendasi> createState() => _KartuRekomendasiState();
}

class _KartuRekomendasiState extends State<_KartuRekomendasi> {
  late bool _disimpan;
  late bool _tertarik;
  late bool _sudahHubungkan;
  bool _memuatSimpan = false;
  bool _memuatTertarik = false;
  bool _memuatHubungkan = false;

  Map get item => widget.item;
  String get _id => item['mahasiswaId'].toString();

  @override
  void initState() {
    super.initState();
    // Baca status awal dari feed (bukan selalu mulai dari nol) — supaya benar
    // walau kandidat yang sama muncul lagi setelah refresh.
    _disimpan = item['sudahDisimpan'] == true;
    _tertarik = item['sudahTertarik'] == true;
    _sudahHubungkan = item['sudahKirimPermintaan'] == true;
  }

  // Dipanggil setelah kembali dari halaman detail — aksi Simpan/Tertarik/Hubungkan
  // bisa saja dilakukan di sana, jadi status kartu ini perlu disamakan lagi.
  Future<void> _sinkronStatus() async {
    try {
      final res = await apiGet('/people-to-people/profil/$_id');
      if (mounted && res is Map) {
        setState(() {
          _disimpan = res['sudahDisimpan'] == true;
          _tertarik = res['sudahTertarik'] == true;
          _sudahHubungkan = res['sudahKirimPermintaan'] == true;
        });
      }
    } catch (_) {
      // biarkan status yang lama kalau gagal memuat
    }
  }

  Widget _kotakAksi(IconData icon, VoidCallback? onTap, {bool aktif = false, bool memuat = false}) => InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: aktif ? const Color(0xFFEEF2FF) : null,
              shape: BoxShape.circle,
              border: Border.all(color: aktif ? _biru : const Color(0xFFE2E8F0))),
          child: memuat
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(icon, size: 20, color: aktif ? _biru : _navy),
        ),
      );

  // Toggle: kalau belum aktif -> POST (aktifkan), kalau sudah aktif -> DELETE (undo).
  // Kalau hasilnya CONNECTED (saling tertarik/hubungkan), langsung lanjut ke kandidat
  // berikutnya karena hubungannya sudah final, tidak ada lagi yang bisa di-undo.
  Future<void> _toggle({
    required bool aktifSaatIni,
    required String postPath,
    required String deletePath,
    required Map<String, dynamic> body,
    required void Function(bool memuat) setMemuat,
    required void Function(bool nilai) setAktif,
  }) async {
    setState(() => setMemuat(true));
    try {
      if (aktifSaatIni) {
        final res = await apiDelete(deletePath);
        final pesan = res is Map && res['pesan'] != null ? res['pesan'].toString() : 'Dibatalkan';
        if (mounted) _snack(context, pesan);
        setState(() => setAktif(false));
      } else {
        final res = await apiPost(postPath, body);
        final pesan = res is Map && res['pesan'] != null ? res['pesan'].toString() : 'Berhasil';
        if (mounted) _snack(context, pesan);
        setState(() => setAktif(true));
        final status = res is Map ? res['status']?.toString() : null;
        if (status == 'CONNECTED') {
          widget.onSkip();
          return; // widget ini akan diganti kandidat berikutnya, tidak perlu setState lagi
        }
      }
    } catch (_) {
      if (mounted) _snack(context, 'Gagal terhubung ke server.');
    }
    if (mounted) setState(() => setMemuat(false));
  }

  @override
  Widget build(BuildContext context) {
    final nama = item['nama']?.toString() ?? '-';
    final institusi = item['institusi']?.toString() ?? '';
    final jurusan = item['jurusan']?.toString() ?? '';
    final angkatan = item['angkatan'];
    final jurusanAngkatan =
        jurusan.isNotEmpty && angkatan != null ? '$jurusan · $angkatan' : (jurusan.isNotEmpty ? jurusan : '');
    final bio = item['bio']?.toString() ?? '';
    final alasan = (item['alasan'] as List?)?.cast<String>() ?? [];
    final dotWarna = [_hijau, _biru, _biru, const Color(0xFFD97706)];
    // Kartu selalu mengisi tinggi penuh yang tersedia (bukan mengikuti tinggi konten) supaya
    // posisi & ukurannya tidak berubah-ubah antar kandidat — cuma bagian "alasan cocok" yang
    // scroll internal kalau isinya lebih dari yang muat.
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Donut((item['persen'] as num?) ?? 0),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _avatar(nama, _id, size: 44),
                const SizedBox(height: 8),
                Text(nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
                if (institusi.isNotEmpty) Text(institusi, style: const TextStyle(color: _abu)),
                if (jurusanAngkatan.isNotEmpty)
                  Text(jurusanAngkatan, style: const TextStyle(color: _abu, fontSize: 12)),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _navy, fontSize: 13, fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 8),
                _badge(item['label']?.toString() ?? ''),
              ]),
            ),
          ]),
          const SizedBox(height: 18),
          _sectionTitle('KENAPA KALIAN COCOK'),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: alasan.asMap().entries.map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration:
                          BoxDecoration(color: const Color(0xFFF6F8FB), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration:
                                BoxDecoration(color: dotWarna[e.key % dotWarna.length], shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(e.value, style: const TextStyle(color: _navy, height: 1.3))),
                      ]),
                    )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: () async {
                await Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => PartnerDetailPage(mahasiswaId: _id)));
                // Aksi (Simpan/Tertarik/Hubungkan) mungkin dilakukan dari halaman detail —
                // sinkronkan lagi status kartu ini begitu kembali, supaya tombolnya tidak ketinggalan.
                _sinkronStatus();
              },
              child: const Text('Lihat profil lengkap →', style: TextStyle(color: _biru, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            _kotakAksi(
              _disimpan ? Icons.bookmark : Icons.bookmark_border,
              _memuatSimpan
                  ? null
                  : () => _toggle(
                      aktifSaatIni: _disimpan,
                      postPath: '/people-to-people/saved',
                      deletePath: '/people-to-people/saved/$_id',
                      body: {'targetId': _id},
                      setMemuat: (v) => _memuatSimpan = v,
                      setAktif: (v) => _disimpan = v),
              aktif: _disimpan,
              memuat: _memuatSimpan,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _memuatTertarik
                    ? null
                    : () => _toggle(
                        aktifSaatIni: _tertarik,
                        postPath: '/people-to-people/interest',
                        deletePath: '/people-to-people/interest/$_id',
                        body: {'receiverId': _id},
                        setMemuat: (v) => _memuatTertarik = v,
                        setAktif: (v) => _tertarik = v),
                style: OutlinedButton.styleFrom(
                    backgroundColor: _tertarik ? _pinkMuda : null,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                    side: BorderSide(color: _tertarik ? _pink : const Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                child: _memuatTertarik
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (_tertarik) ...[
                            const Icon(Icons.favorite, size: 16, color: _pink),
                            const SizedBox(width: 6),
                          ],
                          Text('Tertarik',
                              style: TextStyle(color: _tertarik ? _pink : _navy, fontWeight: FontWeight.bold)),
                        ]),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _memuatHubungkan
                    ? null
                    : () => _toggle(
                        aktifSaatIni: _sudahHubungkan,
                        postPath: '/people-to-people/connect',
                        deletePath: '/people-to-people/connect/$_id',
                        body: {'receiverId': _id},
                        setMemuat: (v) => _memuatHubungkan = v,
                        setAktif: (v) => _sudahHubungkan = v),
                style: FilledButton.styleFrom(
                    backgroundColor: _sudahHubungkan ? const Color(0xFFEEF2FF) : _biru,
                    disabledBackgroundColor: _sudahHubungkan ? const Color(0xFFEEF2FF) : null,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                child: _memuatHubungkan
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (_sudahHubungkan) ...[
                            const Icon(Icons.check_circle, size: 16, color: _biru),
                            const SizedBox(width: 6),
                          ],
                          Text(_sudahHubungkan ? 'Terkirim' : 'Hubungkan',
                              style: TextStyle(
                                  color: _sudahHubungkan ? _biru : Colors.white, fontWeight: FontWeight.bold)),
                        ]),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            _kotakAksi(Icons.arrow_forward, widget.onSkip),
          ]),
        ]),
      ),
    );
  }
}

// ---------- DETAIL PROFIL PARTNER ----------
class PartnerDetailPage extends StatefulWidget {
  final String mahasiswaId;
  const PartnerDetailPage({super.key, required this.mahasiswaId});
  @override
  State<PartnerDetailPage> createState() => _PartnerDetailPageState();
}

class _PartnerDetailPageState extends State<PartnerDetailPage> {
  Map<String, dynamic>? _p;
  bool _loading = true;

  static const _labelAtribut = {
    'skill': 'Skill',
    'minat': 'Minat',
    'gayaKerja': 'Gaya kerja',
    'pengalaman': 'Pengalaman',
    'ketersediaan': 'Ketersediaan',
    'peran': 'Preferensi peran',
  };
  static const _komplementer = {'skill', 'peran'};

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final res = await apiGet('/people-to-people/profil/${widget.mahasiswaId}');
    setState(() {
      _p = res is Map ? Map<String, dynamic>.from(res) : null;
      _loading = false;
    });
  }

  // Toggle: kalau statusnya lagi aktif (sudah disimpan/tertarik/terkirim), tap lagi = undo (DELETE).
  Future<void> _toggle(bool aktifSaatIni, String postPath, String deletePath, Map<String, dynamic> body) async {
    try {
      final res = aktifSaatIni ? await apiDelete(deletePath) : await apiPost(postPath, body);
      if (mounted) {
        _snack(context, res is Map && res['pesan'] != null ? res['pesan'].toString() : 'Berhasil');
      }
      _muat();
    } catch (_) {
      if (mounted) _snack(context, 'Gagal terhubung ke server.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final p = _p;
    if (p == null || p['error'] != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil partner')),
        body: Center(child: Text(p?['error']?.toString() ?? 'Profil tidak tersedia')),
      );
    }
    final nama = p['nama']?.toString() ?? '-';
    final institusi = p['institusi']?.toString() ?? '';
    final jurusan = p['jurusan']?.toString() ?? '';
    final angkatan = p['angkatan'];
    final jurusanAngkatan =
        jurusan.isNotEmpty && angkatan != null ? '$jurusan · $angkatan' : (jurusan.isNotEmpty ? jurusan : '');
    final bio = p['bio']?.toString() ?? '';
    final affinity = p['affinity'] as Map?;
    final breakdown = affinity?['breakdown'] as Map?;
    final terhubung = p['terhubung'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil partner', style: TextStyle(fontWeight: FontWeight.bold, color: _navy)),
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
      ),
      bottomNavigationBar: terhubung ? null : _barAksi(),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          _Donut((affinity?['persen'] as num?) ?? 0, size: 92),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _navy)),
              if (institusi.isNotEmpty) Text(institusi, style: const TextStyle(color: _abu)),
              if (jurusanAngkatan.isNotEmpty)
                Text(jurusanAngkatan, style: const TextStyle(color: _abu, fontSize: 12)),
              const SizedBox(height: 8),
              Row(children: [
                Text('${(affinity?['persen'] as num?)?.round() ?? 0}% ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _navy, fontSize: 16)),
                _badge(affinity?['label']?.toString() ?? ''),
              ]),
            ]),
          ),
        ]),
        if (bio.isNotEmpty) ...[
          const SizedBox(height: 18),
          _sectionTitle('BIO'),
          const SizedBox(height: 10),
          Text(bio, style: const TextStyle(color: _navy, height: 1.4)),
        ],
        const SizedBox(height: 20),
        if (breakdown != null) ...[
          Row(children: [
            _sectionTitle('RINCIAN KECOCOKAN'),
            const SizedBox(width: 8),
            const Text('AffinityEngine', style: TextStyle(color: Color(0xFFB0B8C4))),
          ]),
          const SizedBox(height: 10),
          Builder(builder: (context) {
            final kunci = _labelAtribut.keys.where((k) => breakdown.containsKey(k)).toList();
            final semuaBobot = kunci.map((k) => ((breakdown[k] as Map)['bobot'] as num).toDouble()).toList();
            final minBobot = semuaBobot.reduce((a, b) => a < b ? a : b);
            final maxBobot = semuaBobot.reduce((a, b) => a > b ? a : b);
            return Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    children: kunci.map((k) {
                  final b = breakdown[k] as Map;
                  final skor = (b['skor'] as num).toDouble();
                  final bobot = (b['bobot'] as num).toDouble();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(_labelAtribut[k]!, style: const TextStyle(fontWeight: FontWeight.bold, color: _navy)),
                        const SizedBox(width: 8),
                        _tagRincian(_komplementer.contains(k) ? 'Komplementer' : 'Suplementer'),
                        const Spacer(),
                        Text('bobot ${bobot.toStringAsFixed(3).replaceAll('.', ',')}',
                            style: const TextStyle(color: Color(0xFFB0B8C4), fontSize: 12)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                            value: skor,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFEEF2F7),
                            valueColor: AlwaysStoppedAnimation(_warnaBobot(bobot, minBobot, maxBobot)),
                            borderRadius: BorderRadius.circular(999)),
                      ),
                    ]),
                  );
                }).toList()),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
        _sectionTitle('MINAT'),
        const SizedBox(height: 10),
        _chipList(((p['minat'] as List?) ?? []).cast<String>()),
        const SizedBox(height: 18),
        _sectionTitle('SKILL'),
        const SizedBox(height: 10),
        _chipList(((p['skill'] as List?) ?? []).cast<String>()),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: [
            _baris('Pengalaman', _teksPengalaman(p['pengalaman'])),
            const Divider(height: 1),
            _baris('Gaya kerja', p['gayaKerja']?.toString() ?? '-'),
            const Divider(height: 1),
            _baris('Preferensi peran', p['preferensiPeran']?.toString() ?? '-'),
          ]),
        ),
        const SizedBox(height: 18),
        _sectionTitle('KETERSEDIAAN WAKTU'),
        const SizedBox(height: 10),
        _chipList(((p['ketersediaanWaktu'] as List?) ?? []).cast<String>()),
        const SizedBox(height: 16),
        _kotakKontak(terhubung, p['kontak']?.toString()),
        const SizedBox(height: 8),
      ]),
    );
  }

  String _teksPengalaman(dynamic v) {
    switch (v) {
      case 1:
        return 'Pemula';
      case 2:
        return 'Menengah';
      case 3:
        return 'Mahir';
      default:
        return '-';
    }
  }

  Widget _kotakKontak(bool terhubung, String? kontak) {
    if (terhubung) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Icon(Icons.check_circle, color: _hijau),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('KONTAK', style: TextStyle(color: _hijau, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(kontak?.isNotEmpty == true ? kontak! : '(belum diisi)',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: _navy)),
            ]),
          ),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(children: [
        const Icon(Icons.lock_outline, size: 20, color: _abu),
        const SizedBox(width: 12),
        const Expanded(
          child: Text.rich(TextSpan(style: TextStyle(color: _abu, height: 1.4), children: [
            TextSpan(text: 'Kontak akan terbuka setelah kalian '),
            TextSpan(text: 'terhubung.', style: TextStyle(fontWeight: FontWeight.bold, color: _navy)),
          ])),
        ),
      ]),
    );
  }

  Widget _barAksi() => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        decoration: const BoxDecoration(
            color: Colors.white, boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 10)]),
        child: Row(children: [
          InkWell(
            onTap: () => _toggle(_p?['sudahDisimpan'] == true, '/people-to-people/saved',
                '/people-to-people/saved/${widget.mahasiswaId}', {'targetId': widget.mahasiswaId}),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 52,
              height: 48,
              decoration: BoxDecoration(
                  color: (_p?['sudahDisimpan'] == true) ? const Color(0xFFEEF2FF) : null,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: (_p?['sudahDisimpan'] == true) ? _biru : const Color(0xFFE2E8F0))),
              child: Icon(
                  (_p?['sudahDisimpan'] == true) ? Icons.bookmark : Icons.bookmark_border,
                  color: (_p?['sudahDisimpan'] == true) ? _biru : _navy),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _toggle(_p?['sudahTertarik'] == true, '/people-to-people/interest',
                  '/people-to-people/interest/${widget.mahasiswaId}', {'receiverId': widget.mahasiswaId}),
              icon: Icon(
                  (_p?['sudahTertarik'] == true) ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: (_p?['sudahTertarik'] == true) ? _pink : _navy),
              label: Text('Tertarik',
                  style: TextStyle(
                      color: (_p?['sudahTertarik'] == true) ? _pink : _navy, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                  backgroundColor: (_p?['sudahTertarik'] == true) ? _pinkMuda : null,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: (_p?['sudahTertarik'] == true) ? _pink : const Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: () => _toggle(_p?['sudahKirimPermintaan'] == true, '/people-to-people/connect',
                  '/people-to-people/connect/${widget.mahasiswaId}', {'receiverId': widget.mahasiswaId}),
              style: FilledButton.styleFrom(
                  backgroundColor: (_p?['sudahKirimPermintaan'] == true) ? const Color(0xFFEEF2FF) : _biru,
                  disabledBackgroundColor:
                      (_p?['sudahKirimPermintaan'] == true) ? const Color(0xFFEEF2FF) : null,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (_p?['sudahKirimPermintaan'] == true) ...[
                    const Icon(Icons.check_circle, size: 16, color: _biru),
                    const SizedBox(width: 6),
                  ],
                  Text((_p?['sudahKirimPermintaan'] == true) ? 'Terkirim' : 'Hubungkan',
                      style: TextStyle(
                          color: (_p?['sudahKirimPermintaan'] == true) ? _biru : Colors.white,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
        ]),
      );

  Widget _tagRincian(String tag) {
    final biru = tag == 'Komplementer';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: biru ? const Color(0xFFEEF2FF) : const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20)),
      child: Text(tag, style: TextStyle(color: biru ? _biru : _hijau, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _baris(String kiri, String kanan) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(kiri, style: const TextStyle(color: _abu)),
          Text(kanan, style: const TextStyle(fontWeight: FontWeight.bold, color: _navy)),
        ]),
      );
}

// ---------- TAB KONEKSI ----------
class _KoneksiTab extends StatefulWidget {
  // (jumlah permintaan pending, jumlah koneksi baru yang belum dilihat)
  final void Function(int permintaan, int koneksiBaru)? onJumlahBerubah;
  const _KoneksiTab({this.onJumlahBerubah});
  @override
  State<_KoneksiTab> createState() => _KoneksiTabState();
}

class _KoneksiTabState extends State<_KoneksiTab> {
  int _sub = 1; // default Permintaan
  bool _loading = true;
  List<dynamic> _terhubung = [];
  List<dynamic> _permintaan = [];
  List<dynamic> _disimpan = [];
  int _jumlahMenyukai = 0;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    if (authToken == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final c = await apiGet('/people-to-people/connections');
      final r = await apiGet('/people-to-people/requests');
      final s = await apiGet('/people-to-people/saved');
      final m = await apiGet('/people-to-people/menyukai-saya');
      setState(() {
        _terhubung = (c is Map && c['koneksi'] is List) ? c['koneksi'] as List : [];
        _permintaan = (r is Map && r['permintaan'] is List) ? r['permintaan'] as List : [];
        _disimpan = (s is Map && s['saved'] is List) ? s['saved'] as List : [];
        _jumlahMenyukai = (m is Map && m['jumlah'] is int) ? m['jumlah'] as int : 0;
      });
      widget.onJumlahBerubah?.call(_permintaan.length, _hitungKoneksiBaru());
    } catch (_) {
      // biarkan kosong
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _hitungKoneksiBaru() =>
      _terhubung.where((o) => !_koneksiTerlihat.contains((o as Map)['mahasiswaId'].toString())).length;

  void _tandaiKoneksiTerlihat() {
    _koneksiTerlihat.addAll(_terhubung.map((o) => (o as Map)['mahasiswaId'].toString()));
    widget.onJumlahBerubah?.call(_permintaan.length, _hitungKoneksiBaru());
  }

  Future<void> _respons(String requestId, String aksi) async {
    try {
      final res = await apiPatch('/people-to-people/connect/$requestId', {'aksi': aksi});
      if (mounted) _snack(context, res is Map && res['pesan'] != null ? res['pesan'].toString() : 'Selesai');
      _muat();
    } catch (_) {
      if (mounted) _snack(context, 'Gagal terhubung ke server.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _subTabs(),
      const SizedBox(height: 16),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(onRefresh: _muat, child: _isi()),
      ),
    ]);
  }

  Widget _subTabs() {
    Widget seg(String label, int i, {bool dotBaru = false}) {
      final aktif = _sub == i;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() => _sub = i);
            if (i == 0) _tandaiKoneksiTerlihat();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
            decoration: BoxDecoration(
              color: aktif ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: aktif ? [const BoxShadow(color: Color(0x14000000), blurRadius: 6)] : null,
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700, color: aktif ? _biru : _abu, fontSize: 12)),
                if (dotBaru) ...[
                  const SizedBox(width: 5),
                  Container(
                      width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle)),
                ],
              ]),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFEEF2F7), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        seg('Terhubung', 0, dotBaru: _hitungKoneksiBaru() > 0),
        seg('Permintaan', 1, dotBaru: _permintaan.isNotEmpty),
        seg('Disimpan', 2),
        seg('Menyukai', 3),
      ]),
    );
  }

  Widget _isi() {
    if (_sub == 0) {
      if (_terhubung.isEmpty) {
        return _listKosong(Icons.link, 'Belum ada koneksi',
            'Koneksi terbentuk lewat Hubungkan yang diterima, atau saat kalian saling tertarik.');
      }
      return ListView(children: _terhubung.map((o) => _kartuTerhubung(o as Map)).toList());
    }
    if (_sub == 1) {
      if (_permintaan.isEmpty) {
        return _listKosong(Icons.mail_outline, 'Belum ada permintaan', 'Permintaan koneksi masuk akan muncul di sini.');
      }
      return ListView(children: _permintaan.map((o) => _kartuPermintaan(o as Map)).toList());
    }
    if (_sub == 2) {
      if (_disimpan.isEmpty) {
        return _listKosong(Icons.bookmark_border, 'Belum ada yang disimpan',
            'Tekan ikon simpan pada kartu rekomendasi untuk menyimpan profil.');
      }
      return ListView(children: _disimpan.map((o) => _kartuDisimpan(o as Map)).toList());
    }
    return _isiMenyukai();
  }

  // Identitas yang menyukai kita sengaja dirahasiakan (cuma jumlah) — supaya tahu siapa,
  // kamu harus menandai "Tertarik" balik lewat rekomendasi/pencarian biasa; kalau ternyata
  // sama-sama tertarik, koneksi otomatis terbentuk (lihat POST /interest).
  Widget _isiMenyukai() => ListView(children: [
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _pinkMuda,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFBCFE8)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.favorite, color: _pink, size: 40),
                const SizedBox(height: 12),
                Text('$_jumlahMenyukai',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _pink)),
                const SizedBox(height: 4),
                Text(_jumlahMenyukai == 1 ? 'orang menyukaimu' : 'orang menyukaimu',
                    style: const TextStyle(color: _navy, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                  'Identitasnya dirahasiakan. Terus jelajahi rekomendasi, dan kalau kamu juga\n'
                  'menandai "Tertarik" ke salah satu dari mereka, kalian akan otomatis terhubung.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _abu, height: 1.4),
                ),
              ]),
            ),
          ),
        ),
      ]);

  Widget _listKosong(IconData icon, String judul, String sub) => ListView(children: [
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: _EmptyState(icon: icon, judul: judul, subtitle: sub, tombol: 'Muat ulang', onTombol: _muat),
        )
      ]);

  Widget _kartuPermintaan(Map o) {
    final nama = o['nama']?.toString() ?? '-';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _avatar(nama, o['senderId'].toString(), size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _navy)),
                if ((o['institusi']?.toString() ?? '').isNotEmpty)
                  Text(o['institusi'].toString(), style: const TextStyle(color: _abu, fontSize: 13)),
              ]),
            ),
            _badge(o['label']?.toString() ?? ''),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF6F8FB), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.mail_outline, size: 18, color: _abu),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('Mengirim permintaan koneksi · ${o['persen']}% cocok',
                      style: const TextStyle(color: _navy, height: 1.3))),
            ]),
          ),
          _lihatProfil(context, o['senderId'].toString()),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _respons(o['requestId'].toString(), 'REJECTED'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                child: const Text('Tolak', style: TextStyle(color: _navy, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: () => _respons(o['requestId'].toString(), 'ACCEPTED'),
                style: FilledButton.styleFrom(
                    backgroundColor: _biru,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                child: const Text('Terima koneksi', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // Subtitle kartu koneksi: "jurusan · angkatan" kalau ada, fallback ke institusi.
  String _subJurusan(Map o) {
    final jurusan = o['jurusan']?.toString() ?? '';
    final angkatan = o['angkatan'];
    if (jurusan.isNotEmpty && angkatan != null) return '$jurusan · $angkatan';
    if (jurusan.isNotEmpty) return jurusan;
    return o['institusi']?.toString() ?? '';
  }

  Widget _badgeAsal(String asal) {
    final interest = asal == 'INTEREST';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: interest ? _pinkMuda : const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(interest ? Icons.favorite : Icons.link, size: 13, color: interest ? _pink : _hijau),
        const SizedBox(width: 4),
        Text(interest ? 'Saling tertarik' : 'Via koneksi',
            style: TextStyle(color: interest ? _pink : _hijau, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _kartuTerhubung(Map o) {
    final nama = o['nama']?.toString() ?? '-';
    final sub = _subJurusan(o);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _avatar(nama, o['mahasiswaId'].toString(), size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _navy)),
                if (sub.isNotEmpty) Text(sub, style: const TextStyle(color: _abu, fontSize: 13)),
              ]),
            ),
            _badgeAsal(o['asal']?.toString() ?? 'REQUEST'),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.contact_phone, size: 20, color: _hijau),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('KONTAK', style: TextStyle(color: _hijau, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text((o['kontak']?.toString().isNotEmpty ?? false) ? o['kontak'].toString() : '(belum diisi)',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: _navy)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: const Text('Terbuka', style: TextStyle(color: _hijau, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ]),
          ),
          _lihatProfil(context, o['mahasiswaId'].toString()),
        ]),
      ),
    );
  }

  Widget _kartuDisimpan(Map o) {
    final nama = o['nama']?.toString() ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _avatar(nama.isEmpty ? '?' : nama, o['targetId'].toString(), size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nama.isNotEmpty ? nama : 'Profil tidak tersedia',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _navy)),
                if ((o['institusi']?.toString() ?? '').isNotEmpty)
                  Text(o['institusi'].toString(), style: const TextStyle(color: _abu, fontSize: 13)),
              ]),
            ),
            if (nama.isNotEmpty) _badge(o['label']?.toString() ?? ''),
          ]),
          if (nama.isNotEmpty) _lihatProfil(context, o['targetId'].toString()),
        ]),
      ),
    );
  }

}

// ---------- EMPTY STATE ----------
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String judul, subtitle, tombol;
  final VoidCallback onTombol;
  const _EmptyState(
      {required this.icon,
      required this.judul,
      required this.subtitle,
      required this.tombol,
      required this.onTombol});
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(radius: 32, backgroundColor: const Color(0xFFE8EDF5), child: Icon(icon, color: _biru)),
            const SizedBox(height: 14),
            Text(judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _navy)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: _abu, height: 1.4)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onTombol,
              style: FilledButton.styleFrom(
                  backgroundColor: _biru, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
              child: Text(tombol, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      );
}
