import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import '../api.dart';
import '../design_system.dart';

// Modul People-to-Project (Faishal). Tersambung ke /api/people-to-project.
// Desain mengikuti design system bersama (lihat design_system.dart).
// 3 tab: Rekomendasi / Terdaftar / Proyek Saya.

const _biru = DS.active;
const _navy = DS.primaryText;
const _abu = DS.secondaryText;
const _hijau = DS.success;
const _amber = DS.warning;

// Dipakai tur onboarding (lihat main.dart) — target elemen statis yang selalu ada.
final GlobalKey tourP2PToggleKey = GlobalKey();

// badge backend: hijau/kuning/abu -> label & warna
String _badgeLabel(String b) {
  switch (b) {
    case 'hijau':
      return 'Sangat Cocok';
    case 'kuning':
      return 'Cocok';
    case 'abu':
      return 'Cukup Cocok';
    default:
      return '';
  }
}

Color _badgeFg(String b) =>
    b == 'hijau' ? _hijau : (b == 'kuning' ? _amber : _abu);
Color _badgeBg(String b) => b == 'hijau'
    ? const Color(0xFFDCFCE7)
    : (b == 'kuning' ? const Color(0xFFFEF3C7) : const Color(0xFFEEF2F7));

Widget _badgeChip(String badge) {
  final label = _badgeLabel(badge);
  if (label.isEmpty) return const SizedBox.shrink();
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
        color: _badgeBg(badge), borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: TextStyle(
            color: _badgeFg(badge), fontWeight: FontWeight.bold, fontSize: 12)),
  );
}

IconData _ikonKontak(String? jenis) {
  switch (jenis) {
    case 'WHATSAPP':
      return Icons.phone;
    case 'LINE':
      return Icons.chat_bubble_outline;
    case 'LINKEDIN':
      return Icons.work_outline;
    default:
      return Icons.email_outlined;
  }
}

// "· Teknik Industri · 2022" — format sama dengan people_to_people.dart agar konsisten.
String _jurusanAngkatan(dynamic jurusan, dynamic angkatan) {
  final j = jurusan?.toString() ?? '';
  if (j.isEmpty && angkatan == null) return '';
  if (j.isEmpty) return ' · $angkatan';
  return angkatan != null ? ' · $j · $angkatan' : ' · $j';
}

// Ikon ditebak dari kata kunci di judul proyek (bukan field terpisah) — di luar kata
// kunci yang dikenal / judul kosong, jatuh ke ikon umum (Icons.work_rounded).
IconData _ikonJudul(String? judul) {
  final j = (judul ?? '').toLowerCase();
  if (j.contains('aplikasi') ||
      j.contains(' app') ||
      j.contains('website') ||
      j.contains('sistem')) {
    return Icons.smartphone_rounded;
  }
  if (j.contains('riset') || j.contains('penelitian'))
    return Icons.science_rounded;
  if (j.contains('desain') || j.contains('ui/ux') || j.contains('grafis'))
    return Icons.palette_rounded;
  if (j.contains('kompetisi') || j.contains('lomba'))
    return Icons.emoji_events_rounded;
  if (j.contains('kkn') || j.contains('pengabdian') || j.contains('relawan')) {
    return Icons.volunteer_activism_rounded;
  }
  if (j.contains('wirausaha') ||
      j.contains('bisnis') ||
      j.contains('startup')) {
    return Icons.rocket_launch_rounded;
  }
  return Icons.work_rounded; // lainnya / tidak cocok kata kunci apa pun
}

Widget _ikonKotak({double size = 52, String? judul}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1F5FF), Color(0xFFE0E9FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _biru.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Icon(_ikonJudul(judul), color: _biru, size: size * 0.46),
    );

Widget _chipList(List<String> items) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((s) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFFEEF2F7),
                    borderRadius: BorderRadius.circular(20)),
                child:
                    Text(s, style: const TextStyle(color: _navy, fontSize: 13)),
              ))
          .toList(),
    );

Widget _sectionTitle(String t) => Text(t,
    style: const TextStyle(
        color: _biru, fontWeight: FontWeight.bold, letterSpacing: 0.5));

// Judul section "RINCIAN KECOCOKAN" + ikon bantuan kecil buat jelasin skornya ke
// user awam, dipakai konsisten di Detail Proyek & Profil Pendaftar.
Widget _judulRincianKecocokan(BuildContext context) => Row(children: [
      _sectionTitle('RINCIAN KECOCOKAN'),
      const SizedBox(width: 4),
      InkWell(
        onTap: () => _jelaskanSkorProyek(context),
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.help_outline, size: 16, color: _abu),
        ),
      ),
    ]);

// Penjelasan skor buat user awam — jelaskan konsepnya saja, tanpa rumus/bobot.
void _jelaskanSkorProyek(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Kenapa skor ini?',
          style: TextStyle(fontWeight: FontWeight.bold, color: _navy)),
      content: const Text(
        'Skor kecocokan dilihat dari beberapa hal: skill, minat, gaya kerja, dan pengalaman.\n\n'
        'Untuk skill dan pengalaman, dilihat dari seberapa besar kemampuanmu memenuhi kebutuhan '
        'peran di proyek ini.\n\n'
        'Untuk minat dan gaya kerja, dilihat dari seberapa cocok kamu dengan suasana dan tujuan '
        'proyeknya.\n\n'
        'Semuanya digabung jadi satu skor akhir yang kamu lihat di atas.',
        style: TextStyle(color: _navy, height: 1.5),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mengerti',
                style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    ),
  );
}

// Judul section generik + ikon bantuan kecil, dipakai buat "DESKRIPSI" dan
// "PERAN DIBUTUHKAN" baik di Detail Proyek maupun form Buat Proyek.
Widget _judulBantuan(String judul, VoidCallback onTap) => Row(children: [
      _sectionTitle(judul),
      const SizedBox(width: 4),
      InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.help_outline, size: 16, color: _abu),
        ),
      ),
    ]);

void _jelaskanDeskripsiProyek(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Apa isi Deskripsi?',
          style: TextStyle(fontWeight: FontWeight.bold, color: _navy)),
      content: const Text(
        'Bagian ini berisi penjelasan dari pembuat proyek, seperti latar belakang, tujuan, atau '
        'hal-hal yang perlu diketahui sebelum ikut bergabung.\n\n'
        'Kalau kamu yang membuat proyek, tulis deskripsi yang jelas supaya calon anggota tahu '
        'persis apa yang akan mereka kerjakan dan apa yang kamu harapkan dari mereka.',
        style: TextStyle(color: _navy, height: 1.5),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mengerti',
                style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    ),
  );
}

void _jelaskanPeranDibutuhkan(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Apa saja peran ini?',
          style: TextStyle(fontWeight: FontWeight.bold, color: _navy)),
      content: const Text(
        'Setiap proyek punya beberapa peran yang bisa dipilih anggota saat mendaftar:\n\n'
        'Leader/Coordinator: memimpin dan mengatur jalannya proyek, membagi tugas, dan memastikan '
        'semua berjalan sesuai rencana.\n\n'
        'Contributor/Executor: mengerjakan tugas teknis secara langsung, jadi tulang punggung '
        'eksekusi proyek.\n\n'
        'Supporter/Facilitator: membantu dari sisi pendukung, seperti komunikasi, dokumentasi, '
        'atau menjaga kelancaran kerja sama tim.\n\n'
        'Pilih atau tawarkan peran yang paling sesuai dengan kebutuhan proyekmu.',
        style: TextStyle(color: _navy, height: 1.5),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mengerti',
                style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    ),
  );
}

// Bar pencarian dipakai di 3 tab (Rekomendasi/Terdaftar/Proyek Saya) — filter lokal by judul.
Widget _searchBar(TextEditingController c,
        {String hint = 'Cari judul proyek...',
        ValueChanged<String>? onChanged}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: c,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _abu),
          prefixIcon: const Icon(Icons.search, color: _abu),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );

// Dropdown filter dipakai di 3 tab — tampil sebagai pill kecil + panah, tap buka menu.
// `opsi` urut key->label (LinkedHashMap-friendly lewat literal Map biasa).
Widget _dropdownFilter({
  required String value,
  required Map<String, String> opsi,
  required ValueChanged<String> onChanged,
}) =>
    PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => opsi.entries
          .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(opsi[value] ?? value,
              style: const TextStyle(
                  color: _navy, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _abu),
        ]),
      ),
    );

void _snack(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

class _Donut extends StatelessWidget {
  final num persen;
  final double size;
  const _Donut(this.persen, {this.size = 92});
  @override
  Widget build(BuildContext context) {
    final warna = persen >= 85 ? _hijau : (persen >= 60 ? _amber : _abu);
    return DsRadialGauge(
      percent: persen,
      size: size,
      filledColor: warna,
      center: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${persen.round()}%',
            style: TextStyle(
                fontSize: size * 0.2,
                fontWeight: FontWeight.bold,
                color: _navy)),
        Text('KECOCOKAN',
            style: TextStyle(
                fontSize: size * 0.08,
                color: _abu,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

const _labelAtribut = {
  'minat': 'Minat ⇄ Bidang',
  'skill': 'Skill ⇄ Kebutuhan',
  'peran': 'Preferensi peran',
  'gayaKerja': 'Gaya kerja',
  'pengalaman': 'Pengalaman',
};

// Kartu "RINCIAN KECOCOKAN" — dipakai di Detail Proyek & Profil Pendaftar agar konsisten.
Widget _rincianKecocokan(Map breakdown) => Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            children: _labelAtribut.keys
                .where((k) => breakdown.containsKey(k))
                .map((k) {
          final skor = ((breakdown[k] as Map)['skor'] as num).toDouble();
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_labelAtribut[k]!,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: _navy)),
                Text('${(skor * 100).round()}%',
                    style: const TextStyle(color: _abu, fontSize: 12)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                    value: skor,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFEEF2F7),
                    valueColor: const AlwaysStoppedAnimation(_hijau),
                    borderRadius: BorderRadius.circular(999)),
              ),
            ]),
          );
        }).toList()),
      ),
    );

// ================= HALAMAN UTAMA =================
class PeopleToProjectPage extends StatefulWidget {
  const PeopleToProjectPage({super.key});
  @override
  State<PeopleToProjectPage> createState() => _PeopleToProjectPageState();
}

class _PeopleToProjectPageState extends State<PeopleToProjectPage> {
  int _tab = 0;
  int _jumlahPendingPendaftar = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            const SizedBox(height: 8),
            Showcase(
              key: tourP2PToggleKey,
              title: 'Jelajahi Proyek',
              description:
                  'Cari rekomendasi proyek yang cocok, lihat yang sudah kamu daftar, atau kelola proyek buatanmu sendiri di sini.',
              child: _toggle(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  const _RekomendasiTab(),
                  const _TerdaftarTab(),
                  _ProyekSayaTab(
                    onJumlahBerubah: (j) {
                      if (mounted) setState(() => _jumlahPendingPendaftar = j);
                    },
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _toggle() {
    Widget seg(String label, int i, {int badge = 0}) {
      final aktif = _tab == i;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = i),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: aktif ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: aktif
                  ? [const BoxShadow(color: Color(0x14000000), blurRadius: 8)]
                  : null,
            ),
            alignment: Alignment.center,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: aktif ? _biru : _abu,
                      fontSize: 13)),
              if (badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(
                      color: Color(0xFFDC2626), shape: BoxShape.circle),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text('$badge',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ]),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: const Color(0xFFEEF2F7),
          borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        seg('Rekomendasi', 0),
        seg('Terdaftar', 1),
        seg('Proyek Saya', 2, badge: _jumlahPendingPendaftar),
      ]),
    );
  }
}

// ================= TAB 1: REKOMENDASI =================
class _RekomendasiTab extends StatefulWidget {
  const _RekomendasiTab();
  @override
  State<_RekomendasiTab> createState() => _RekomendasiTabState();
}

class _RekomendasiTabState extends State<_RekomendasiTab>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _feed = [];
  bool _loading = true;
  String? _pesan;
  final _search = TextEditingController();
  String _filterBadge = 'semua';

  static const _badgeOpsi = {
    'semua': 'Semua',
    'hijau': 'Sangat Cocok',
    'kuning': 'Cocok',
    'abu': 'Cukup Cocok',
  };

  List<dynamic> get _feedFiltered {
    final q = _search.text.trim().toLowerCase();
    return _feed.where((e) {
      final cocokJudul =
          q.isEmpty || (e['judul']?.toString() ?? '').toLowerCase().contains(q);
      final cocokBadge =
          _filterBadge == 'semua' || e['badge']?.toString() == _filterBadge;
      return cocokJudul && cocokBadge;
    }).toList();
  }

  @override
  bool get wantKeepAlive => true;

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
    setState(() => _loading = true);
    try {
      final res = await apiGet('/people-to-project/feed');
      final feed =
          (res is Map && res['feed'] is List) ? res['feed'] as List : [];
      setState(() {
        _feed = feed;
        _pesan = feed.isEmpty
            ? ((res is Map ? res['error']?.toString() : null) ??
                'Belum ada rekomendasi.')
            : null;
      });
    } catch (_) {
      setState(() => _pesan = 'Gagal memuat. Pastikan backend jalan.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView(children: [
        const SizedBox(height: 4),
        const Text('Proyek & kegiatan',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: _navy)),
        const Text('Diurutkan dari kecocokan profilmu (person-job fit)',
            style: TextStyle(color: _abu)),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: _searchBar(_search, onChanged: (_) => setState(() {}))),
          const SizedBox(width: 8),
          _dropdownFilter(
            value: _filterBadge,
            opsi: _badgeOpsi,
            onChanged: (v) => setState(() => _filterBadge = v),
          ),
        ]),
        if (_feedFiltered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: _EmptyState(
              icon: Icons.auto_awesome,
              judul: _feed.isEmpty
                  ? (_pesan ?? 'Belum ada rekomendasi')
                  : 'Tidak ditemukan',
              subtitle: _feed.isEmpty
                  ? 'Lengkapi profilmu atau tunggu proyek baru muncul sesuai kecocokanmu.'
                  : 'Coba kata kunci lain.',
              tombol: 'Muat ulang',
              onTombol: _muat,
            ),
          )
        else
          ..._feedFiltered.map((e) => _kartuFeed(e as Map)),
      ]),
    );
  }

  Widget _kartuFeed(Map item) {
    final id = item['projectId'].toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => DetailProjectPage(projectId: id)));
          _muat();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _ikonKotak(judul: item['judul']?.toString()),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(item['judul']?.toString() ?? '-',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: _navy)),
                        ),
                        _badgeChip(item['badge']?.toString() ?? ''),
                      ]),
                    ]),
              ),
            ]),
            const Divider(height: 20),
            Row(children: [
              const Icon(Icons.confirmation_number_outlined,
                  size: 16, color: _hijau),
              const SizedBox(width: 4),
              Text('${item['slotTerbuka'] ?? 0} slot terbuka',
                  style: const TextStyle(
                      color: _hijau,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${item['skorPersen']}%',
                  style: const TextStyle(
                      color: _biru, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ================= TAB 2: TERDAFTAR =================
class _TerdaftarTab extends StatefulWidget {
  const _TerdaftarTab();
  @override
  State<_TerdaftarTab> createState() => _TerdaftarTabState();
}

class _TerdaftarTabState extends State<_TerdaftarTab> {
  List<dynamic> _rows = [];
  bool _loading = true;
  final _search = TextEditingController();
  String _filterStatus = 'semua';

  static const _statusOpsi = {
    'semua': 'Semua',
    'menunggu': 'Menunggu',
    'selesai': 'Selesai'
  };

  List<dynamic> get _rowsFiltered {
    final q = _search.text.trim().toLowerCase();
    return _rows.where((e) {
      final cocokJudul =
          q.isEmpty || (e['judul']?.toString() ?? '').toLowerCase().contains(q);
      final status = e['status']?.toString();
      final cocokStatus = _filterStatus == 'semua' ||
          (_filterStatus == 'menunggu' && status == 'PENDING') ||
          (_filterStatus == 'selesai' &&
              (status == 'ACCEPTED' || status == 'REJECTED'));
      return cocokJudul && cocokStatus;
    }).toList();
  }

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
      final res = await apiGet('/people-to-project/terdaftar');
      setState(() => _rows = res is List ? res : []);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusFg(String s) => s == 'ACCEPTED'
      ? _hijau
      : (s == 'REJECTED' ? const Color(0xFFDC2626) : _amber);
  Color _statusBg(String s) => s == 'ACCEPTED'
      ? const Color(0xFFDCFCE7)
      : (s == 'REJECTED' ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7));
  String _statusLabel(String s) =>
      s == 'ACCEPTED' ? 'Diterima' : (s == 'REJECTED' ? 'Ditolak' : 'Menunggu');

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView(children: [
        const SizedBox(height: 4),
        const Text('Proyek terdaftar',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: _navy)),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: _searchBar(_search, onChanged: (_) => setState(() {}))),
          const SizedBox(width: 8),
          _dropdownFilter(
            value: _filterStatus,
            opsi: _statusOpsi,
            onChanged: (v) => setState(() => _filterStatus = v),
          ),
        ]),
        if (_rowsFiltered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: _EmptyState(
              icon: Icons.assignment_outlined,
              judul: _rows.isEmpty
                  ? 'Belum mendaftar ke proyek mana pun'
                  : 'Tidak ditemukan',
              subtitle: _rows.isEmpty
                  ? 'Daftar dari tab Rekomendasi untuk mulai mengikuti kegiatan.'
                  : 'Coba kata kunci lain.',
              tombol: 'Muat ulang',
              onTombol: _muat,
            ),
          )
        else
          ..._rowsFiltered.map((e) => _kartu(e as Map)),
      ]),
    );
  }

  Widget _kartu(Map r) {
    final status = r['status']?.toString() ?? 'PENDING';
    final kontak = r['kontakPembuat']?.toString();
    final adaKontak = status == 'ACCEPTED' && (kontak?.isNotEmpty ?? false);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(
                builder: (_) =>
                    DetailProjectPage(projectId: r['projectId'].toString())))
            .then((_) => _muat()),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _ikonKotak(size: 46, judul: r['judul']?.toString()),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['judul']?.toString() ?? '-',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _navy)),
                      const SizedBox(height: 2),
                      Text(r['role']?.toString() ?? '',
                          style: const TextStyle(color: _abu, fontSize: 13)),
                    ]),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: _statusBg(status),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(_statusLabel(status),
                    style: TextStyle(
                        color: _statusFg(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ]),
            if (adaKontak) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Icon(_ikonKontak(r['kontakJenisPembuat']?.toString()),
                      size: 18, color: _hijau),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'KONTAK PEMBUAT · ${r['namaPembuat'] ?? ''} · ${r['kontakJenisPembuat'] ?? 'EMAIL'}',
                              style: const TextStyle(
                                  color: _hijau,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                          Text(kontak!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _navy,
                                  fontSize: 13)),
                        ]),
                  ),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

// ================= TAB 3: PROYEK SAYA =================
class _ProyekSayaTab extends StatefulWidget {
  const _ProyekSayaTab({this.onJumlahBerubah});
  final void Function(int jumlahPendingPendaftar)? onJumlahBerubah;
  @override
  State<_ProyekSayaTab> createState() => _ProyekSayaTabState();
}

class _ProyekSayaTabState extends State<_ProyekSayaTab> {
  List<dynamic> _rows = [];
  bool _loading = true;
  final _search = TextEditingController();
  String _filterKuota = 'semua';

  static const _kuotaOpsi = {
    'semua': 'Semua',
    'penuh': 'Penuh',
    'belum': 'Belum Penuh'
  };

  List<dynamic> get _rowsFiltered {
    final q = _search.text.trim().toLowerCase();
    return _rows.where((e) {
      final cocokJudul =
          q.isEmpty || (e['judul']?.toString() ?? '').toLowerCase().contains(q);
      final terisi = (e['terisi'] as num?)?.toInt() ?? 0;
      final totalKuota = (e['totalKuota'] as num?)?.toInt() ?? 0;
      final penuh = totalKuota > 0 && terisi >= totalKuota;
      final cocokKuota = _filterKuota == 'semua' ||
          (_filterKuota == 'penuh' && penuh) ||
          (_filterKuota == 'belum' && !penuh);
      return cocokJudul && cocokKuota;
    }).toList();
  }

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
      final res = await apiGet('/people-to-project/saya');
      setState(() => _rows = res is List ? res : []);
      final total = _rows.fold<int>(
          0, (s, r) => s + (((r as Map)['pendingBaru'] as num?)?.toInt() ?? 0));
      widget.onJumlahBerubah?.call(total);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView(children: [
        const SizedBox(height: 4),
        Row(children: [
          const Expanded(
            child: Text('Proyek saya',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: _navy)),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BuatProjectPage()));
              _muat();
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Buat'),
            style: FilledButton.styleFrom(
                backgroundColor: _biru,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
          ),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: _searchBar(_search, onChanged: (_) => setState(() {}))),
          const SizedBox(width: 8),
          _dropdownFilter(
            value: _filterKuota,
            opsi: _kuotaOpsi,
            onChanged: (v) => setState(() => _filterKuota = v),
          ),
        ]),
        if (_rowsFiltered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: _EmptyState(
              icon: Icons.add_circle_outline,
              judul: _rows.isEmpty ? 'Belum membuat proyek' : 'Tidak ditemukan',
              subtitle: _rows.isEmpty
                  ? 'Buat kegiatan kolaboratif pertamamu dan temukan mahasiswa yang cocok.'
                  : 'Coba kata kunci lain.',
              tombol: _rows.isEmpty ? 'Buat proyek' : 'Muat ulang',
              onTombol: _rows.isEmpty
                  ? () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const BuatProjectPage()));
                      _muat();
                    }
                  : _muat,
            ),
          )
        else
          ..._rowsFiltered.map((e) => _kartu(e as Map)),
      ]),
    );
  }

  Widget _kartu(Map r) {
    final pendingBaru = (r['pendingBaru'] as num?)?.toInt() ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _ikonKotak(judul: r['judul']?.toString()),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Expanded(
                        child: Text('Dibuat olehmu',
                            style: TextStyle(
                                color: _abu,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (pendingBaru > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('$pendingBaru baru',
                              style: const TextStyle(
                                  color: _amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    Text(r['judul']?.toString() ?? '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: _navy)),
                  ]),
            ),
          ]),
          const Divider(height: 20),
          Row(children: [
            const Icon(Icons.people_alt_outlined, size: 16, color: _abu),
            const SizedBox(width: 4),
            Text('${r['totalPendaftar'] ?? 0} pendaftar',
                style: const TextStyle(color: _abu, fontSize: 13)),
            const SizedBox(width: 14),
            const Icon(Icons.check_box_outlined, size: 16, color: _hijau),
            const SizedBox(width: 4),
            Text('${r['terisi'] ?? 0}/${r['totalKuota'] ?? 0} terisi',
                style: const TextStyle(
                    color: _hijau, fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => KelolaProjectPage(
                        projectId: r['projectId'].toString())));
                _muat();
              },
              child: const Text('Kelola →',
                  style: TextStyle(color: _biru, fontWeight: FontWeight.bold)),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ================= DETAIL PROYEK =================
class DetailProjectPage extends StatefulWidget {
  final String projectId;
  const DetailProjectPage({super.key, required this.projectId});
  @override
  State<DetailProjectPage> createState() => _DetailProjectPageState();
}

class _DetailProjectPageState extends State<DetailProjectPage> {
  Map<String, dynamic>? _p;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final res = await apiGet('/people-to-project/projects/${widget.projectId}');
    setState(() {
      _p = res is Map ? Map<String, dynamic>.from(res) : null;
      _loading = false;
    });
  }

  Future<void> _daftar(String roleId) async {
    final res = await apiPost(
        '/people-to-project/projects/${widget.projectId}/daftar',
        {'roleId': roleId});
    if (!mounted) return;
    final pesan = res is Map && res['error'] != null
        ? res['error'].toString()
        : 'Pendaftaran diajukan (menunggu konfirmasi).';
    _snack(context, pesan);
    _muat();
  }

  Future<void> _batalkan(String pendaftaranId) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan pendaftaran?'),
        content: const Text('Kamu bisa mendaftar lagi kapan saja setelah ini.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Ya, batalkan'),
          ),
        ],
      ),
    );
    if (yakin != true) return;
    final res =
        await apiDelete('/people-to-project/pendaftaran/$pendaftaranId');
    if (!mounted) return;
    final pesan = res is Map && res['error'] != null
        ? res['error'].toString()
        : 'Pendaftaran dibatalkan.';
    _snack(context, pesan);
    _muat();
  }

  void _pilihRole(List roles) {
    final terbuka = roles.where((r) => (r['sisaKuota'] as num) > 0).toList();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daftar sebagai',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _navy)),
                const SizedBox(height: 12),
                ...terbuka.map((r) => ListTile(
                      title: Text(r['namaRole']?.toString() ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Sisa ${r['sisaKuota']} slot'),
                      trailing: const Icon(Icons.arrow_forward, color: _biru),
                      onTap: () {
                        Navigator.pop(context);
                        _daftar(r['id'].toString());
                      },
                    )),
              ]),
        ),
      ),
    );
  }

  String _teksPengalamanReq(dynamic v) =>
      v == 1 ? 'Pemula' : (v == 2 ? 'Menengah' : (v == 3 ? 'Mahir' : '-'));

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final p = _p;
    if (p == null || p['error'] != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail proyek')),
        body: Center(
            child: Text(p?['error']?.toString() ?? 'Proyek tidak ditemukan')),
      );
    }
    final affinity = p['affinity'] as Map?;
    final breakdown = affinity?['breakdown'] as Map?;
    final roles = (p['roles'] as List?) ?? [];
    final skills = <String>{
      for (final r in roles)
        ...((r['skillDicari'] as List?)?.cast<String>() ?? [])
    }.toList();
    final minat = (p['minatTag'] as List?)?.cast<String>() ?? [];
    final jadwal = (p['jadwalSlot'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail proyek',
            style: TextStyle(fontWeight: FontWeight.bold, color: _navy)),
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
      ),
      bottomNavigationBar: _bar(p, roles),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ikonKotak(size: 60, judul: p['judul']?.toString()),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['judul']?.toString() ?? '-',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: _navy)),
              if (p['milikSaya'] != true &&
                  (p['namaPembuat']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.person_outline, size: 14, color: _abu),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                        'Diajukan oleh ${p['namaPembuat']}${_jurusanAngkatan(p['jurusanPembuat'], p['angkatanPembuat'])}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _abu, fontSize: 13)),
                  ),
                ]),
              ],
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        if (affinity != null)
          Center(
            child: Column(children: [
              _Donut((affinity['skorPersen'] as num?) ?? 0, size: 128),
              const SizedBox(height: 12),
              _badgeChip(affinity['badge']?.toString() ?? ''),
            ]),
          ),
        const SizedBox(height: 20),
        if (p['statusSaya'] == 'ACCEPTED' &&
            (p['kontakPembuat']?.toString().isNotEmpty ?? false)) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Icon(_ikonKontak(p['kontakJenisPembuat']?.toString()),
                  color: _hijau),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'KONTAK PEMBUAT · ${p['namaPembuat'] ?? ''} · ${p['kontakJenisPembuat'] ?? 'EMAIL'}',
                          style: const TextStyle(
                              color: _hijau,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      Text(p['kontakPembuat'].toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _navy,
                              fontSize: 15)),
                    ]),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Terbuka',
                    style: TextStyle(
                        color: _hijau,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
        ],
        _judulBantuan('DESKRIPSI', () => _jelaskanDeskripsiProyek(context)),
        const SizedBox(height: 8),
        Text(p['deskripsi']?.toString() ?? '',
            style: const TextStyle(fontSize: 15, height: 1.4, color: _navy)),
        const SizedBox(height: 20),
        _judulBantuan(
            'PERAN DIBUTUHKAN', () => _jelaskanPeranDibutuhkan(context)),
        const SizedBox(height: 10),
        ...roles.map((r) => _barisRole(r as Map)),
        const SizedBox(height: 16),
        if (skills.isNotEmpty) ...[
          _judulBantuan('SKILL DIBUTUHKAN',
              () => dsJelaskanAtribut(context, 'proyekSkill')),
          const SizedBox(height: 10),
          _chipList(skills),
          const SizedBox(height: 20),
        ],
        if (minat.isNotEmpty) ...[
          _judulBantuan('MINAT / BIDANG',
              () => dsJelaskanAtribut(context, 'proyekMinat')),
          const SizedBox(height: 10),
          _chipList(minat),
          const SizedBox(height: 20),
        ],
        if (jadwal.isNotEmpty) ...[
          Row(children: [
            _sectionTitle('JADWAL KEGIATAN'),
            const SizedBox(width: 4),
            dsBantuanIkon(context, 'proyekJadwal'),
          ]),
          const SizedBox(height: 10),
          DsExpandableChips(items: jadwal),
          const SizedBox(height: 20),
        ],
        if (breakdown != null) ...[
          _judulRincianKecocokan(context),
          const SizedBox(height: 10),
          _rincianKecocokan(breakdown),
        ],
        const SizedBox(height: 8),
        if (p['pengalamanReq'] != null && p['pengalamanReq'] != 1)
          Text(
              'Pengalaman disarankan: ${_teksPengalamanReq(p['pengalamanReq'])}',
              style: const TextStyle(color: _abu, fontSize: 12)),
      ]),
    );
  }

  Widget _barisRole(Map r) {
    final sisa = (r['sisaKuota'] as num).toInt();
    final kuota = (r['kuota'] as num).toInt();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(children: [
          Expanded(
            child: Text(r['namaRole']?.toString() ?? '-',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15, color: _navy)),
          ),
          Text('${kuota - sisa}/$kuota  ', style: const TextStyle(color: _abu)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: sisa > 0
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFEEF2F7),
                borderRadius: BorderRadius.circular(20)),
            child: Text(sisa > 0 ? '$sisa terbuka' : 'penuh',
                style: TextStyle(
                    color: sisa > 0 ? _hijau : _abu,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        ]),
      ),
    );
  }

  Widget _bar(Map p, List roles) {
    Widget wrap(Widget child) => Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 10)]),
          child: SizedBox(width: double.infinity, height: 52, child: child),
        );

    if (p['milikSaya'] == true) {
      return wrap(FilledButton(
        onPressed: () async {
          final dihapus = await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => KelolaProjectPage(projectId: widget.projectId)));
          if (dihapus == true && mounted) Navigator.of(context).pop();
        },
        style: FilledButton.styleFrom(
            backgroundColor: _biru,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
        child: const Text('Kelola proyek',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ));
    }
    if (p['sudahDaftar'] == true) {
      final status = p['statusSaya']?.toString() ?? 'PENDING';
      final role = p['roleSaya'] ?? '';
      final pendaftaranId = p['pendaftaranIdSaya']?.toString();
      late Color bg, fg;
      late String teks;
      if (status == 'ACCEPTED') {
        bg = const Color(0xFFDCFCE7);
        fg = _hijau;
        teks = 'Diterima · $role';
      } else if (status == 'REJECTED') {
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        teks = 'Ditolak';
      } else {
        bg = const Color(0xFFFEF3C7);
        fg = _amber;
        teks = 'Menunggu konfirmasi · $role';
      }
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 10)]),
        child: Row(children: [
          Expanded(
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(20)),
              // FittedBox: teks otomatis mengecil kalau nama role-nya panjang
              // (bikin 2 baris), supaya tetap pas di dalam kotak tanpa tumpah —
              // ukuran kotaknya sendiri tidak berubah.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(teks,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: fg, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
          if (pendaftaranId != null) ...[
            const SizedBox(width: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () => _batalkan(pendaftaranId),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20))),
                child: const Text('Batalkan',
                    style: TextStyle(
                        color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ]),
      );
    }
    final penuh = p['kuotaPenuh'] == true;
    return wrap(FilledButton(
      onPressed: penuh ? null : () => _pilihRole(roles),
      style: FilledButton.styleFrom(
          backgroundColor: _biru,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      child: Text(penuh ? 'Kuota penuh' : 'Daftar ke proyek',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    ));
  }
}

// ================= KELOLA PROYEK =================
class KelolaProjectPage extends StatefulWidget {
  final String projectId;
  const KelolaProjectPage({super.key, required this.projectId});
  @override
  State<KelolaProjectPage> createState() => _KelolaProjectPageState();
}

class _KelolaProjectPageState extends State<KelolaProjectPage> {
  Map<String, dynamic>? _project;
  List<dynamic> _pendaftar = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    try {
      final proj =
          await apiGet('/people-to-project/projects/${widget.projectId}');
      final pend = await apiGet(
          '/people-to-project/projects/${widget.projectId}/pendaftar');
      setState(() {
        _project = proj is Map ? Map<String, dynamic>.from(proj) : null;
        _pendaftar = pend is List ? pend : [];
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _proses(String pendaftaranId, String keputusan) async {
    final res = await apiPatch('/people-to-project/pendaftaran/$pendaftaranId',
        {'keputusan': keputusan});
    if (!mounted) return;
    if (res is Map && res['kontak'] != null) {
      _snack(context,
          'Diterima. Kontak (${res['kontakJenis'] ?? 'EMAIL'}): ${res['kontak']}');
    } else if (res is Map && res['error'] != null) {
      _snack(context, res['error'].toString());
    } else {
      _snack(context,
          keputusan == 'REJECTED' ? 'Pendaftar ditolak' : 'Pendaftar diterima');
    }
    _muat();
  }

  Future<void> _hapusProyek() async {
    final judul = _project?['judul']?.toString() ?? 'proyek ini';
    final yakin = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus proyek?'),
        content: Text(
            '"$judul" beserta seluruh pendaftar akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Ya, hapus'),
          ),
        ],
      ),
    );
    if (yakin != true) return;
    final res =
        await apiDelete('/people-to-project/projects/${widget.projectId}');
    if (!mounted) return;
    if (res is Map && res['error'] != null) {
      _snack(context, res['error'].toString());
      return;
    }
    _snack(context, 'Proyek dihapus.');
    Navigator.pop(context,
        true); // true = proyek dihapus, agar pemanggil ikut menutup halamannya
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final p = _project;
    final roles = (p?['roles'] as List?) ?? [];
    final totalKuota =
        roles.fold<int>(0, (s, r) => s + (r['kuota'] as num).toInt());
    final sisa =
        roles.fold<int>(0, (s, r) => s + (r['sisaKuota'] as num).toInt());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola proyek',
            style: TextStyle(fontWeight: FontWeight.bold, color: _navy)),
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: _biru),
            tooltip: 'Edit proyek',
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      BuatProjectPage(projectId: widget.projectId)));
              _muat();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
            tooltip: 'Hapus proyek',
            onPressed: _hapusProyek,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _muat,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _ikonKotak(size: 56, judul: p?['judul']?.toString()),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dibuat olehmu',
                        style: TextStyle(
                            color: _abu,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    Text(p?['judul']?.toString() ?? '-',
                        style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: _navy)),
                  ]),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _info('Terisi', '${totalKuota - sisa}/$totalKuota'),
          ]),
          const SizedBox(height: 20),
          _sectionTitle('PERAN & KUOTA'),
          const SizedBox(height: 10),
          ...roles.map((r) => _barisRole(r as Map)),
          const SizedBox(height: 20),
          _sectionTitle('PENDAFTAR'),
          const SizedBox(height: 10),
          if (_pendaftar.isEmpty)
            const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(child: Text('Belum ada pendaftar.')))
          else
            ..._pendaftar.map((e) => _kartuPendaftar(e as Map)),
        ]),
      ),
    );
  }

  Widget _info(String judul, String isi) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(children: [
            Text(judul, style: const TextStyle(color: _abu, fontSize: 11)),
            const SizedBox(height: 2),
            Text(isi,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, color: _navy)),
          ]),
        ),
      );

  Widget _barisRole(Map r) {
    final sisa = (r['sisaKuota'] as num).toInt();
    final kuota = (r['kuota'] as num).toInt();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Expanded(
              child: Text(r['namaRole']?.toString() ?? '-',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: _navy))),
          Text('${kuota - sisa}/$kuota  ', style: const TextStyle(color: _abu)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: sisa > 0
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFEEF2F7),
                borderRadius: BorderRadius.circular(20)),
            child: Text(sisa > 0 ? '$sisa terbuka' : 'penuh',
                style: TextStyle(
                    color: sisa > 0 ? _hijau : _abu,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        ]),
      ),
    );
  }

  Widget _kartuPendaftar(Map d) {
    final m = d['mahasiswa'] as Map? ?? {};
    final status = d['status']?.toString() ?? 'PENDING';
    final nama = m['nama']?.toString() ?? '-';
    final inisial = nama.trim().isNotEmpty
        ? nama
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((e) => e[0])
            .join()
            .toUpperCase()
        : '?';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PendaftarProfilPage(
                  pendaftaranId: d['pendaftaranId'].toString())));
          _muat();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                  radius: 22,
                  backgroundColor: _biru,
                  child: Text(inisial,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nama,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _navy)),
                      if ((m['jurusan']?.toString() ?? '').isNotEmpty ||
                          m['angkatan'] != null)
                        Text(
                            _jurusanAngkatan(m['jurusan'], m['angkatan'])
                                .replaceFirst(' · ', ''),
                            style: const TextStyle(color: _abu, fontSize: 12)),
                      if (d['skorPersen'] != null)
                        Text('${d['skorPersen']}% cocok',
                            style: const TextStyle(color: _abu, fontSize: 13)),
                    ]),
              ),
              _statusBadge(status),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FB),
                  borderRadius: BorderRadius.circular(10)),
              child: Text.rich(
                  TextSpan(style: const TextStyle(color: _navy), children: [
                const TextSpan(text: 'Melamar sebagai '),
                TextSpan(
                    text: d['role']?.toString() ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ])),
            ),
            if (status == 'PENDING') ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _proses(d['pendaftaranId'].toString(), 'REJECTED'),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20))),
                    child: const Text('Tolak',
                        style: TextStyle(
                            color: _navy, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () =>
                        _proses(d['pendaftaranId'].toString(), 'ACCEPTED'),
                    style: FilledButton.styleFrom(
                        backgroundColor: _biru,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20))),
                    child: const Text('Terima',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}

Widget _statusBadge(String s) {
  final fg = s == 'ACCEPTED'
      ? _hijau
      : (s == 'REJECTED' ? const Color(0xFFDC2626) : _amber);
  final bg = s == 'ACCEPTED'
      ? const Color(0xFFDCFCE7)
      : (s == 'REJECTED' ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7));
  final label =
      s == 'ACCEPTED' ? 'Diterima' : (s == 'REJECTED' ? 'Ditolak' : 'Menunggu');
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12)),
  );
}

// ================= PROFIL PENDAFTAR =================
class PendaftarProfilPage extends StatefulWidget {
  final String pendaftaranId;
  const PendaftarProfilPage({super.key, required this.pendaftaranId});
  @override
  State<PendaftarProfilPage> createState() => _PendaftarProfilPageState();
}

class _PendaftarProfilPageState extends State<PendaftarProfilPage> {
  Map<String, dynamic>? _d;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() => _loading = true);
    final res = await apiGet(
        '/people-to-project/pendaftaran/${widget.pendaftaranId}/profil');
    if (!mounted) return;
    setState(() {
      _d = res is Map ? Map<String, dynamic>.from(res) : null;
      _loading = false;
    });
  }

  Future<void> _proses(String keputusan) async {
    final res = await apiPatch(
        '/people-to-project/pendaftaran/${widget.pendaftaranId}',
        {'keputusan': keputusan});
    if (!mounted) return;
    if (res is Map && res['error'] != null) {
      _snack(context, res['error'].toString());
      return;
    }
    _snack(context,
        keputusan == 'REJECTED' ? 'Pendaftar ditolak' : 'Pendaftar diterima');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final d = _d;
    if (d == null || d['error'] != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil pendaftar')),
        body: Center(
            child: Text(d?['error']?.toString() ?? 'Profil tidak ditemukan')),
      );
    }

    final nama = d['nama']?.toString() ?? '-';
    final inisial = nama.trim().isNotEmpty
        ? nama
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((e) => e[0])
            .join()
            .toUpperCase()
        : '?';
    final status = d['status']?.toString() ?? 'PENDING';
    final affinity = d['affinity'] as Map?;
    final breakdown = affinity?['breakdown'] as Map?;
    final skill = (d['skill'] as List?)?.cast<String>() ?? [];
    final minat = (d['minatTag'] as List?)?.cast<String>() ?? [];
    final waktu = (d['ketersediaanWaktu'] as List?)?.cast<String>() ?? [];
    final gayaPeran = [
      if ((d['gayaKerja']?.toString() ?? '').isNotEmpty)
        d['gayaKerja'].toString(),
      if ((d['preferensiPeran']?.toString() ?? '').isNotEmpty)
        d['preferensiPeran'].toString(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil pendaftar',
            style: TextStyle(fontWeight: FontWeight.bold, color: _navy)),
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
      ),
      bottomNavigationBar: status != 'PENDING'
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _proses('REJECTED'),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20))),
                      child: const Text('Tolak',
                          style: TextStyle(
                              color: _navy, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => _proses('ACCEPTED'),
                      style: FilledButton.styleFrom(
                          backgroundColor: _biru,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20))),
                      child: const Text('Terima',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ),
            ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _biru,
            child: Text(inisial,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nama,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.bold, color: _navy)),
              if ((d['jurusan']?.toString() ?? '').isNotEmpty ||
                  d['angkatan'] != null)
                Text(
                    _jurusanAngkatan(d['jurusan'], d['angkatan'])
                        .replaceFirst(' · ', ''),
                    style: const TextStyle(color: _abu, fontSize: 13)),
              if ((d['institusi']?.toString() ?? '').isNotEmpty)
                Text(d['institusi'].toString(),
                    style: const TextStyle(color: _abu, fontSize: 13)),
            ]),
          ),
          _statusBadge(status),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: const Color(0xFFF6F8FB),
              borderRadius: BorderRadius.circular(10)),
          child: Text.rich(
              TextSpan(style: const TextStyle(color: _navy), children: [
            const TextSpan(text: 'Melamar sebagai '),
            TextSpan(
                text: d['role']?.toString() ?? '-',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ])),
        ),
        if ((d['kontak']?.toString() ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Icon(_ikonKontak(d['kontakJenis']?.toString()), color: _hijau),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KONTAK PENDAFTAR · ${d['kontakJenis'] ?? 'EMAIL'}',
                          style: const TextStyle(
                              color: _hijau,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      Text(d['kontak'].toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _navy,
                              fontSize: 15)),
                    ]),
              ),
            ]),
          ),
        ],
        if (affinity != null) ...[
          const SizedBox(height: 20),
          Center(
            child: Column(children: [
              _Donut((affinity['skorPersen'] as num?) ?? 0, size: 110),
              const SizedBox(height: 10),
              _badgeChip(affinity['badge']?.toString() ?? ''),
            ]),
          ),
        ],
        if ((d['bio']?.toString() ?? '').isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(children: [
            _sectionTitle('BIO'),
            const SizedBox(width: 4),
            dsBantuanIkon(context, 'bio')
          ]),
          const SizedBox(height: 8),
          Text(d['bio'].toString(), style: const TextStyle(color: _navy)),
        ],
        if (skill.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(children: [
            _sectionTitle('SKILL'),
            const SizedBox(width: 4),
            dsBantuanIkon(context, 'skill')
          ]),
          const SizedBox(height: 10),
          _chipList(skill),
        ],
        if (minat.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(children: [
            _sectionTitle('MINAT / BIDANG'),
            const SizedBox(width: 4),
            dsBantuanIkon(context, 'minat')
          ]),
          const SizedBox(height: 10),
          _chipList(minat),
        ],
        if (gayaPeran.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(children: [
            _sectionTitle('GAYA KERJA & PERAN'),
            const SizedBox(width: 4),
            dsBantuanIkon(context, 'gayaKerjaPeran')
          ]),
          const SizedBox(height: 10),
          _chipList(gayaPeran),
        ],
        if (waktu.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(children: [
            _sectionTitle('KETERSEDIAAN WAKTU'),
            const SizedBox(width: 4),
            dsBantuanIkon(context, 'ketersediaanWaktu')
          ]),
          const SizedBox(height: 10),
          DsExpandableChips(items: waktu),
        ],
        if (breakdown != null) ...[
          const SizedBox(height: 20),
          _judulRincianKecocokan(context),
          const SizedBox(height: 10),
          _rincianKecocokan(breakdown),
        ],
        const SizedBox(height: 20),
      ]),
    );
  }
}

// ================= BUAT PROYEK =================
class BuatProjectPage extends StatefulWidget {
  final String? projectId; // null = buat baru, terisi = edit proyek ini
  const BuatProjectPage({super.key, this.projectId});
  @override
  State<BuatProjectPage> createState() => _BuatProjectPageState();
}

class _BuatProjectPageState extends State<BuatProjectPage> {
  final _judul = TextEditingController();
  final _deskripsi = TextEditingController();
  final Map<String, int> _peran =
      {}; // namaRole -> kuota (jumlah orang dibutuhkan)
  final Set<String> _skill = {};
  // 6 atribut yang dipakai Affinity Engine (sama seperti profil mahasiswa).
  final Set<String> _minat = {};
  // Sengaja tidak diberi nilai default — supaya user tidak melewatkan atribut
  // ini tanpa sadar (ke-pilih otomatis lalu tidak diubah sama sekali).
  String? _gayaKerja;
  String? _pengalaman;
  final Set<String> _ketersediaan = {};
  bool _loading = false;
  bool _loadingAwal = false;

  bool get _editMode => widget.projectId != null;

  // Taksonomi generik — HARUS sama persis dengan preferensiPeran profil mahasiswa,
  // karena Affinity Engine mencocokkan string-nya langsung (lihat affinityProject.ts).
  final _peranOpsi = const [
    'Leader/Coordinator',
    'Contributor/Executor',
    'Supporter/Facilitator'
  ];
  final _skillOpsi = const [
    'Python',
    'JavaScript',
    'Figma',
    'Flutter',
    'Public Speaking',
    'Manajemen Proyek',
    'Penulisan',
    'Analisis Data',
    'UI Design',
    'Riset Pengguna',
    'SQL',
    'Copywriting',
  ];
  final _minatOpsi = const [
    'AI',
    'Riset',
    'Pengembangan Web',
    'Pengembangan Mobile',
    'Desain',
    'Data Science',
    'Kewirausahaan',
    'UI/UX',
  ];
  final _gayaKerjaOpsi = const ['Terstruktur', 'Fleksibel'];
  final _pengalamanOpsi = const ['Pemula', 'Menengah', 'Mahir'];

  bool get _valid => _judul.text.trim().isNotEmpty && _peran.isNotEmpty;

  int get _pengalamanReq => _pengalaman == null
      ? 0
      : _pengalamanOpsi.indexOf(_pengalaman!) +
          1; // Pemula=1, Menengah=2, Mahir=3

  @override
  void initState() {
    super.initState();
    if (_editMode) _muatDataLama();
  }

  Future<void> _muatDataLama() async {
    setState(() => _loadingAwal = true);
    try {
      final res =
          await apiGet('/people-to-project/projects/${widget.projectId}');
      if (res is Map) {
        _judul.text = res['judul']?.toString() ?? '';
        _deskripsi.text = res['deskripsi']?.toString() ?? '';
        _minat.addAll((res['minatTag'] as List?)?.cast<String>() ?? []);
        _ketersediaan
            .addAll((res['jadwalSlot'] as List?)?.cast<String>() ?? []);
        final gaya = res['gayaKerja']?.toString();
        if (gaya != null && _gayaKerjaOpsi.contains(gaya)) _gayaKerja = gaya;
        final pengalamanReq = (res['pengalamanReq'] as num?)?.toInt() ?? 2;
        if (pengalamanReq >= 1 && pengalamanReq <= 3) {
          _pengalaman = _pengalamanOpsi[pengalamanReq - 1];
        }
        for (final r in (res['roles'] as List? ?? [])) {
          final role = r as Map;
          _peran[role['namaRole'].toString()] = (role['kuota'] as num).toInt();
          _skill.addAll((role['skillDicari'] as List?)?.cast<String>() ?? []);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingAwal = false);
    }
  }

  Future<void> _buat() async {
    setState(() => _loading = true);
    try {
      final body = {
        'judul': _judul.text.trim(),
        'deskripsi': _deskripsi.text.trim(),
        'minatTag': _minat.toList(),
        'gayaKerja': _gayaKerja,
        'pengalamanReq': _pengalaman == null ? null : _pengalamanReq,
        'jadwalSlot': _ketersediaan.toList(),
        'roles': _peran.entries
            .map((e) => {
                  'namaRole': e.key,
                  'kuota': e.value,
                  'skillDicari': _skill.toList()
                })
            .toList(),
      };
      final res = _editMode
          ? await apiPut(
              '/people-to-project/projects/${widget.projectId}', body)
          : await apiPost('/people-to-project/projects', body);
      if (!mounted) return;
      if (res is Map && res['error'] != null) {
        _snack(context, res['error'].toString());
      } else {
        _snack(context,
            _editMode ? 'Perubahan disimpan' : 'Proyek berhasil dibuat');
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) _snack(context, 'Gagal terhubung ke server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _label(String t, {String? bantuanKey}) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 20),
        child: bantuanKey == null
            ? _sectionTitle(t)
            : Row(children: [
                _sectionTitle(t),
                const SizedBox(width: 4),
                dsBantuanIkon(context, bantuanKey)
              ]),
      );

  Widget _field(TextEditingController c, String hint, {int maxLines = 1}) =>
      TextField(
        controller: c,
        maxLines: maxLines,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: _biru)),
        ),
      );

  Widget _pilihan(List<String> opsi, bool Function(String) aktif,
          void Function(String) onTap) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: opsi
            .map((o) => DsChip(
                label: o,
                aktif: aktif(o),
                onTap: () => setState(() => onTap(o))))
            .toList(),
      );

  Widget _barisKuotaPeran(String role) {
    final kuota = _peran[role] ?? 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(children: [
        Expanded(
            child: Text(role,
                style: const TextStyle(
                    color: _navy, fontWeight: FontWeight.w600))),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 22),
          color: kuota > 1 ? _biru : const Color(0xFFCBD5E1),
          onPressed:
              kuota > 1 ? () => setState(() => _peran[role] = kuota - 1) : null,
        ),
        SizedBox(
          width: 24,
          child: Text('$kuota',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _navy, fontSize: 16)),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 22),
          color: _biru,
          onPressed: () => setState(() => _peran[role] = kuota + 1),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingAwal) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_editMode ? 'Edit proyek' : 'Buat proyek baru',
            style: const TextStyle(fontWeight: FontWeight.bold, color: _navy)),
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context)),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 10)]),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: (_valid && !_loading) ? _buat : null,
            style: FilledButton.styleFrom(
                backgroundColor: _biru,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999))),
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(_editMode ? 'Simpan perubahan' : 'Buat proyek',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _label('JUDUL PROYEK'),
            _field(_judul, 'cth: Aplikasi Absensi Berbasis QR'),
            const SizedBox(height: 20),
            _judulBantuan('DESKRIPSI', () => _jelaskanDeskripsiProyek(context)),
            const SizedBox(height: 8),
            _field(_deskripsi, 'Jelaskan tujuan proyek & apa yang dikerjakan…',
                maxLines: 4),

            // 6 atribut Affinity Engine (sama seperti profil mahasiswa) — menentukan skor kecocokan.
            Row(children: [
              _label('PERAN DIBUTUHKAN'),
              const Text(' *', style: TextStyle(color: Color(0xFFDC2626))),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _jelaskanPeranDibutuhkan(context),
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.help_outline, size: 16, color: _abu),
                ),
              ),
            ]),
            _pilihan(_peranOpsi, (o) => _peran.containsKey(o), (o) {
              if (_peran.containsKey(o)) {
                _peran.remove(o);
              } else {
                _peran[o] = 1;
              }
            }),
            if (_peran.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Jumlah orang dibutuhkan per peran:',
                  style: TextStyle(color: _abu, fontSize: 12)),
              const SizedBox(height: 8),
              ..._peran.keys.map((role) => _barisKuotaPeran(role)),
            ],
            _label('SKILL DIBUTUHKAN', bantuanKey: 'proyekSkill'),
            _pilihan(_skillOpsi, (o) => _skill.contains(o),
                (o) => _skill.contains(o) ? _skill.remove(o) : _skill.add(o)),
            _label('MINAT / BIDANG', bantuanKey: 'proyekMinat'),
            _pilihan(_minatOpsi, (o) => _minat.contains(o),
                (o) => _minat.contains(o) ? _minat.remove(o) : _minat.add(o)),
            _label('GAYA KERJA KEGIATAN', bantuanKey: 'proyekGayaKerja'),
            _pilihan(
                _gayaKerjaOpsi, (o) => _gayaKerja == o, (o) => _gayaKerja = o),
            _label('PENGALAMAN DISARANKAN', bantuanKey: 'proyekPengalaman'),
            _pilihan(_pengalamanOpsi, (o) => _pengalaman == o,
                (o) => _pengalaman = o),
            _label('KETERSEDIAAN JADWAL KEGIATAN', bantuanKey: 'proyekJadwal'),
            DsJadwalGrid(
              value: _ketersediaan,
              onToggle: (slot) => setState(() => _ketersediaan.contains(slot)
                  ? _ketersediaan.remove(slot)
                  : _ketersediaan.add(slot)),
            ),
          ]),
    );
  }
}

// ================= EMPTY STATE (konsisten dengan modul People-to-People) =================
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
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFE8EDF5),
                child: Icon(icon, color: _biru)),
            const SizedBox(height: 14),
            Text(judul,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: _navy)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _abu, height: 1.4)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onTombol,
              style: FilledButton.styleFrom(
                  backgroundColor: _biru,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20))),
              child: Text(tombol,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      );
}
