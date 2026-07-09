import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import '../api.dart';
import '../design_system.dart';

// Modul Team Formation (Faishal) — UC21-UC2x, Algoritma IV.1-IV.3 (Bab4_Algoritma_Affinity_Matching_Final).
// Desain mengikuti design system bersama (lihat design_system.dart).

const _biru = DS.active;
const _navy = DS.primaryText;
const _abu = DS.secondaryText;
const _hijau = DS.success;
const _amber = DS.warning;

// Dipakai tur onboarding (lihat main.dart) — target elemen statis yang selalu ada.
final GlobalKey tourTimToggleKey = GlobalKey();

// Dekorasi input konsisten dengan LabeledField (lihat auth.dart) — dipakai semua TextField
// di modul ini supaya tidak jatuh ke garis bawah default Material yang terlalu tebal/kasar.
InputDecoration _kotakInput(String hint, {Widget? prefixIcon, bool isDense = false}) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9AA5B8)),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      isDense: isDense,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isDense ? 12 : 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: _biru, width: 1.5),
      ),
    );

const _domainRole = [
  'Programmer', 'Backend Developer', 'Frontend Developer', 'Mobile Developer',
  'UI/UX Designer', 'Data Analyst', 'Data Scientist', 'Project Manager',
  'QA/Tester', 'Content/Business Analyst',
];
const _kategoriOpsi = [
  'AI', 'Riset', 'Pengembangan Web', 'Pengembangan Mobile', 'Desain', 'Data Science',
  'Kewirausahaan', 'UI/UX',
];
String _inisial(String nama) {
  final parts = nama.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts[0].substring(0, 1).toUpperCase();
}

void _snack(BuildContext context, String pesan, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(pesan), backgroundColor: error ? Colors.red.shade700 : null),
  );
}

Widget _chipList(List<String> items) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(s, style: const TextStyle(color: _navy, fontSize: 12, fontWeight: FontWeight.w600)),
              ))
          .toList(),
    );

Widget _sectionTitle(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
      child: Text(t, style: const TextStyle(color: _navy, fontSize: 15, fontWeight: FontWeight.w700)),
    );

// Penjelasan "Fungsi Kerja Tim" buat user awam — jelaskan konsepnya (6 fungsi,
// arti titik hijau/abu) tanpa menyebut algoritma penugasan di baliknya.
void _jelaskanFungsiKerjaTim(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Apa itu Fungsi Kerja Tim?', style: TextStyle(fontWeight: FontWeight.bold, color: _navy)),
      content: const Text(
        'Tim yang seimbang biasanya butuh 6 fungsi kerja berbeda: Organizer, Doer, Challenger, '
        'Innovator, Team Builder, dan Connector.\n\n'
        'Sistem otomatis melihat hasil kuesioner TREO tiap anggota, lalu menandai siapa yang '
        'paling cocok memegang tiap fungsi itu.\n\n'
        'Titik hijau artinya fungsi itu sudah ada anggota yang memegangnya. Titik abu-abu artinya '
        'belum ada anggota yang cocok untuk fungsi tersebut.\n\n'
        'Makin banyak fungsi yang terisi, makin seimbang tim kalian.',
        style: TextStyle(color: _navy, height: 1.5),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    ),
  );
}

// Penjelasan "Analitik Tim" buat user awam — jelaskan 3 ukurannya tanpa
// menyebut rumus/bobot perhitungan di baliknya.
void _jelaskanAnalitikTim(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Apa itu Analitik Tim?', style: TextStyle(fontWeight: FontWeight.bold, color: _navy)),
      content: const Text(
        'Analitik tim terdiri dari tiga ukuran:\n\n'
        'Kecocokan Fungsi Teknis, seberapa cocok kemampuan teknis anggota tim (seperti Data Analyst, '
        'Backend Developer, dan peran teknis lain) dengan kebutuhan tim.\n\n'
        'Kecocokan Fungsi Kerja, seberapa seimbang peran kerja tim dilihat dari hasil kuesioner TREO tiap '
        'anggota (Organizer, Doer, Challenger, dan seterusnya).\n\n'
        'Skor Keseimbangan Tim, gabungan dari kedua ukuran di atas yang dihitung di level tim secara '
        'keseluruhan, menunjukkan seberapa siap tim kalian menyelesaikan tugas.',
        style: TextStyle(color: _navy, height: 1.5),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String subjudul;
  final String? tombol;
  final VoidCallback? onTombol;
  const _EmptyState({required this.icon, required this.judul, required this.subjudul, this.tombol, this.onTombol});
  @override
  Widget build(BuildContext context) => Align(
        // topCenter (bukan Center biasa) supaya kotak selalu rapi di bagian atas &
        // rata tengah horizontal, konsisten dengan modul People-to-Project/People-to-People,
        // apa pun tinggi ruang yang diberikan parent (Expanded/ListView/dll).
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 32, backgroundColor: const Color(0xFFEFF3FB), child: Icon(icon, color: _biru, size: 30)),
                const SizedBox(height: 14),
                Text(judul, style: const TextStyle(color: _navy, fontSize: 16, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(subjudul, style: const TextStyle(color: _abu, fontSize: 13, height: 1.4), textAlign: TextAlign.center),
                if (tombol != null) ...[
                  const SizedBox(height: 16),
                  FilledButton(onPressed: onTombol, child: Text(tombol!)),
                ],
              ],
            ),
          ),
        ),
      );
}

String _statusLabel(String s) {
  switch (s) {
    case 'PENDING':
      return 'Menunggu persetujuan';
    case 'ACCEPTED':
      return 'Diterima';
    case 'DIKELUARKAN':
      return 'Dikeluarkan';
    case 'KELUAR':
      return 'Telah keluar';
    default:
      return 'Ditolak';
  }
}

Color _statusFg(String s) {
  switch (s) {
    case 'PENDING':
      return _amber;
    case 'ACCEPTED':
      return _hijau;
    case 'DIKELUARKAN':
    case 'REJECTED':
      return Colors.red.shade700;
    case 'KELUAR':
      return _abu;
    default:
      return Colors.red.shade700;
  }
}

Color _statusBg(String s) {
  switch (s) {
    case 'PENDING':
      return const Color(0xFFFEF3C7);
    case 'ACCEPTED':
      return const Color(0xFFDCFCE7);
    case 'DIKELUARKAN':
    case 'REJECTED':
      return const Color(0xFFFEE2E2);
    case 'KELUAR':
      return const Color(0xFFF3F4F6);
    default:
      return const Color(0xFFFEE2E2);
  }
}

String _formatTenggat(dynamic tenggat) {
  if (tenggat == null) return '';
  final dt = DateTime.tryParse(tenggat.toString());
  if (dt == null) return tenggat.toString();
  final now = DateTime.now();
  final sisaHari = DateTime(dt.year, dt.month, dt.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  if (sisaHari < 30) {
    if (sisaHari < 0) return 'Tenggat lewat';
    if (sisaHari == 0) return 'Tenggat hari ini';
    return '$sisaHari hari lagi';
  }
  const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  return '${dt.day} ${bulan[dt.month - 1]} ${dt.year}';
}

Widget _badgeChip(String label, Color fg, Color bg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );

// ------------------------------------------------------------------------------------------------
// Root page — toggle Lomba / Tim Saya
// ------------------------------------------------------------------------------------------------

class TeamFormationPage extends StatefulWidget {
  const TeamFormationPage({super.key});
  @override
  State<TeamFormationPage> createState() => _TeamFormationPageState();
}

class _TeamFormationPageState extends State<TeamFormationPage> {
  int _tab = 0;
  final _timSayaKey = GlobalKey<_TimSayaTabState>();

  bool _loading = true;
  bool _terkunci = false;
  String? _pesanKunci;

  @override
  void initState() {
    super.initState();
    _cekAkses();
  }

  Future<void> _cekAkses() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([apiGet('/auth/profil'), apiGet('/team-formation/treo')]);
      final profil = results[0];
      final treo = results[1];
      final profilLengkap = profil != null && profil['lengkap'] == true;
      final treoDiisi = treo != null && treo['diisi'] == true;
      String? pesan;
      if (!profilLengkap && !treoDiisi) {
        pesan = 'Lengkapi profil dan isi kuesioner TREO dulu untuk membuka Team Formation.';
      } else if (!profilLengkap) {
        pesan = 'Lengkapi profil dulu untuk membuka Team Formation.';
      } else if (!treoDiisi) {
        pesan = 'Isi kuesioner TREO dulu untuk membuka Team Formation.';
      }
      if (!mounted) return;
      setState(() {
        _terkunci = pesan != null;
        _pesanKunci = pesan;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _terkunci = true;
        _pesanKunci = 'Gagal memuat status profil. Cek koneksi lalu coba lagi.';
        _loading = false;
      });
    }
  }

  Widget _toggle() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(0xFFEFF3FB), borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              _toggleItem('Lomba', 0),
              _toggleItem('Tim Saya', 1),
            ],
          ),
        ),
      );

  Widget _toggleItem(String label, int i) => Expanded(
        child: GestureDetector(
          // IndexedStack + AutomaticKeepAliveClientMixin di _TimSayaTab sudah menjaga
          // datanya tetap ada saat berpindah tab — tidak perlu paksa reload di sini
          // (itu yang bikin kedip/loading sekilas tiap pindah). Refresh manual masih
          // bisa lewat pull-to-refresh di dalam tab masing-masing.
          onTap: () => setState(() => _tab = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _tab == i ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: _tab == i ? [const BoxShadow(color: Color(0x14000000), blurRadius: 6)] : null,
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(color: _tab == i ? _biru : _abu, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Showcase(
                key: tourTimToggleKey,
                title: 'Team Formation',
                description: 'Cari lomba untuk diikuti, atau kelola tim yang sudah kamu buat/gabung di sini.',
                child: _toggle(),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _terkunci
                        ? _EmptyState(
                            icon: Icons.auto_awesome,
                            judul: _pesanKunci ?? 'Team Formation terkunci',
                            subjudul: 'Isi profil dan kuesioner TREO di tab Profil, lalu muat ulang di sini.',
                            tombol: 'Muat ulang',
                            onTombol: _cekAkses,
                          )
                        : IndexedStack(
                            index: _tab,
                            children: [const _LombaTab(), _TimSayaTab(key: _timSayaKey)],
                          ),
              ),
            ],
          ),
        ),
      );
}

// ------------------------------------------------------------------------------------------------
// Tab: daftar lomba
// ------------------------------------------------------------------------------------------------

class _LombaTab extends StatefulWidget {
  const _LombaTab();
  @override
  State<_LombaTab> createState() => _LombaTabState();
}

class _LombaTabState extends State<_LombaTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List _daftar = [];
  bool _loading = true;
  final _cariCtrl = TextEditingController();
  String _cari = '';

  @override
  void initState() {
    super.initState();
    _muat();
    _cariCtrl.addListener(() => setState(() => _cari = _cariCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _cariCtrl.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    setState(() => _loading = true);
    final res = await apiGet('/team-formation/lomba');
    setState(() {
      _daftar = res is List ? res : [];
      _loading = false;
    });
  }

  List get _tersaring {
    if (_cari.isEmpty) return _daftar;
    return _daftar.where((l) {
      final judul = ('${l['judul'] ?? ''}').toLowerCase();
      final penyelenggara = ('${l['penyelenggara'] ?? ''}').toLowerCase();
      return judul.contains(_cari) || penyelenggara.contains(_cari);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: TextField(
              controller: _cariCtrl,
              decoration: InputDecoration(
                hintText: 'Cari lomba atau penyelenggara...',
                hintStyle: const TextStyle(color: _abu, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: _abu, size: 20),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _muat,
                    child: _tersaring.isEmpty
                        ? ListView(children: [
                            _EmptyState(
                              icon: Icons.emoji_events_outlined,
                              judul: _daftar.isEmpty ? 'Belum ada lomba' : 'Tidak ditemukan',
                              subjudul: _daftar.isEmpty
                                  ? 'Lomba akan ditambahkan oleh admin.'
                                  : 'Coba kata kunci lain.',
                            ),
                          ])
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
                            itemCount: _tersaring.length,
                            itemBuilder: (context, i) => _kartuLomba(_tersaring[i]),
                          ),
                  ),
          ),
        ],
      );
  }

  Widget _kartuLomba(dynamic l) {
    final kategori = ((l['kategoriLomba'] as List?)?.cast<String>() ?? []);
    final subjudul = [
      if (kategori.isNotEmpty) kategori.first,
      l['penyelenggara'] ?? 'Penyelenggara tidak diketahui',
    ].join(' · ');
    final diikuti = l['diikuti'] == true;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => DetailLombaPage(lombaId: l['id'])));
          _muat();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(radius: 22, backgroundColor: Color(0xFFEFF3FB), child: Icon(Icons.emoji_events, color: _biru)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(subjudul, style: const TextStyle(color: _abu, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                      if (diikuti) _badgeChip('Diikuti', _hijau, const Color(0xFFDCFCE7)),
                    ]),
                    const SizedBox(height: 2),
                    Text(l['judul'] ?? '', style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 6),
                    Row(children: [
                      if (l['tenggat'] != null) ...[
                        const Icon(Icons.calendar_today, size: 13, color: _abu),
                        const SizedBox(width: 4),
                        Text(_formatTenggat(l['tenggat']), style: const TextStyle(color: _abu, fontSize: 12)),
                      ],
                      if (l['tenggat'] != null && l['hadiah'] != null) const SizedBox(width: 12),
                      if (l['hadiah'] != null) ...[
                        const Icon(Icons.emoji_events_outlined, size: 13, color: _hijau),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text('${l['hadiah']}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(color: _hijau, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Spacer(),
                      Text('${l['jumlahLobi'] ?? 0} lobi tim →', style: const TextStyle(color: _biru, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------------------------------------
// Tab: tim saya
// ------------------------------------------------------------------------------------------------

class _TimSayaTab extends StatefulWidget {
  const _TimSayaTab({super.key});
  @override
  State<_TimSayaTab> createState() => _TimSayaTabState();
}

class _TimSayaTabState extends State<_TimSayaTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List _daftar = [];
  bool _loading = true;
  int _subTab = 0;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() => _loading = true);
    final res = await apiGet('/team-formation/saya');
    setState(() {
      _daftar = res is List ? res : [];
      _loading = false;
    });
  }

  List get _dibuat => _daftar.where((t) => t['peranSaya'] == 'Koordinator').toList();
  List get _bergabung => _daftar.where((t) => t['peranSaya'] != 'Koordinator').toList();

  Widget _subToggle() => Container(
        margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: const Color(0xFFEFF3FB), borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            _subToggleItem('Dibuat olehku (${_dibuat.length})', 0),
            _subToggleItem('Bergabung (${_bergabung.length})', 1),
          ],
        ),
      );

  Widget _subToggleItem(String label, int i) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _subTab = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _subTab == i ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: _subTab == i ? [const BoxShadow(color: Color(0x14000000), blurRadius: 6)] : null,
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(color: _subTab == i ? _biru : _abu, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
      );

  Widget _deskripsiSubTab() => Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
        child: Text(
          _subTab == 0
              ? 'Berikut daftar tim yang telah Anda buat'
              : 'Berikut merupakan daftar tim yang Anda ajukan bergabung ataupun sudah menjadi anggota aktif',
          style: const TextStyle(color: _abu, fontSize: 12),
        ),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    final daftar = _subTab == 0 ? _dibuat : _bergabung;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tim Saya', style: TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 18)),
              IconButton(
                tooltip: 'Riwayat Pengajuan',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatPengajuanPage())),
                icon: const Icon(Icons.history, color: _navy),
              ),
            ],
          ),
        ),
        _subToggle(),
        _deskripsiSubTab(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _muat,
            child: daftar.isEmpty
                ? ListView(children: [
                    _EmptyState(
                      icon: Icons.groups_2_outlined,
                      judul: _subTab == 0 ? 'Belum membuat tim' : 'Belum bergabung tim',
                      subjudul: _subTab == 0
                          ? 'Buat tim dari halaman Lomba untuk mulai merekrut anggota.'
                          : 'Gabung tim dari halaman Lomba untuk mulai berkolaborasi.',
                    ),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                    itemCount: daftar.length,
                    itemBuilder: (context, i) => _subTab == 0 ? _kartuDibuat(daftar[i]) : _kartuBergabung(daftar[i]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _kartuDibuat(dynamic t) {
    final pending = (t['pendingCount'] ?? 0) as int;
    final rolesTerbuka = (t['rolesTerbuka'] as List?)?.cast<String>() ?? [];
    final subtitle = rolesTerbuka.isEmpty
        ? '${t['jumlahAnggota']}/${t['totalKuota']} anggota · roster lengkap'
        : '${t['jumlahAnggota']}/${t['totalKuota']} anggota · butuh ${rolesTerbuka.join(', ')}';
    final label = [t['kategoriLomba'], t['namaLomba']].where((x) => x != null && x != '').join(' · ');
    final isFinal = t['status'] == 'FINAL';
    final pengajuanLabel = pending > 0 ? '$pending pengajuan masuk →' : 'Belum ada pengajuan →';
    final pengajuanColor = pending > 0 ? Colors.red.shade600 : _abu;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => DetailLobiPage(lobiId: t['id'])));
          _muat();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(label, style: const TextStyle(color: _abu, fontSize: 12), overflow: TextOverflow.ellipsis),
                  ),
                  isFinal
                      ? _badgeChip('Final', _hijau, const Color(0xFFDCFCE7))
                      : _badgeChip('Aktif', _hijau, const Color(0xFFDCFCE7)),
                ],
              ),
              const SizedBox(height: 4),
              Text(t['judul'] ?? '', style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: _abu, fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                children: [
                  InkWell(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => KelolaLobiPage(lobiId: t['id'])));
                      _muat();
                    },
                    child: Text(pengajuanLabel,
                        style: TextStyle(color: pengajuanColor, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: isFinal
                        ? null
                        : () async {
                            final berubah = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (_) => EditTimPage(lobiId: t['id'])),
                            );
                            if (berubah == true) _muat();
                          },
                    child: Text(isFinal ? 'Tim sudah final' : 'Kelola tim →',
                        style: TextStyle(color: isFinal ? _abu : _biru, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kartuBergabung(dynamic t) {
    final status = t['statusSaya'] ?? 'ACCEPTED';
    final dikeluarkan = t['dikeluarkan'] == true;
    final isFinal = t['status'] == 'FINAL';
    final aktif = status == 'ACCEPTED';
    final pending = status == 'PENDING';
    // Lobi tetap bisa dibuka walau masih menunggu persetujuan (sama seperti saat
    // menjelajah dari daftar lomba) — hanya dikunci kalau sudah keluar/dikeluarkan.
    final tappable = aktif || pending;

    final String statusLabel;
    final Color fg;
    final Color bg;
    if (aktif && isFinal) {
      statusLabel = 'Final';
      fg = _hijau;
      bg = const Color(0xFFDCFCE7);
    } else if (aktif) {
      statusLabel = 'Aktif';
      fg = _hijau;
      bg = const Color(0xFFDCFCE7);
    } else if (pending) {
      statusLabel = 'Menunggu persetujuan';
      fg = _amber;
      bg = const Color(0xFFFEF3C7);
    } else if (dikeluarkan) {
      statusLabel = 'Dikeluarkan';
      fg = Colors.red.shade700;
      bg = const Color(0xFFFEE2E2);
    } else {
      statusLabel = 'Keluar';
      fg = Colors.red.shade700;
      bg = const Color(0xFFFEE2E2);
    }

    final role = t['roleSaya'];
    final subtitle = (role != null && role != '')
        ? '$role · ${t['jumlahAnggota']}/${t['totalKuota']} anggota'
        : '${t['jumlahAnggota']}/${t['totalKuota']} anggota';
    final label = [t['kategoriLomba'], t['namaLomba']].where((x) => x != null && x != '').join(' · ');

    final isi = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(color: _abu, fontSize: 12), overflow: TextOverflow.ellipsis),
              ),
              _badgeChip(statusLabel, fg, bg),
            ],
          ),
          const SizedBox(height: 4),
          Text(t['judul'] ?? '', style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: _abu, fontSize: 12)),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: tappable
          ? InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => DetailLobiPage(lobiId: t['id'])));
                _muat();
              },
              child: isi,
            )
          : isi,
    );
  }
}

// ------------------------------------------------------------------------------------------------
// Riwayat pengajuan (semua status, non-tappable). Backend memetakan status LEFT menjadi ACCEPTED,
// jadi setiap pengajuan tetap muncul di sini walau anggotanya sudah keluar/dikeluarkan — hanya
// ada 3 label yang tampil: Menunggu persetujuan, Diterima, Ditolak.
// ------------------------------------------------------------------------------------------------

class RiwayatPengajuanPage extends StatefulWidget {
  const RiwayatPengajuanPage({super.key});
  @override
  State<RiwayatPengajuanPage> createState() => _RiwayatPengajuanPageState();
}

class _RiwayatPengajuanPageState extends State<RiwayatPengajuanPage> {
  List _daftar = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() => _loading = true);
    final res = await apiGet('/team-formation/pendaftaran-saya');
    setState(() {
      _daftar = res is List ? res : [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Riwayat Pengajuan')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _muat,
                child: _daftar.isEmpty
                    ? ListView(children: const [
                        _EmptyState(
                          icon: Icons.history,
                          judul: 'Belum ada pengajuan',
                          subjudul: 'Riwayat status pengajuanmu ke tim akan muncul di sini.',
                        ),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                        itemCount: _daftar.length,
                        itemBuilder: (context, i) => _kartuRiwayat(_daftar[i]),
                      ),
              ),
      );

  Widget _kartuRiwayat(dynamic p) {
    final status = p['status'] ?? 'PENDING';
    final role = p['roleNama'];
    final label = [p['kategoriLomba'], p['namaLomba']].where((x) => x != null && x != '').join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, style: const TextStyle(color: _abu, fontSize: 12), overflow: TextOverflow.ellipsis),
                ),
                _badgeChip(_statusLabel(status), _statusFg(status), _statusBg(status)),
              ],
            ),
            const SizedBox(height: 4),
            Text(p['judul'] ?? '', style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 15)),
            if (role != null && role != '') ...[
              const SizedBox(height: 4),
              Text('$role', style: const TextStyle(color: _abu, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------------------------------------
// Buat/usul lomba baru
// ------------------------------------------------------------------------------------------------

class BuatLombaPage extends StatefulWidget {
  const BuatLombaPage({super.key});
  @override
  State<BuatLombaPage> createState() => _BuatLombaPageState();
}

const List<String> _cakupanOpsi = ['Nasional', 'Regional', 'Internasional'];

class _BuatLombaPageState extends State<BuatLombaPage> {
  final _judul = TextEditingController();
  final _deskripsi = TextEditingController();
  final _penyelenggara = TextEditingController();
  DateTime? _tenggatDate;
  final _hadiah = TextEditingController();
  final _minAnggota = TextEditingController();
  final _maxAnggota = TextEditingController(text: '5');
  final _nominalBiaya = TextEditingController();
  final _kontakInstagram = TextEditingController();
  final _kontakWebsite = TextEditingController();
  final _kontakNarahubung = TextEditingController();
  final Set<String> _kategori = {};
  String? _cakupan;
  String _jenisBiaya = 'GRATIS';
  bool _saving = false;

  @override
  void dispose() {
    _judul.dispose();
    _deskripsi.dispose();
    _penyelenggara.dispose();
    _hadiah.dispose();
    _minAnggota.dispose();
    _maxAnggota.dispose();
    _nominalBiaya.dispose();
    _kontakInstagram.dispose();
    _kontakWebsite.dispose();
    _kontakNarahubung.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_judul.text.trim().isEmpty || _deskripsi.text.trim().isEmpty || _kategori.isEmpty) {
      _snack(context, 'Judul, deskripsi, dan kategori wajib diisi', error: true);
      return;
    }
    final maks = int.tryParse(_maxAnggota.text.trim()) ?? 0;
    if (maks < 1) {
      _snack(context, 'Maksimal anggota tim tidak valid', error: true);
      return;
    }
    final minText = _minAnggota.text.trim();
    final min = minText.isEmpty ? null : int.tryParse(minText);
    if (minText.isNotEmpty && (min == null || min < 1)) {
      _snack(context, 'Minimal anggota tim tidak valid', error: true);
      return;
    }
    if (min != null && min > maks) {
      _snack(context, 'Minimal anggota tidak boleh lebih besar dari maksimal', error: true);
      return;
    }
    setState(() => _saving = true);
    final res = await apiPost('/team-formation/lomba', {
      'judul': _judul.text.trim(),
      'deskripsi': _deskripsi.text.trim(),
      'kategoriLomba': _kategori.toList(),
      'maxAnggotaTim': maks,
      if (min != null) 'minAnggotaTim': min,
      if (_tenggatDate != null) 'tenggat': _tenggatDate!.toIso8601String(),
      if (_penyelenggara.text.trim().isNotEmpty) 'penyelenggara': _penyelenggara.text.trim(),
      if (_hadiah.text.trim().isNotEmpty) 'hadiah': _hadiah.text.trim(),
      if (_cakupan != null) 'cakupan': _cakupan,
      'jenisBiaya': _jenisBiaya,
      if (_jenisBiaya == 'BERBAYAR' && _nominalBiaya.text.trim().isNotEmpty) 'nominalBiaya': _nominalBiaya.text.trim(),
      if (_kontakInstagram.text.trim().isNotEmpty) 'kontakInstagram': _kontakInstagram.text.trim(),
      if (_kontakWebsite.text.trim().isNotEmpty) 'kontakWebsite': _kontakWebsite.text.trim(),
      if (_kontakNarahubung.text.trim().isNotEmpty) 'kontakNarahubung': _kontakNarahubung.text.trim(),
    });
    setState(() => _saving = false);
    if (res is Map && res['error'] != null) {
      _snack(context, '${res['error']}', error: true);
      return;
    }
    if (mounted) Navigator.pop(context, true);
  }

  Widget _label(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w700, color: _abu, fontSize: 11, letterSpacing: 0.5),
      );

  Widget _card({required List<Widget> children}) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _pillGroup(List<String> opsi, String? selected, void Function(String) onTap) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: opsi.map((o) => DsChip(label: o, aktif: selected == o, onTap: () => onTap(o))).toList(),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Usul Lomba')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF3FB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '💡 Usulanmu akan ditinjau dan ditambahkan ke daftar lomba jika disetujui.',
                style: TextStyle(color: _navy, fontSize: 12.5),
              ),
            ),
            _card(children: [
              _label('Nama Lomba'),
              const SizedBox(height: 8),
              TextField(controller: _judul, decoration: _kotakInput('mis. Hackathon Nasional 2026')),
            ]),
            _card(children: [
              _label('Deskripsi'),
              const SizedBox(height: 8),
              TextField(controller: _deskripsi, maxLines: 4, decoration: _kotakInput('Ceritakan tentang lomba ini')),
              const SizedBox(height: 16),
              _label('Kategori'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kategoriOpsi
                    .map((k) => DsChip(
                        label: k,
                        aktif: _kategori.contains(k),
                        onTap: () => setState(() => _kategori.contains(k) ? _kategori.remove(k) : _kategori.add(k))))
                    .toList(),
              ),
            ]),
            _card(children: [
              _label('Penyelenggara'),
              const SizedBox(height: 8),
              TextField(controller: _penyelenggara, decoration: _kotakInput('mis. Kemendikbudristek')),
              const SizedBox(height: 16),
              _label('Cakupan'),
              const SizedBox(height: 8),
              _pillGroup(_cakupanOpsi, _cakupan, (o) => setState(() => _cakupan = o)),
            ]),
            _card(children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _label('Tenggat'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _tenggatDate ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                          );
                          if (picked != null) setState(() => _tenggatDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today, size: 18)),
                          child: Text(
                            _tenggatDate == null
                                ? 'Pilih tanggal'
                                : '${_tenggatDate!.day}/${_tenggatDate!.month}/${_tenggatDate!.year}',
                            style: TextStyle(color: _tenggatDate == null ? Colors.grey.shade600 : _navy),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _label('Hadiah'),
                      const SizedBox(height: 8),
                      TextField(controller: _hadiah, decoration: _kotakInput('Rp30 juta')),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _label('Format Tim'),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minAnggota,
                      keyboardType: TextInputType.number,
                      decoration: _kotakInput('Min'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxAnggota,
                      keyboardType: TextInputType.number,
                      decoration: _kotakInput('Max'),
                    ),
                  ),
                ],
              ),
            ]),
            _card(children: [
              _label('Biaya Daftar'),
              const SizedBox(height: 8),
              _pillGroup(['Gratis', 'Berbayar'], _jenisBiaya == 'GRATIS' ? 'Gratis' : 'Berbayar', (o) {
                setState(() => _jenisBiaya = o == 'Gratis' ? 'GRATIS' : 'BERBAYAR');
              }),
              if (_jenisBiaya == 'BERBAYAR') ...[
                const SizedBox(height: 12),
                TextField(controller: _nominalBiaya, decoration: _kotakInput('mis. Rp50.000/tim')),
              ],
            ]),
            _card(children: [
              _label('Tautan & Kontak'),
              const SizedBox(height: 8),
              TextField(
                controller: _kontakInstagram,
                decoration: _kotakInput('@username Instagram',
                    prefixIcon: const Icon(Icons.camera_alt_rounded, color: Color(0xFFE1306C))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _kontakWebsite,
                decoration: _kotakInput('Website resmi', prefixIcon: const Icon(Icons.language_rounded, color: _biru)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _kontakNarahubung,
                decoration: _kotakInput('Nama & nomor narahubung',
                    prefixIcon: const Icon(Icons.phone_rounded, color: _hijau)),
              ),
            ]),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _saving ? null : _simpan,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Kirim Usulan'),
            ),
          ),
        ),
      );
}

// ------------------------------------------------------------------------------------------------
// Detail lomba — daftar tim/lobi yang sudah dibentuk
// ------------------------------------------------------------------------------------------------

class DetailLombaPage extends StatefulWidget {
  final String lombaId;
  const DetailLombaPage({super.key, required this.lombaId});
  @override
  State<DetailLombaPage> createState() => _DetailLombaPageState();
}

class _DetailLombaPageState extends State<DetailLombaPage> {
  dynamic _lomba;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() => _loading = true);
    final res = await apiGet('/team-formation/lomba/${widget.lombaId}');
    setState(() {
      _lomba = (res is Map && res['error'] == null) ? res : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_lomba == null) {
      return Scaffold(appBar: AppBar(title: const Text('Detail Lomba')), body: const Center(child: Text('Lomba tidak ditemukan')));
    }
    final lobi = (_lomba['lobi'] as List?) ?? [];
    final kategori = ((_lomba['kategoriLomba'] as List?)?.cast<String>() ?? []);
    final subjudul = [
      if (_lomba['cakupan'] != null) _lomba['cakupan'],
      _lomba['penyelenggara'] ?? 'Penyelenggara tidak diketahui',
    ].join(' · ');
    final formatTim = _lomba['minAnggotaTim'] != null
        ? 'Tim ${_lomba['minAnggotaTim']}-${_lomba['maxAnggotaTim']} orang'
        : 'Maks ${_lomba['maxAnggotaTim']} orang';
    final biaya = _lomba['jenisBiaya'] == 'BERBAYAR' ? (_lomba['nominalBiaya'] ?? 'Berbayar') : 'Gratis';
    return Scaffold(
      appBar: AppBar(title: Text(_lomba['judul'] ?? 'Detail Lomba')),
      body: RefreshIndicator(
        onRefresh: _muat,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const CircleAvatar(radius: 24, backgroundColor: Color(0xFFEFF3FB), child: Icon(Icons.emoji_events, color: _biru, size: 26)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(subjudul, style: const TextStyle(color: _abu, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(_lomba['judul'] ?? '', style: const TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 18)),
                          ],
                        ),
                      ),
                    ]),
                    if (kategori.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _chipList(kategori),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(_lomba['deskripsi'] ?? '', style: const TextStyle(color: _navy, fontSize: 14, height: 1.4)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: _infoBox(
                  'Tenggat',
                  _lomba['tenggat'] == null ? '-' : _formatTenggat(_lomba['tenggat']),
                  Icons.calendar_today_rounded,
                  highlight: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoBox(
                  'Hadiah',
                  _lomba['hadiah'] ?? '-',
                  Icons.emoji_events_rounded,
                  accent: _hijau,
                  accentBg: const Color(0xFFDCFCE7),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _infoBox('Format tim', formatTim, Icons.groups_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _infoBox('Biaya daftar', biaya, Icons.confirmation_number_rounded)),
            ]),
            if (_lomba['kontakInstagram'] != null || _lomba['kontakWebsite'] != null || _lomba['kontakNarahubung'] != null) ...[
              _sectionTitle('Kontak'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_lomba['kontakInstagram'] != null)
                      _kontakRow(Icons.camera_alt_rounded, const Color(0xFFE1306C), 'INSTAGRAM', _lomba['kontakInstagram']),
                    if (_lomba['kontakWebsite'] != null) ...[
                      if (_lomba['kontakInstagram'] != null) const SizedBox(height: 12),
                      _kontakRow(Icons.language_rounded, _biru, 'WEBSITE', _lomba['kontakWebsite']),
                    ],
                    if (_lomba['kontakNarahubung'] != null) ...[
                      if (_lomba['kontakInstagram'] != null || _lomba['kontakWebsite'] != null) const SizedBox(height: 12),
                      _kontakRow(Icons.phone_rounded, _hijau, 'NARAHUBUNG', _lomba['kontakNarahubung']),
                    ],
                  ],
                ),
              ),
            ],
            Row(children: [
              Expanded(child: _sectionTitle('Lobi tim (${lobi.length})')),
              TextButton.icon(
                onPressed: () async {
                  final ok = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BuatLobiPage(lombaId: widget.lombaId)),
                  );
                  if (ok == true) _muat();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Buat lobi'),
              ),
            ]),
            if (lobi.isEmpty)
              const _EmptyState(
                icon: Icons.groups_2_outlined,
                judul: 'Belum ada tim',
                subjudul: 'Jadilah yang pertama membentuk tim untuk lomba ini.',
              )
            else
              ...lobi.map((l) => _kartuLobi(l)),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String label, String value, IconData icon, {bool highlight = false, Color? accent, Color? accentBg}) {
    final accentColor = accent ?? (highlight ? _amber : null);
    final fg = accentColor ?? _navy;
    final bg = accentBg ?? (accentColor != null ? accentColor.withOpacity(0.12) : const Color(0xFFF8FAFC));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: accentColor ?? _abu),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: accentColor ?? _abu, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _kontakRow(IconData icon, Color color, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: _abu, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                Text(value, style: const TextStyle(color: _navy, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      );

  Widget _kartuLobi(dynamic l) {
    final anggota = (l['anggota'] as List?) ?? [];
    final rolesTerbuka = ((l['rolesTerbuka'] as List?)?.cast<String>() ?? []);
    final dimensiTerbuka = ((l['dimensiTerbuka'] as List?)?.cast<String>() ?? []);
    final statusSaya = l['statusSaya'] as String?;
    final milikSaya = l['milikSaya'] as bool? ?? false;
    final bisaGabung = l['bisaGabung'] as bool? ?? true;
    final alasanTidakBisaGabung = l['alasanTidakBisaGabung'] as String?;
    const avatarColors = [Color(0xFF7C3AED), Color(0xFFEA580C), Color(0xFFDB2777), Color(0xFF0891B2), Color(0xFF16A34A)];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => DetailLobiPage(lobiId: l['id'])));
          _muat();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(l['judul'] ?? '', style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                if (milikSaya)
                  _badgeChip('Buatanmu', _hijau, const Color(0xFFDCFCE7))
                else if (statusSaya != null)
                  _badgeChip(_statusLabel(statusSaya), _statusFg(statusSaya), _statusBg(statusSaya))
                else
                  _badgeChip(
                    l['status'] == 'FINAL' ? 'Final' : (l['status'] == 'CLOSED' ? 'Ditutup' : 'Terbuka'),
                    l['status'] == 'FINAL' ? _hijau : (l['status'] == 'CLOSED' ? _abu : _biru),
                    l['status'] == 'FINAL' ? const Color(0xFFDCFCE7) : const Color(0xFFEFF3FB),
                  ),
              ]),
              const SizedBox(height: 4),
              Text('${l['jumlahAnggota']}/${l['totalKuota']} anggota', style: const TextStyle(color: _abu, fontSize: 12)),
              if (anggota.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(anggota.length, (i) {
                    final nama = (anggota[i]['nama'] ?? '?') as String;
                    return CircleAvatar(
                      radius: 15,
                      backgroundColor: avatarColors[i % avatarColors.length],
                      child: Text(_inisial2(nama), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    );
                  }),
                ),
              ],
              if (rolesTerbuka.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('🔧 ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text('Teknis terbuka: ${rolesTerbuka.join(' · ')}', style: const TextStyle(color: _abu, fontSize: 12)),
                  ),
                ]),
              ],
              if (dimensiTerbuka.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('⚛️ ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      'Dimensi TREO terbuka: ${dimensiTerbuka.map((d) => _treoDimLabel[d] ?? d).join(' · ')}',
                      style: const TextStyle(color: _abu, fontSize: 12),
                    ),
                  ),
                ]),
              ],
              if (statusSaya == null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: bisaGabung
                        ? () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => DetailLobiPage(lobiId: l['id'])));
                            _muat();
                          }
                        : null,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                    label: const Text('Ajukan Bergabung'),
                  ),
                ),
                if (!bisaGabung && alasanTidakBisaGabung != null) ...[
                  const SizedBox(height: 6),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline_rounded, size: 13, color: _abu),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(alasanTidakBisaGabung, style: const TextStyle(color: _abu, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _inisial2(String nama) {
  final parts = nama.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

// ------------------------------------------------------------------------------------------------
// Buat lobi/tim baru untuk sebuah lomba
// ------------------------------------------------------------------------------------------------

class _RoleDraft {
  String namaRole;
  int kuota;
  _RoleDraft({this.namaRole = _domainRole0, this.kuota = 1});
}

const _domainRole0 = 'Programmer';

class BuatLobiPage extends StatefulWidget {
  final String lombaId;
  const BuatLobiPage({super.key, required this.lombaId});
  @override
  State<BuatLobiPage> createState() => _BuatLobiPageState();
}

class _BuatLobiPageState extends State<BuatLobiPage> {
  final _judul = TextEditingController();
  final _deskripsi = TextEditingController();
  final List<_RoleDraft> _roles = [];
  dynamic _lomba;
  bool _loadingLomba = true;
  int? _kapasitas;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _muatLomba();
  }

  @override
  void dispose() {
    _judul.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  Future<void> _muatLomba() async {
    final res = await apiGet('/team-formation/lomba/${widget.lombaId}');
    setState(() {
      _lomba = (res is Map && res['error'] == null) ? res : null;
      _kapasitas = _lomba?['maxAnggotaTim'] as int?;
      _loadingLomba = false;
    });
  }

  Future<void> _pilihPeran() async {
    final dipilih = _roles.map((r) => r.namaRole).toSet();
    final hasil = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final sementara = {...dipilih};
        return StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pilih peran yang dicari', style: TextStyle(fontWeight: FontWeight.w700, color: _navy, fontSize: 16)),
                if (_kapasitas != null) ...[
                  const SizedBox(height: 4),
                  Text('Maksimal $_kapasitas role (mengikuti kapasitas tim)',
                      style: const TextStyle(color: _abu, fontSize: 12)),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _domainRole.map((r) {
                    final aktif = sementara.contains(r);
                    final penuh = _kapasitas != null && sementara.length >= _kapasitas! && !aktif;
                    return DsChip(
                      label: r,
                      aktif: aktif,
                      enabled: !penuh,
                      onTap: () => setSheet(() => aktif ? sementara.remove(r) : sementara.add(r)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, sementara),
                    child: const Text('Terapkan'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (hasil == null) return;
    setState(() {
      _roles.removeWhere((r) => !hasil.contains(r.namaRole));
      for (final nama in hasil) {
        if (!_roles.any((r) => r.namaRole == nama)) _roles.add(_RoleDraft(namaRole: nama));
      }
    });
  }

  Future<void> _simpan() async {
    if (_judul.text.trim().isEmpty) {
      _snack(context, 'Nama lobi wajib diisi', error: true);
      return;
    }
    if (_roles.isEmpty) {
      _snack(context, 'Pilih minimal 1 peran yang dicari', error: true);
      return;
    }
    if (_kapasitas != null && _roles.length > _kapasitas!) {
      _snack(context, 'Jumlah role teknis tidak boleh melebihi kapasitas tim ($_kapasitas)', error: true);
      return;
    }
    setState(() => _saving = true);
    final res = await apiPost('/team-formation/lomba/${widget.lombaId}/lobi', {
      'judul': _judul.text.trim(),
      if (_deskripsi.text.trim().isNotEmpty) 'deskripsi': _deskripsi.text.trim(),
      if (_kapasitas != null) 'kapasitas': _kapasitas,
      'roles': _roles
          .map((r) => {
                'namaRole': r.namaRole,
                'kuota': r.kuota,
              })
          .toList(),
    });
    setState(() => _saving = false);
    if (res is Map && res['error'] != null) {
      _snack(context, '${res['error']}', error: true);
      return;
    }
    if (mounted) Navigator.pop(context, true);
  }

  Widget _labelKecil(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(color: _abu, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
      );

  Widget _kartu({required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final minTim = _lomba?['minAnggotaTim'] as int?;
    final maxTim = _lomba?['maxAnggotaTim'] as int?;
    final biaya = _lomba?['jenisBiaya'] == 'BERBAYAR' ? (_lomba?['nominalBiaya'] ?? 'Berbayar') : 'Gratis';
    final subjudulLomba = [
      if (minTim != null && maxTim != null) 'Tim $minTim-$maxTim orang',
      biaya,
      if (_lomba?['hadiah'] != null) _lomba['hadiah'],
    ].join(' · ');
    final opsiKapasitas = <int>[
      for (int i = (minTim ?? 2); i <= (maxTim ?? (minTim ?? 2) + 3); i++) i,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Lobi Tim')),
      body: _loadingLomba
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                if (_lomba != null)
                  _kartu(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(radius: 20, backgroundColor: Color(0xFFEFF3FB), child: Icon(Icons.emoji_events, color: _biru, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('LOMBA', style: TextStyle(color: _abu, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                              const SizedBox(height: 2),
                              Text(_lomba['judul'] ?? '', style: const TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(subjudulLomba, style: const TextStyle(color: _abu, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                _labelKecil('NAMA LOBI *'),
                TextField(controller: _judul, decoration: _kotakInput('mis. Tim Elang Data')),
                const SizedBox(height: 16),
                _labelKecil('DESKRIPSI TIM'),
                TextField(controller: _deskripsi, maxLines: 3, decoration: _kotakInput('Visi/strategi tim untuk lomba ini')),
                const SizedBox(height: 16),
                _labelKecil('KAPASITAS MAKSIMAL'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: opsiKapasitas.map((n) {
                    return DsChip(
                      label: '$n',
                      aktif: _kapasitas == n,
                      onTap: () => setState(() => _kapasitas = n),
                    );
                  }).toList(),
                ),
                if (minTim != null && maxTim != null) ...[
                  const SizedBox(height: 6),
                  Text('Sesuai format lomba: Tim $minTim-$maxTim orang', style: const TextStyle(color: _abu, fontSize: 11)),
                ],
                const SizedBox(height: 16),
                _labelKecil('PERAN YANG DICARI'),
                InkWell(
                  onTap: _pilihPeran,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.add, size: 18, color: _biru),
                      const SizedBox(width: 8),
                      Text(
                        _roles.isEmpty ? 'Pilih peran yang dicari...' : 'Ubah peran yang dicari',
                        style: const TextStyle(color: _biru, fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
                ),
                if (_roles.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _roles
                        .map((r) => Chip(
                              label: Text(r.namaRole),
                              onDeleted: () => setState(() => _roles.removeWhere((x) => x.namaRole == r.namaRole)),
                              backgroundColor: const Color(0xFFEFF3FB),
                              labelStyle: const TextStyle(color: _navy, fontWeight: FontWeight.w600),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saving ? null : _simpan,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Buat Tim'),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------------------------------------
// Detail lobi/tim — browse peran, daftar, status pendaftaran, kelola (pembuat tim), skor final, TREO, diskusi
// ------------------------------------------------------------------------------------------------

const Map<String, String> _treoDimLabel = {
  'organizer': 'Organizer',
  'doer': 'Doer',
  'challenger': 'Challenger',
  'innovator': 'Innovator',
  'teamBuilder': 'Team Builder',
  'connector': 'Connector',
};

Color _warnaSkor(int persen) {
  if (persen < 34) return Colors.red.shade600;
  if (persen <= 70) return _amber;
  return _hijau;
}

// Label kualitatif rendah/menengah/tinggi mengikuti ambang yang sama dgn _warnaSkor.
String _labelSkorKualitatif(double nilai) {
  final persen = (nilai * 100).round();
  if (persen < 34) return 'rendah';
  if (persen <= 70) return 'menengah';
  return 'tinggi';
}

// Request 3a: keterangan dinamis utk "Nilai Kecocokan Fungsi Teknis Tim".
String _keteranganKecocokanTeknis(
  int roleTerisiCount,
  int totalRole,
  List<String> roleDibutuhkan,
  double nilaiTeknis,
) {
  if (totalRole > 0 && roleTerisiCount < totalRole) {
    return 'Butuh diversifikasi role teknis'
        '${roleDibutuhkan.isNotEmpty ? ': ${roleDibutuhkan.join(', ')}' : ''}';
  }
  final label = _labelSkorKualitatif(nilaiTeknis);
  if (label == 'rendah') return 'Kecocokan individu ke role teknis rendah';
  if (label == 'menengah') return 'Kecocokan menengah';
  return 'Kecocokan teknis mencukupi';
}

// Request 3b: keterangan "Skor Keseimbangan Tim" dari kombinasi skor teknis & fungsi tim.
String _keteranganKeseimbangan(double nilaiTeknis, double nilaiFungsi) {
  return 'Skor teknis ${_labelSkorKualitatif(nilaiTeknis)} + skor fungsi tim ${_labelSkorKualitatif(nilaiFungsi)}';
}

// Keterangan dinamis utk "Nilai Kecocokan Fungsi Kerja Tim".
String _keteranganFungsiKerja(
  int terisi,
  int totalKuota,
  List<String> dimensiTerbuka,
  double nilaiFungsi,
) {
  if (totalKuota > 0 && terisi < totalKuota) {
    return 'Anggota perlu dipenuhi'
        '${dimensiTerbuka.isNotEmpty ? ': butuh dimensi ${dimensiTerbuka.join(', ')}' : ''}';
  }
  final label = _labelSkorKualitatif(nilaiFungsi);
  if (label == 'rendah' || label == 'menengah') {
    return 'Butuh diversifikasi fungsi kerja tim'
        '${dimensiTerbuka.isNotEmpty ? ': ${dimensiTerbuka.join(', ')}' : ''}';
  }
  return 'Fungsi kerja tim sudah beragam';
}

// Request 2: kelompokkan hasil assignment TREO (per dimensi) menjadi per-anggota (maks 2 dimensi/orang).
const _dimensiUrut = ['organizer', 'doer', 'challenger', 'innovator', 'teamBuilder', 'connector'];

Map<String, List<String>> _dimensiPerAnggota(Map? assignment) {
  final hasil = <String, List<String>>{};
  if (assignment == null) return hasil;
  for (final d in _dimensiUrut) {
    final slot = assignment[d];
    if (slot is Map && (slot['mahasiswaId'] ?? '').toString().isNotEmpty) {
      hasil.putIfAbsent(slot['mahasiswaId'].toString(), () => []).add(d);
    }
  }
  return hasil;
}

Widget _metrikTim(String label, double nilai, String? keterangan, {bool tampilkanBar = true, bool besar = false}) {
  final persen = (nilai * 100).round();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: _navy, fontSize: 13, fontWeight: FontWeight.w600))),
        if (!besar) Text('$persen%', style: const TextStyle(color: _navy, fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
      if (besar) ...[
        const SizedBox(height: 2),
        Text('$persen%', style: TextStyle(color: _warnaSkor(persen), fontSize: 30, fontWeight: FontWeight.w800)),
      ],
      if (tampilkanBar) ...[
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: nilai.clamp(0, 1).toDouble(),
            backgroundColor: const Color(0xFFE7ECF5),
            color: _warnaSkor(persen),
            minHeight: 6,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
      if (keterangan != null) ...[
        const SizedBox(height: 4),
        Text(keterangan, style: const TextStyle(color: _abu, fontSize: 11)),
      ],
    ],
  );
}

class EditTimPage extends StatefulWidget {
  final String lobiId;
  const EditTimPage({super.key, required this.lobiId});
  @override
  State<EditTimPage> createState() => _EditTimPageState();
}

class _EditTimPageState extends State<EditTimPage> {
  bool _loading = true;
  bool _busy = false;
  bool _berubah = false;
  Map<String, dynamic>? _lobi;
  final _judulCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final Map<String, String> _roleOverride = {};
  int _kapasitas = 1;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    setState(() => _loading = true);
    try {
      final data = await apiGet('/team-formation/lobi/${widget.lobiId}');
      setState(() {
        _lobi = data as Map<String, dynamic>;
        _judulCtrl.text = (_lobi?['judul'] ?? '').toString();
        _deskripsiCtrl.text = (_lobi?['deskripsi'] ?? '').toString();
        _kapasitas = (_lobi?['kapasitas'] as num?)?.toInt() ?? 1;
      });
    } catch (e) {
      if (mounted) _snack(context, 'Gagal memuat data tim: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _simpanNamaDeskripsi() async {
    final anggotaAktif = (_lobi?['anggota'] as List?)?.length ?? 0;
    if (_kapasitas < anggotaAktif) {
      _snack(context, 'Kapasitas tidak boleh kurang dari jumlah anggota aktif saat ini ($anggotaAktif)', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await apiPatch('/team-formation/lobi/${widget.lobiId}', {
        'judul': _judulCtrl.text.trim(),
        'deskripsi': _deskripsiCtrl.text.trim(),
        'kapasitas': _kapasitas,
      });
      if (res is Map && res['error'] != null) {
        if (mounted) _snack(context, '${res['error']}', error: true);
        return;
      }
      for (final entry in _roleOverride.entries) {
        final roleRes = await apiPatch('/team-formation/lobi/${widget.lobiId}/anggota/${entry.key}', {'roleId': entry.value});
        if (roleRes is Map && roleRes['error'] != null) {
          if (mounted) _snack(context, '${roleRes['error']}', error: true);
          return;
        }
      }
      _roleOverride.clear();
      _berubah = true;
      if (mounted) {
        _snack(context, 'Perubahan tersimpan');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _snack(context, 'Gagal menyimpan: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _stageRoleAnggota(String pendaftaranId, String roleId) {
    setState(() => _roleOverride[pendaftaranId] = roleId);
  }

  Future<void> _keluarkanAnggota(String pendaftaranId, String nama) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluarkan anggota?'),
        content: Text('$nama akan dikeluarkan dari tim ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluarkan')),
        ],
      ),
    );
    if (konfirmasi != true) return;
    setState(() => _busy = true);
    try {
      final res = await apiDelete('/team-formation/lobi/${widget.lobiId}/anggota/$pendaftaranId');
      if (res is Map && res['error'] != null) {
        if (mounted) _snack(context, '${res['error']}', error: true);
        return;
      }
      _berubah = true;
      await _muat();
    } catch (e) {
      if (mounted) _snack(context, 'Gagal mengeluarkan anggota: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pilihRoleTerbuka() async {
    final l = _lobi!;
    final roles = (l['roles'] as List).cast<Map<String, dynamic>>();
    final dipilihAwal = roles.map((r) => r['namaRole'] as String).toSet();
    final hasil = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final sementara = {...dipilihAwal};
        return StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pilih peran yang dibuka', style: TextStyle(fontWeight: FontWeight.w700, color: _navy, fontSize: 16)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _domainRole.map((r) {
                    final aktif = sementara.contains(r);
                    return DsChip(
                      label: r,
                      aktif: aktif,
                      onTap: () => setSheet(() => aktif ? sementara.remove(r) : sementara.add(r)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, sementara),
                    child: const Text('Terapkan'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (hasil == null) return;
    final tambah = hasil.difference(dipilihAwal);
    final hapus = roles.where((r) => !hasil.contains(r['namaRole'])).toList();
    if (tambah.isEmpty && hapus.isEmpty) return;
    setState(() => _busy = true);
    try {
      for (final nama in tambah) {
        final res = await apiPost('/team-formation/lobi/${widget.lobiId}/roles', {'namaRole': nama});
        if (res is Map && res['error'] != null) {
          if (mounted) _snack(context, '${res['error']}', error: true);
          continue;
        }
      }
      for (final r in hapus) {
        final res = await apiDelete('/team-formation/lobi/${widget.lobiId}/roles/${r['id']}');
        if (res is Map && res['error'] != null) {
          if (mounted) _snack(context, '${res['error']}', error: true);
          continue;
        }
      }
      _berubah = true;
      await _muat();
    } catch (e) {
      if (mounted) _snack(context, 'Gagal mengubah peran yang dibuka: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _label(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w700, color: _abu, fontSize: 11, letterSpacing: 0.5),
      );

  Widget _card({required List<Widget> children}) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  @override
  Widget build(BuildContext context) {
    final isFinal = _lobi?['status'] == 'FINAL';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _berubah);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kelola Pengajuan'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context, _berubah)),
        ),
        body: _loading || _lobi == null
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(context, isFinal),
        bottomNavigationBar: _loading || _lobi == null || isFinal
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _simpanNamaDeskripsi,
                      child: _busy
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Simpan Perubahan'),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isFinal) {
    final l = _lobi!;
    final anggota = (l['anggota'] as List).cast<Map<String, dynamic>>();
    final roles = (l['roles'] as List).cast<Map<String, dynamic>>();
    final nonaktif = _busy || isFinal;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        if (isFinal)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(children: [
              Icon(Icons.lock_outline, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tim sudah final dan tidak bisa diubah lagi.',
                  style: TextStyle(color: Colors.red, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF3FB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            const Icon(Icons.emoji_events, color: _biru, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text((l['lomba']?['judul'] ?? '-').toString(),
                  style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ]),
        ),
        _card(children: [
          _label('Nama Tim'),
          const SizedBox(height: 8),
          TextField(
            controller: _judulCtrl,
            readOnly: isFinal,
            decoration: _kotakInput('Nama tim'),
          ),
          const SizedBox(height: 16),
          _label('Deskripsi Tim'),
          const SizedBox(height: 8),
          TextField(
            controller: _deskripsiCtrl,
            maxLines: 4,
            readOnly: isFinal,
            decoration: _kotakInput('Deskripsi tim'),
          ),
          const SizedBox(height: 16),
          _label('Kapasitas Anggota'),
          const SizedBox(height: 8),
          Row(children: [
            IconButton.filledTonal(
              onPressed: nonaktif || _kapasitas <= anggota.length
                  ? null
                  : () => setState(() => _kapasitas--),
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: Center(
                child: Text('$_kapasitas',
                    style: const TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 20)),
              ),
            ),
            IconButton.filledTonal(
              onPressed: nonaktif || _kapasitas >= (l['lomba']?['maxAnggotaTim'] ?? _kapasitas)
                  ? null
                  : () => setState(() => _kapasitas++),
              icon: const Icon(Icons.add),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            'Minimal ${anggota.length} (jumlah anggota aktif saat ini), maksimal ${l['lomba']?['maxAnggotaTim'] ?? '-'} sesuai lomba.',
            style: const TextStyle(color: _abu, fontSize: 11.5),
          ),
        ]),
        _label('Anggota Tim'),
        const SizedBox(height: 8),
        Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            children: anggota.map((a) {
              final isKoordinator = a['nama'] == l['namaKoordinator'];
              final treoDominan = a['treoDominan'] as String?;
              final treoLabel = treoDominan != null ? _treoDimLabel[treoDominan] : null;
              final pendaftaranId = a['pendaftaranId'] as String;
              final effectiveRoleId = _roleOverride[pendaftaranId] ?? a['roleId'];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isKoordinator ? const Color(0xFFFFEDD5) : const Color(0xFFF3E8FF),
                    child: Text(_inisial(a['nama'] ?? '?'),
                        style: TextStyle(
                            color: isKoordinator ? Colors.orange.shade800 : Colors.purple.shade700,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['nama'] ?? '-', style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          key: ValueKey('role_${pendaftaranId}_$effectiveRoleId'),
                          initialValue: roles.any((r) => r['id'] == effectiveRoleId) ? effectiveRoleId as String : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          items: roles
                              .map((r) => DropdownMenuItem(value: r['id'] as String, child: Text(r['namaRole'] ?? '-')))
                              .toList(),
                          onChanged: nonaktif
                              ? null
                              : (v) {
                                  if (v != null && v != effectiveRoleId) {
                                    _stageRoleAnggota(pendaftaranId, v);
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (treoLabel != null)
                    _badgeChip(
                        treoLabel,
                        treoDominan == 'organizer' ? Colors.orange.shade800 : _abu,
                        treoDominan == 'organizer' ? const Color(0xFFFFEDD5) : const Color(0xFFF1F5F9)),
                  if (!isKoordinator)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Keluarkan anggota',
                      onPressed: nonaktif ? null : () => _keluarkanAnggota(a['pendaftaranId'] as String, a['nama'] ?? '-'),
                    ),
                ]),
              );
            }).toList(),
          ),
        ),
        _card(children: [
          _label('Peran yang Dibuka'),
          const SizedBox(height: 8),
          InkWell(
            onTap: nonaktif ? null : _pilihRoleTerbuka,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(children: [
                Icon(Icons.add, size: 18, color: nonaktif ? _abu : _biru),
                const SizedBox(width: 8),
                Text(
                  roles.isEmpty ? 'Pilih peran yang dibuka...' : 'Ubah peran yang dibuka',
                  style: TextStyle(color: nonaktif ? _abu : _biru, fontWeight: FontWeight.w600),
                ),
              ]),
            ),
          ),
          if (roles.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roles
                  .map((r) => Chip(
                        label: Text(r['namaRole'] ?? '-'),
                        onDeleted: nonaktif ? null : () => _hapusSatuRole(r['id'] as String),
                        backgroundColor: const Color(0xFFEFF3FB),
                        labelStyle: const TextStyle(color: _navy, fontWeight: FontWeight.w600),
                      ))
                  .toList(),
            ),
          ],
        ]),
        if (!isFinal)
          _card(children: [
            _label('Zona Berbahaya'),
            const SizedBox(height: 8),
            const Text(
              'Tim hanya bisa dihapus selama belum ada anggota lain yang bergabung dan tidak ada pengajuan yang menunggu keputusan.',
              style: TextStyle(color: _abu, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _hapusTim,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Hapus Tim', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ),
          ]),
      ],
    );
  }

  // Dijalankan setiap kali tombol "Hapus Tim" ditekan — cek alasan yang mungkin
  // menghalangi (bukan cuma nonaktifkan tombolnya) supaya pembuat tim paham
  // langkah apa yang perlu diambil dulu sebelum bisa menghapus.
  Future<void> _hapusTim() async {
    final l = _lobi!;
    if (l['status'] != 'OPEN') {
      _jelaskanTidakBisaHapus(
        'Tim tidak bisa dihapus',
        l['status'] == 'FINAL'
            ? 'Tim ini sudah final dan tidak bisa dihapus lagi.'
            : 'Tim sedang dalam proses finalisasi. Batalkan atau selesaikan dulu prosesnya sebelum menghapus tim.',
      );
      return;
    }
    final anggota = (l['anggota'] as List).cast<Map<String, dynamic>>();
    final anggotaLain = anggota.length - 1; // pembuat tim selalu ikut sebagai anggota ACCEPTED
    if (anggotaLain > 0) {
      _jelaskanTidakBisaHapus(
        'Tim masih punya anggota',
        'Masih ada $anggotaLain anggota lain di tim ini. Keluarkan semua anggota lewat daftar "Anggota Tim" di atas sebelum menghapus tim.',
      );
      return;
    }
    final pendingCount = (l['pendingCount'] as num?)?.toInt() ?? 0;
    if (pendingCount > 0) {
      _jelaskanTidakBisaHapus(
        'Masih ada pengajuan menunggu',
        'Ada $pendingCount pengajuan yang belum diputuskan. Terima atau tolak semuanya dulu lewat halaman "Kelola Pengajuan" sebelum menghapus tim.',
      );
      return;
    }

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus tim ini?'),
        content: const Text(
            'Tim akan dihapus permanen dan tidak bisa dikembalikan. Lombanya tetap ada, kamu bisa membuat tim baru kapan saja.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (konfirmasi != true) return;

    setState(() => _busy = true);
    try {
      final res = await apiDelete('/team-formation/lobi/${widget.lobiId}');
      if (res is Map && res['error'] != null) {
        if (mounted) _snack(context, '${res['error']}', error: true);
        return;
      }
      _berubah = true;
      if (mounted) {
        _snack(context, 'Tim berhasil dihapus');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _snack(context, 'Gagal menghapus tim: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _jelaskanTidakBisaHapus(String judul, String pesan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(judul, style: const TextStyle(fontWeight: FontWeight.bold, color: _navy)),
        content: Text(pesan, style: const TextStyle(color: _navy, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<void> _hapusSatuRole(String roleId) async {
    setState(() => _busy = true);
    try {
      final res = await apiDelete('/team-formation/lobi/${widget.lobiId}/roles/$roleId');
      if (res is Map && res['error'] != null) {
        if (mounted) _snack(context, '${res['error']}', error: true);
        return;
      }
      _berubah = true;
      await _muat();
    } catch (e) {
      if (mounted) _snack(context, 'Gagal menghapus peran: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class DetailLobiPage extends StatefulWidget {
  final String lobiId;
  const DetailLobiPage({super.key, required this.lobiId});
  @override
  State<DetailLobiPage> createState() => _DetailLobiPageState();
}

class _DetailLobiPageState extends State<DetailLobiPage> {
  dynamic _lobi;
  dynamic _treoTim;
  List _diskusi = [];
  bool _loading = true;
  bool _busy = false;
  bool _kirimBusy = false;
  String? _selectedRoleId;
  String? _myId;
  final _pesanCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _pesanCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    setState(() => _loading = true);
    final res = await apiGet('/team-formation/lobi/${widget.lobiId}');
    if (res is Map && res['error'] == null) {
      _lobi = res;
      final status = res['status'];
      final isMember = res['statusSaya'] == 'ACCEPTED' || res['milikSaya'] == true;
      if (status != 'CLOSED') {
        final t = await apiGet('/team-formation/lobi/${widget.lobiId}/treo-tim');
        if (t is Map && t['error'] == null) _treoTim = t;
      }
      if (isMember) {
        final d = await apiGet('/team-formation/lobi/${widget.lobiId}/diskusi');
        if (d is List) _diskusi = d;
        if (_myId == null) {
          final me = await apiGet('/auth/me');
          if (me is Map && me['error'] == null) _myId = me['id']?.toString();
        }
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _gabung(String roleId) async {
    setState(() => _busy = true);
    final res = await apiPost('/team-formation/lobi/${widget.lobiId}/daftar', {'roleId': roleId});
    setState(() => _busy = false);
    if (res is Map && res['error'] != null) {
      if (mounted) _snack(context, '${res['error']}', error: true);
      return;
    }
    if (mounted) _snack(context, 'Berhasil mendaftar, menunggu keputusan pembuat tim');
    _muat();
  }

  Future<void> _batalkan(String pendaftaranId) async {
    setState(() => _busy = true);
    final res = await apiDelete('/team-formation/pendaftaran/$pendaftaranId');
    setState(() => _busy = false);
    if (res is Map && res['error'] != null) {
      if (mounted) _snack(context, '${res['error']}', error: true);
      return;
    }
    if (res is Map && res['lobiDihapus'] == true) {
      if (mounted) {
        _snack(context, 'Anda anggota terakhir, lobi telah dihapus');
        Navigator.pop(context);
      }
      return;
    }
    if (mounted) _snack(context, 'Pendaftaran dibatalkan');
    _muat();
  }

  Future<void> _keluarTim(String pendaftaranId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar dari Tim'),
        content: const Text('Anda akan keluar dari tim ini dan bisa mendaftar ke tim lain. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _batalkan(pendaftaranId);
  }

  Future<void> _kirimPesan() async {
    final teks = _pesanCtrl.text.trim();
    if (teks.isEmpty) return;
    _pesanCtrl.clear();
    final res = await apiPost('/team-formation/lobi/${widget.lobiId}/diskusi', {'pesan': teks});
    if (res is Map && res['error'] != null) {
      if (mounted) _snack(context, '${res['error']}', error: true);
      return;
    }
    final d = await apiGet('/team-formation/lobi/${widget.lobiId}/diskusi');
    if (d is List && mounted) setState(() => _diskusi = d);
  }

  Future<void> _inisiasiFinalisasi() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Inisiasi Finalisasi Tim'),
        content: const Text('Seluruh anggota akan diminta menyetujui finalisasi. Roster tim akan dikunci setelah semua setuju. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Inisiasi')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    final res = await apiPost('/team-formation/lobi/${widget.lobiId}/finalisasi/inisiasi', {});
    setState(() => _busy = false);
    if (res is Map && res['error'] != null) {
      if (mounted) _snack(context, '${res['error']}', error: true);
      return;
    }
    if (mounted) _snack(context, 'Finalisasi diinisiasi, menunggu persetujuan anggota');
    _muat();
  }

  Future<void> _setujuFinalisasi() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Setujui Finalisasi'),
        content: const Text('Setelah semua anggota setuju, roster tim akan dikunci dan skor akhir dihitung. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Setuju')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    final res = await apiPost('/team-formation/lobi/${widget.lobiId}/finalisasi/setuju', {});
    setState(() => _busy = false);
    if (res is Map && res['error'] != null) {
      if (mounted) _snack(context, '${res['error']}', error: true);
      return;
    }
    if (mounted) _snack(context, 'Persetujuan finalisasi tercatat');
    _muat();
  }

  Future<void> _tolakFinalisasi() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tolak Finalisasi'),
        content: const Text('Finalisasi akan dibatalkan dan status tim kembali terbuka. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    final res = await apiPost('/team-formation/lobi/${widget.lobiId}/finalisasi/tolak', {});
    setState(() => _busy = false);
    if (res is Map && res['error'] != null) {
      if (mounted) _snack(context, '${res['error']}', error: true);
      return;
    }
    if (mounted) _snack(context, 'Finalisasi ditolak, tim kembali terbuka');
    _muat();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_lobi == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Tim tidak ditemukan')));
    final l = _lobi;
    final status = l['status'];
    final milikSaya = l['milikSaya'] == true;
    final statusSaya = l['statusSaya'];
    final roles = (l['roles'] as List?) ?? [];
    final anggota = (l['anggota'] as List?) ?? [];
    final affinityPerRole = (l['affinityPerRole'] as List?) ?? [];
    final totalKuota = roles.fold<int>(0, (s, r) => s + ((r['kuota'] as int?) ?? 0));
    final terisi = anggota.length;
    final penuh = totalKuota > 0 && terisi >= totalKuota;
    final sudahPunyaStatus = milikSaya || statusSaya != null;
    final bisaDaftar = status == 'OPEN' && !sudahPunyaStatus && !penuh;
    final rolesTerbuka = ((_treoTim?['rolesTerbuka'] as List?) ?? []).cast<String>();
    final dimensiTerbuka = ((_treoTim?['dimensiTerbuka'] as List?) ?? []).cast<String>();
    final roleTerisiCount = (l['roleTerisiCount'] as int?) ?? 0;
    final totalRole = (l['totalRole'] as int?) ?? 0;
    final roleDibutuhkan = ((l['roleDibutuhkan'] as List?)?.cast<String>() ?? []);
    final dimensiPerAnggotaAwal = _dimensiPerAnggota(_treoTim?['assignment'] as Map?);
    final isMember = milikSaya || statusSaya == 'ACCEPTED';

    if (isMember) {
      return _buildMemberView(context, l, milikSaya, roles, anggota, totalKuota, terisi, rolesTerbuka, dimensiTerbuka,
          roleTerisiCount: roleTerisiCount, totalRole: totalRole, roleDibutuhkan: roleDibutuhkan);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l['lomba']?['judul'] ?? l['judul'] ?? ''),
      ),
      body: RefreshIndicator(
        onRefresh: _muat,
        child: Scrollbar(
          controller: _scrollCtrl,
          thumbVisibility: true,
          child: ListView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l['lomba']?['judul'] ?? '-', style: const TextStyle(color: _abu, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(l['judul'] ?? '', style: const TextStyle(color: _navy, fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _badgeChip(
                        status == 'FINAL' ? 'Sudah difinalisasi' : (status == 'CLOSED' ? 'Ditutup' : 'Terbuka'),
                        status == 'FINAL' ? _hijau : (status == 'CLOSED' ? _abu : _biru),
                        status == 'FINAL' ? const Color(0xFFDCFCE7) : const Color(0xFFEFF3FB),
                      ),
                      const SizedBox(width: 8),
                      if (statusSaya != null) _badgeChip(_statusLabel(statusSaya), _statusFg(statusSaya), _statusBg(statusSaya)),
                    ]),
                    if ((l['deskripsi'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(l['deskripsi'], style: const TextStyle(color: _abu, fontSize: 13)),
                    ],
                    const SizedBox(height: 10),
                    Text('Pembuat Tim: ${l['namaKoordinator'] ?? '-'}', style: const TextStyle(color: _abu, fontSize: 12)),
                    const Divider(height: 24),
                    Text('Anggota Tim ($terisi/$totalKuota)', style: const TextStyle(color: _navy, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (anggota.isEmpty)
                      const Text('Belum ada anggota diterima', style: TextStyle(color: _abu, fontSize: 12))
                    else
                      ...anggota.map<Widget>((a) {
                        final dimensiSaya = dimensiPerAnggotaAwal[a['mahasiswaId']?.toString()] ?? const <String>[];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFFEFF3FB),
                              child: Text(_inisial(a['nama'] ?? '?'), style: const TextStyle(color: _biru, fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a['nama'] ?? '-', style: const TextStyle(color: _navy, fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text(a['role'] ?? '-', style: const TextStyle(color: _abu, fontSize: 11)),
                                ],
                              ),
                            ),
                            ...dimensiSaya.where((d) => d == 'organizer').map((d) => Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: _badgeChip(_treoDimLabel[d] ?? d, _biru, const Color(0xFFEFF3FB)),
                                )),
                          ]),
                        );
                      }),
                  ],
                ),
              ),
            ),

            if (_treoTim != null) ...[
              Row(children: [
                _sectionTitle('Kondisi Tim Saat Ini'),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _jelaskanAnalitikTim(context),
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.help_outline, size: 16, color: _abu),
                  ),
                ),
              ]),
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _metrikTim(
                        'Nilai Kecocokan Fungsi Teknis Tim',
                        (_treoTim['technicalRoleAffinityTeam'] as num?)?.toDouble() ?? 0,
                        _keteranganKecocokanTeknis(
                          roleTerisiCount,
                          totalRole,
                          roleDibutuhkan,
                          (_treoTim['technicalRoleAffinityTeam'] as num?)?.toDouble() ?? 0,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _metrikTim(
                        'Nilai Kecocokan Fungsi Kerja Tim',
                        (_treoTim['teamFunctionAffinity'] as num?)?.toDouble() ?? 0,
                        _keteranganFungsiKerja(
                          terisi,
                          totalKuota,
                          dimensiTerbuka,
                          (_treoTim['teamFunctionAffinity'] as num?)?.toDouble() ?? 0,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _metrikTim(
                        'Skor Keseimbangan Tim',
                        (_treoTim['effectivenessScore'] as num?)?.toDouble() ?? 0,
                        _keteranganKeseimbangan(
                          (_treoTim['technicalRoleAffinityTeam'] as num?)?.toDouble() ?? 0,
                          (_treoTim['teamFunctionAffinity'] as num?)?.toDouble() ?? 0,
                        ),
                        tampilkanBar: false,
                        besar: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (bisaDaftar) ...[
              _sectionTitle('Pilih Peran Teknis'),
              const Padding(
                padding: EdgeInsets.only(top: 0, bottom: 8),
                child: Text('diurutkan dari yang paling direkomendasikan', style: TextStyle(color: _abu, fontSize: 11.5)),
              ),
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: (List.of(roles)..sort((r1, r2) {
                    num skor(dynamic r) {
                      for (final a in affinityPerRole) {
                        if (a['roleId'] == r['id']) return (a['skorPersen'] as num?) ?? 0;
                      }
                      return 0;
                    }
                    return skor(r2).compareTo(skor(r1));
                  })).map<Widget>((r) {
                    dynamic aff;
                    for (final a in affinityPerRole) {
                      if (a['roleId'] == r['id']) {
                        aff = a;
                        break;
                      }
                    }
                    final cocok = aff != null && (aff['skorPersen'] as num) >= 60;
                    return InkWell(
                      onTap: () => setState(() => _selectedRoleId = r['id']),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Radio<String>(
                                  value: r['id'],
                                  groupValue: _selectedRoleId,
                                  onChanged: (v) => setState(() => _selectedRoleId = v),
                                ),
                                Expanded(
                                  child: Text(r['namaRole'] ?? '-',
                                      style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 14)),
                                ),
                              ],
                            ),
                            if (aff != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 40, right: 4, bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: ((aff['skorPersen'] as num) / 100).clamp(0, 1).toDouble(),
                                          backgroundColor: const Color(0xFFE7ECF5),
                                          color: _biru,
                                          minHeight: 6,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${(aff['skorPersen'] as num).round()}%',
                                          style: const TextStyle(color: _navy, fontSize: 12, fontWeight: FontWeight.w700)),
                                    ]),
                                    if (cocok) ...[
                                      const SizedBox(height: 6),
                                      _badgeChip('✨ Sesuai profilmu', _hijau, const Color(0xFFDCFCE7)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              const Card(
                margin: EdgeInsets.symmetric(vertical: 6),
                color: Color(0xFFEFF3FB),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(children: [
                    Icon(Icons.info_outline, color: _biru, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fungsi kerja tim (TREO) dikalkulasi otomatis berdasarkan profil semua anggota setelah kamu bergabung.',
                        style: TextStyle(color: _navy, fontSize: 12),
                      ),
                    ),
                  ]),
                ),
              ),
            ],

            if (statusSaya == 'PENDING') ...[
              const SizedBox(height: 8),
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                color: const Color(0xFFFEF3C7),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(children: [
                    Text('Menunggu keputusan pembuat tim untuk peran: ${l['roleSaya'] ?? '-'}',
                        style: const TextStyle(color: _navy, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : () => _batalkan(l['pendaftaranIdSaya']),
                      child: const Text('Batalkan Pendaftaran'),
                    ),
                  ]),
                ),
              ),
            ],

          ],
          ),
        ),
      ),
      bottomNavigationBar: bisaDaftar
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (_busy || _selectedRoleId == null) ? null : () => _gabung(_selectedRoleId!),
                        child: _busy
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Ajukan Bergabung'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Pembuat tim akan menerima atau menolak pengajuanmu', style: TextStyle(color: _abu, fontSize: 11)),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  void _bukaDiskusi() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (ctx, setModalState) => SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.75,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Text('Diskusi Lobi', style: TextStyle(color: _navy, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _diskusi.isEmpty
                        ? const Center(child: Text('Belum ada pesan', style: TextStyle(color: _abu, fontSize: 12)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _diskusi.length,
                            itemBuilder: (_, i) {
                              final p = _diskusi[i];
                              final milikSendiri = p['mahasiswaId']?.toString() == _myId;
                              return Align(
                                alignment: milikSendiri ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(ctx).size.width * 0.72),
                                  decoration: BoxDecoration(
                                    color: milikSendiri ? _biru : const Color(0xFFEFF3FB),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (!milikSendiri)
                                        Text(p['nama'] ?? '-',
                                            style: const TextStyle(color: _biru, fontSize: 11, fontWeight: FontWeight.w700)),
                                      Text(p['pesan'] ?? '',
                                          style: TextStyle(color: milikSendiri ? Colors.white : _navy, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _pesanCtrl,
                            enabled: !_kirimBusy,
                            decoration: _kotakInput('Tulis pesan...', isDense: true),
                            onSubmitted: _kirimBusy
                                ? null
                                : (_) async {
                                    setModalState(() => _kirimBusy = true);
                                    await _kirimPesan();
                                    setModalState(() => _kirimBusy = false);
                                  },
                          ),
                        ),
                        IconButton(
                          icon: _kirimBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _biru),
                                )
                              : const Icon(Icons.send, color: _biru),
                          onPressed: _kirimBusy
                              ? null
                              : () async {
                                  setModalState(() => _kirimBusy = true);
                                  await _kirimPesan();
                                  setModalState(() => _kirimBusy = false);
                                },
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _tampilkanKontakTim(List anggota) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kontak Anggota Tim'),
        content: SizedBox(
          width: 360,
          child: ListView(
            shrinkWrap: true,
            children: anggota.map<Widget>((a) {
              final nama = (a['nama'] ?? '-') as String;
              final kontak = a['kontak'] as String?;
              final kontakJenis = a['kontakJenis'] as String?;
              final mahasiswaId = a['mahasiswaId'] as String?;
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: mahasiswaId == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeamMemberProfilePage(
                              lobiId: widget.lobiId,
                              mahasiswaId: mahasiswaId,
                            ),
                          ),
                        );
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nama,
                                style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(
                              kontak != null && kontak.isNotEmpty
                                  ? '${kontakJenis ?? 'Kontak'}: $kontak'
                                  : 'Belum mengisi kontak',
                              style: const TextStyle(color: _abu, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (mahasiswaId != null)
                        const Icon(Icons.chevron_right, color: _abu, size: 20),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  Widget _buildMemberView(
    BuildContext context,
    dynamic l,
    bool milikSaya,
    List roles,
    List anggota,
    int totalKuota,
    int terisi,
    List<String> rolesTerbuka,
    List<String> dimensiTerbuka, {
    int roleTerisiCount = 0,
    int totalRole = 0,
    List<String> roleDibutuhkan = const [],
  }) {
    final status = l['status'];
    final kategori = ((l['lomba']?['kategoriLomba'] as List?) ?? []).join(', ');
    final subjudul = [l['lomba']?['judul'] ?? '', kategori].where((s) => s.toString().isNotEmpty).join(' — ');
    final sudahSetuju = l['setujuFinalisasiSaya'] == true;
    final jumlahSetujuFinalisasi = (l['jumlahSetujuFinalisasi'] as int?) ?? 0;
    final totalAnggotaAccepted = (l['totalAnggotaAccepted'] as int?) ?? 0;
    final minAnggotaTim = l['lomba']?['minAnggotaTim'] as int?;
    final kurangAnggota = minAnggotaTim != null && totalAnggotaAccepted < minAnggotaTim;
    final sisaMenungguFinalisasi = totalAnggotaAccepted - jumlahSetujuFinalisasi;
    final labelStatusLobi = status == 'FINAL'
        ? 'Sudah difinalisasi'
        : (status == 'FINALIZING' ? 'Menunggu finalisasi' : (status == 'CLOSED' ? 'Ditutup' : 'Terbuka'));
    final fgStatusLobi = status == 'FINAL'
        ? _hijau
        : (status == 'FINALIZING' ? Colors.orange.shade800 : (status == 'CLOSED' ? _abu : _biru));
    final bgStatusLobi = status == 'FINAL'
        ? const Color(0xFFDCFCE7)
        : (status == 'FINALIZING' ? const Color(0xFFFFEDD5) : (status == 'CLOSED' ? const Color(0xFFF1F5F9) : const Color(0xFFEFF3FB)));

    const dimensiUrut = _dimensiUrut;
    final assignment = _treoTim?['assignment'] as Map?;
    final dominanPerDimensi = <String, String>{};
    if (assignment != null) {
      for (final d in dimensiUrut) {
        final slot = assignment[d] as Map?;
        final mid = slot?['mahasiswaId']?.toString();
        if (mid != null && mid.isNotEmpty) {
          dominanPerDimensi[d] = mid == _myId ? 'Kamu' : (slot?['nama'] ?? '-');
        }
      }
    }
    final dimensiPerAnggotaMember = _dimensiPerAnggota(assignment);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail tim'),
        actions: [
          if (milikSaya && status != 'FINAL')
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              iconSize: 26,
              tooltip: 'Kelola Pengajuan',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              padding: const EdgeInsets.all(12),
              onPressed: () async {
                final berubah = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => EditTimPage(lobiId: widget.lobiId)),
                );
                if (berubah == true) _muat();
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _muat,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: const Color(0xFFEFF3FB), borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.laptop_mac, color: _biru, size: 22),
                    ),
                    const SizedBox(height: 10),
                    if (subjudul.isNotEmpty)
                      Text(subjudul, style: const TextStyle(color: _abu, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(l['judul'] ?? '', style: const TextStyle(color: _navy, fontSize: 19, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        _badgeChip(labelStatusLobi, fgStatusLobi, bgStatusLobi),
                        if (milikSaya) _badgeChip('Kamu pembuat tim', _biru, const Color(0xFFEFF3FB)),
                        Text('$terisi/$totalKuota anggota', style: const TextStyle(color: _abu, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if ((l['deskripsi'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(l['deskripsi'], style: const TextStyle(color: _abu, fontSize: 13)),
            ],

            _sectionTitle('ANGGOTA TIM'),
            Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Column(
                children: anggota.map<Widget>((a) {
                  final isKamu = a['mahasiswaId']?.toString() == _myId;
                  final isKoordinator = a['nama'] == l['namaKoordinator'];
                  final dimensiSaya = dimensiPerAnggotaMember[a['mahasiswaId']?.toString()] ?? const <String>[];
                  final subtitle = [a['role'] ?? '-', if (isKoordinator) 'Pembuat tim'].join(' · ');
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isKoordinator ? const Color(0xFFFFEDD5) : const Color(0xFFF3E8FF),
                        child: Text(_inisial(a['nama'] ?? '?'),
                            style: TextStyle(
                                color: isKoordinator ? Colors.orange.shade800 : Colors.purple.shade700,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isKamu ? 'Kamu' : (a['nama'] ?? '-'),
                                style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(subtitle, style: const TextStyle(color: _abu, fontSize: 12)),
                          ],
                        ),
                      ),
                      ...dimensiSaya.where((d) => d == 'organizer').map((d) => Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: _badgeChip(_treoDimLabel[d] ?? d, Colors.orange.shade800, const Color(0xFFFFEDD5)),
                          )),
                    ]),
                  );
                }).toList(),
              ),
            ),

            if (rolesTerbuka.isNotEmpty) ...[
              _sectionTitle('PERAN YANG DIBUKA'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rolesTerbuka
                    .map((r) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Text(r, style: const TextStyle(color: _navy, fontSize: 12, fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
              ),
            ],

            Row(children: [
              _sectionTitle('FUNGSI KERJA TIM'),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _jelaskanFungsiKerjaTim(context),
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.help_outline, size: 16, color: _abu),
                ),
              ),
            ]),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.6,
              children: dimensiUrut.map((d) {
                final nama = dominanPerDimensi[d];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: nama != null ? _hijau : const Color(0xFFCBD5E1),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(_treoDimLabel[d] ?? d,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(nama ?? 'Belum ada',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _abu, fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Direpresentasikan oleh ${_treoTim?['m'] ?? dominanPerDimensi.length} anggota',
                style: TextStyle(color: _navy.withOpacity(0.35), fontSize: 11),
              ),
            ),

            if (_treoTim != null) ...[
              Row(children: [
                _sectionTitle('ANALITIK TIM'),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _jelaskanAnalitikTim(context),
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.help_outline, size: 16, color: _abu),
                  ),
                ),
              ]),
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _metrikTim(
                        'Nilai Kecocokan Fungsi Teknis Tim',
                        (_treoTim['technicalRoleAffinityTeam'] as num?)?.toDouble() ?? 0,
                        _keteranganKecocokanTeknis(
                          roleTerisiCount,
                          totalRole,
                          roleDibutuhkan,
                          (_treoTim['technicalRoleAffinityTeam'] as num?)?.toDouble() ?? 0,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _metrikTim(
                        'Nilai Kecocokan Fungsi Kerja Tim',
                        (_treoTim['teamFunctionAffinity'] as num?)?.toDouble() ?? 0,
                        _keteranganFungsiKerja(
                          terisi,
                          totalKuota,
                          dimensiTerbuka,
                          (_treoTim['teamFunctionAffinity'] as num?)?.toDouble() ?? 0,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _metrikTim(
                        'Skor Keseimbangan Tim',
                        (_treoTim['effectivenessScore'] as num?)?.toDouble() ?? 0,
                        _keteranganKeseimbangan(
                          (_treoTim['technicalRoleAffinityTeam'] as num?)?.toDouble() ?? 0,
                          (_treoTim['teamFunctionAffinity'] as num?)?.toDouble() ?? 0,
                        ),
                        tampilkanBar: false,
                        besar: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _bukaDiskusi,
                child: const Text('💬 Diskusi lobi'),
              ),
            ),
            if (status == 'OPEN' && milikSaya) ...[
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: (_busy || kurangAnggota) ? null : _inisiasiFinalisasi,
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(kurangAnggota ? 'Minimal $minAnggotaTim anggota' : 'Inisiasi finalisasi'),
                ),
              ),
            ],
            if (status == 'OPEN' && !milikSaya) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _keluarTim(l['pendaftaranIdSaya']),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, side: BorderSide(color: Colors.red.shade300)),
                  child: const Text('Keluar dari tim'),
                ),
              ),
            ],
            if (status == 'FINALIZING' && milikSaya) ...[
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: null,
                  child: Text(sisaMenungguFinalisasi > 0 ? 'Menunggu $sisaMenungguFinalisasi anggota' : 'Menunggu anggota'),
                ),
              ),
            ],
            if (status == 'FINALIZING' && !milikSaya) ...[
              if (!sudahSetuju) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _tolakFinalisasi,
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, side: BorderSide(color: Colors.red.shade300)),
                    child: const Text('Tolak'),
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: (_busy || sudahSetuju) ? null : _setujuFinalisasi,
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(sudahSetuju
                          ? 'Menunggu ${totalAnggotaAccepted - jumlahSetujuFinalisasi} anggota lain'
                          : 'Setujui finalisasi'),
                ),
              ),
            ],
            if (status == 'FINAL') ...[
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _tampilkanKontakTim(anggota),
                  style: FilledButton.styleFrom(
                    backgroundColor: _hijau,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Sudah final'),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------------------------------------
// Kelola lobi (pembuat tim) — daftar pendaftar per role, terima/tolak
// ------------------------------------------------------------------------------------------------

class KelolaLobiPage extends StatefulWidget {
  final String lobiId;
  const KelolaLobiPage({super.key, required this.lobiId});
  @override
  State<KelolaLobiPage> createState() => _KelolaLobiPageState();
}

class _KelolaLobiPageState extends State<KelolaLobiPage> {
  List _pendaftar = [];
  bool _loading = true;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() => _loading = true);
    final res = await apiGet('/team-formation/lobi/${widget.lobiId}/pendaftar');
    if (res is List) _pendaftar = res;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _putuskan(String pendaftaranId, String keputusan) async {
    setState(() => _busyIds.add(pendaftaranId));
    final res = await apiPatch('/team-formation/pendaftaran/$pendaftaranId', {'keputusan': keputusan});
    setState(() => _busyIds.remove(pendaftaranId));
    if (res is Map && res['error'] != null) {
      if (mounted) _snack(context, '${res['error']}', error: true);
      return;
    }
    _muat();
  }

  Widget _kartuPendaftar(Map p) {
    final busy = _busyIds.contains(p['pendaftaranId']);
    final status = p['status'] as String;
    final mhs = (p['mahasiswa'] as Map?) ?? {};
    final nama = mhs['nama'] ?? '-';
    final asal = [mhs['jurusan'], mhs['institusi']].where((x) => x != null && x != '').join(' · ');
    final treoLabel = p['treoDominan'] != null ? _treoDimLabel[p['treoDominan']] : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEFF3FB),
                child: Text(_inisial(nama), style: const TextStyle(color: _biru, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama, style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 14)),
                    if (asal.isNotEmpty) Text(asal, style: const TextStyle(color: _abu, fontSize: 12)),
                  ],
                ),
              ),
              if (status != 'PENDING') _badgeChip(_statusLabel(status), _statusFg(status), _statusBg(status)),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _badgeChip(p['role'] ?? '-', _biru, const Color(0xFFEFF3FB)),
              if (treoLabel != null) _badgeChip(treoLabel, _hijau, const Color(0xFFDCFCE7)),
            ]),
            const SizedBox(height: 8),
            Text('Mengisi peran teknis: ${p['role'] ?? '-'}', style: const TextStyle(color: _abu, fontSize: 12)),
            if (treoLabel != null)
              Text('Fungsi kerja tinggi di: $treoLabel', style: const TextStyle(color: _abu, fontSize: 12)),
            if (p['skorPersen'] != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: ((p['skorPersen'] as num) / 100).clamp(0, 1).toDouble(),
                    backgroundColor: const Color(0xFFE7ECF5),
                    color: _biru,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(p['skorPersen'] as num).round()}%', style: const TextStyle(color: _navy, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ],
            if (status == 'PENDING') ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => _putuskan(p['pendaftaranId'], 'REJECTED'),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : () => _putuskan(p['pendaftaranId'], 'ACCEPTED'),
                    child: busy
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Terima ke tim'),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menunggu = _pendaftar.where((p) => p['status'] == 'PENDING').toList();
    final diputuskan = _pendaftar.where((p) => p['status'] != 'PENDING').toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Pendaftar')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _muat,
              child: _pendaftar.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        _EmptyState(
                          icon: Icons.people_outline,
                          judul: 'Belum ada pendaftar',
                          subjudul: 'Pendaftar akan muncul di sini setelah ada mahasiswa yang melamar.',
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (menunggu.isNotEmpty) ...[
                          Row(children: [
                            const Text('MENUNGGU KEPUTUSAN',
                                style: TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.4)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(10)),
                              child: Text('${menunggu.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          ...menunggu.map((p) => _kartuPendaftar(p as Map)),
                          const SizedBox(height: 8),
                        ],
                        if (diputuskan.isNotEmpty) ...[
                          const Text('SUDAH DIPUTUSKAN',
                              style: TextStyle(color: _abu, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.4)),
                          const SizedBox(height: 12),
                          ...diputuskan.map((p) => _kartuPendaftar(p as Map)),
                        ],
                      ],
                    ),
            ),
    );
  }
}

// ------------------------------------------------------------------------------------------------
// Kuesioner TREO — 18 item Likert 1..5, 6 dimensi x 3 item
// ------------------------------------------------------------------------------------------------

class TreoQuestionnairePage extends StatefulWidget {
  // Kalau diisi, tampilkan tombol "Lewati" di AppBar (dipakai alur onboarding
  // setelah daftar akun — mengisi TREO jadi opsional, bisa dilanjutkan nanti).
  final VoidCallback? onLewati;
  const TreoQuestionnairePage({super.key, this.onLewati});
  @override
  State<TreoQuestionnairePage> createState() => _TreoQuestionnairePageState();
}

class _TreoQuestionnairePageState extends State<TreoQuestionnairePage> {
  bool _loading = true;
  bool _saving = false;
  final Map<String, List<int?>> _jawaban = {
    for (final d in _treoDimLabel.keys) d: List<int?>.filled(3, null),
  };

  static const Map<String, List<String>> _pertanyaan = {
    'organizer': [
      'Saya suka menjadi orang yang merapikan atau mengatur detail-detail dalam sebuah proyek tim.',
      'Saya suka menjadi orang yang menentukan siapa yang akan mengerjakan tugas tertentu dalam tim.',
      'Saya suka menjadi orang yang memantau seberapa baik kinerja tim saya.',
    ],
    'doer': [
      'Saya suka ketika tim tetap sibuk dan menyelesaikan pekerjaan.',
      'Saya dapat diandalkan ketika ada tugas yang perlu diselesaikan.',
      'Saya sering menjadi orang pertama yang menawarkan diri untuk mengerjakan tugas yang sulit atau kurang disukai jika hal itu dibutuhkan oleh tim.',
    ],
    'challenger': [
      'Saya merasa nyaman memberikan kritik kepada rekan satu tim saya.',
      'Saya suka menantang asumsi orang lain.',
      'Saya tidak takut untuk mempertanyakan otoritas rekan satu tim saya.',
    ],
    'innovator': [
      'Saya suka mencoba ide dan pendekatan baru.',
      'Saya merasa bosan ketika kami mengerjakan tugas yang sama dengan cara yang sama setiap saat.',
      'Saya suka memikirkan cara-cara baru agar tim kami dapat menyelesaikan tugas.',
    ],
    'teamBuilder': [
      'Saya selalu siap mendukung usulan yang baik demi kepentingan bersama tim.',
      'Saya merasa nyaman menghadapi konflik antarindividu dan membantu orang-orang menyelesaikannya.',
      'Saya suka membantu berbagai macam orang agar dapat bekerja sama secara efektif.',
    ],
    'connector': [
      'Saya senang mengoordinasikan upaya tim dengan orang atau kelompok di luar tim.',
      'Saya dapat diandalkan untuk menyampaikan ide antara tim saya dan orang-orang di luar tim.',
      'Saya merasa nyaman menjadi juru bicara bagi tim.',
    ],
  };

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final res = await apiGet('/team-formation/treo');
    if (res is Map && res['diisi'] == true && res['jawaban'] is Map) {
      final j = res['jawaban'] as Map;
      for (final d in _treoDimLabel.keys) {
        if (j[d] is List && (j[d] as List).length == _pertanyaan[d]!.length) {
          _jawaban[d] = List<int>.from((j[d] as List).map((e) => (e as num).toInt()));
        }
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _simpan() async {
    final belumLengkap = _jawaban.values.any((list) => list.any((v) => v == null));
    if (belumLengkap) {
      _snack(context, 'Harap isi semua pernyataan sebelum menyimpan.', error: true);
      return;
    }
    setState(() => _saving = true);
    final res = await apiPost('/team-formation/treo', {'jawaban': _jawaban});
    setState(() => _saving = false);
    if (res is Map && res['error'] != null) {
      if (mounted) _snack(context, '${res['error']}', error: true);
      return;
    }
    if (mounted) {
      _snack(context, 'Kuesioner TREO tersimpan');
      // pop(true) supaya alur onboarding (auth.dart) bisa membedakan ini dari
      // pop akibat tombol back (yang tidak bawa nilai / null).
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    // Saat dipakai di alur onboarding (onLewati != null), tombol/gestur back
    // sengaja dimatikan — tidak ada "kembali" yang masuk akal di titik ini
    // (akun sudah dibuat & login), satu-satunya jalan maju adalah Simpan/Lewati.
    final saatOnboarding = widget.onLewati != null;
    return PopScope(
      canPop: !saatOnboarding,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Kuesioner TREO'),
        automaticallyImplyLeading: !saatOnboarding,
        actions: widget.onLewati == null
            ? null
            : [
                TextButton(
                  onPressed: widget.onLewati,
                  child: const Text('Lewati', style: TextStyle(color: _abu, fontWeight: FontWeight.bold)),
                ),
              ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          const Text(
            'Isi tingkat kesesuaian setiap pernyataan dengan diri Anda (1 = Sangat Tidak Setuju, 5 = Sangat Setuju).',
            style: TextStyle(color: _abu, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ..._treoDimLabel.entries.map((dim) {
            final items = _pertanyaan[dim.key]!;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dim.value, style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 8),
                    ...List.generate(items.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(items[i], style: const TextStyle(color: _navy, fontSize: 13)),
                            Row(
                              children: List.generate(5, (v) {
                                final nilai = v + 1;
                                final terpilih = _jawaban[dim.key]![i] == nilai;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _jawaban[dim.key]![i] = nilai),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: terpilih ? _biru : const Color(0xFFEFF3FB),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$nilai',
                                        style: TextStyle(
                                          color: terpilih ? Colors.white : _navy,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _simpan,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan Jawaban'),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

// Profil detail anggota tim (dipanggil dari kontak tim yang sudah final) — mengikuti pola
// PartnerDetailPage pada modul people to people, tanpa bagian kecocokan/affinity.
class TeamMemberProfilePage extends StatefulWidget {
  final String lobiId;
  final String mahasiswaId;
  const TeamMemberProfilePage({super.key, required this.lobiId, required this.mahasiswaId});
  @override
  State<TeamMemberProfilePage> createState() => _TeamMemberProfilePageState();
}

class _TeamMemberProfilePageState extends State<TeamMemberProfilePage> {
  Map<String, dynamic>? _p;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final res = await apiGet('/team-formation/lobi/${widget.lobiId}/anggota/${widget.mahasiswaId}/profil');
    setState(() {
      _p = res is Map ? Map<String, dynamic>.from(res) : null;
      _loading = false;
    });
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

  Widget _baris(String label, String nilai, {String? bantuanKey}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Expanded(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: const TextStyle(color: _abu)),
              if (bantuanKey != null) dsBantuanIkon(context, bantuanKey, size: 14),
            ]),
          ),
          Text(nilai, style: const TextStyle(color: _navy, fontWeight: FontWeight.w600)),
        ]),
      );

  static const Map<String, String> _treoDimLabelAnggota = {
    'organizer': 'Organizer',
    'doer': 'Doer',
    'challenger': 'Challenger',
    'innovator': 'Innovator',
    'teamBuilder': 'Team Builder',
    'connector': 'Connector',
  };

  Color _warnaSkorAnggota(int persen) {
    if (persen < 40) return Colors.red.shade600;
    if (persen < 80) return const Color(0xFFF59E0B);
    return const Color(0xFF16A34A);
  }

  Widget _metrikTreoAnggota(String label, double nilai) {
    final persen = (nilai * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label, style: const TextStyle(color: _navy, fontSize: 13, fontWeight: FontWeight.w600))),
            Text('$persen%', style: const TextStyle(color: _navy, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: nilai.clamp(0, 1).toDouble(),
              backgroundColor: const Color(0xFFE7ECF5),
              color: _warnaSkorAnggota(persen),
              minHeight: 6,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kotakKontak(String? kontak, String? kontakJenis) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Icon(Icons.check_circle, color: _hijau),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((kontakJenis ?? 'KONTAK').toUpperCase(),
                  style: const TextStyle(color: _hijau, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(kontak?.isNotEmpty == true ? kontak! : '(belum diisi)',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: _navy)),
            ]),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final p = _p;
    if (p == null || p['error'] != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil anggota')),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil anggota', style: TextStyle(fontWeight: FontWeight.bold, color: _navy)),
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(radius: 32, backgroundColor: _biru, child: Text(_inisial(nama), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _navy)),
                  if (institusi.isNotEmpty) Text(institusi, style: const TextStyle(color: _abu)),
                  if (jurusanAngkatan.isNotEmpty)
                    Text(jurusanAngkatan, style: const TextStyle(color: _abu, fontSize: 12)),
                ]),
              ),
            ]),
          ),
        ),
        if (bio.isNotEmpty) ...[
          const SizedBox(height: 18),
          Row(children: [_sectionTitle('BIO'), const SizedBox(width: 4), dsBantuanIkon(context, 'bio')]),
          const SizedBox(height: 10),
          Text(bio, style: const TextStyle(color: _navy, height: 1.4)),
        ],
        Row(children: [_sectionTitle('MINAT'), const SizedBox(width: 4), dsBantuanIkon(context, 'minat')]),
        const SizedBox(height: 10),
        _chipList(((p['minatTag'] as List?) ?? []).cast<String>()),
        const SizedBox(height: 18),
        Row(children: [_sectionTitle('SKILL'), const SizedBox(width: 4), dsBantuanIkon(context, 'skill')]),
        const SizedBox(height: 10),
        _chipList(((p['skill'] as List?) ?? []).cast<String>()),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: [
            _baris('Pengalaman', _teksPengalaman(p['pengalaman']), bantuanKey: 'pengalaman'),
            const Divider(height: 1),
            _baris('Gaya kerja', p['gayaKerja']?.toString() ?? '-', bantuanKey: 'gayaKerja'),
            const Divider(height: 1),
            _baris('Preferensi peran', p['preferensiPeran']?.toString() ?? '-', bantuanKey: 'preferensiPeran'),
          ]),
        ),
        const SizedBox(height: 18),
        Row(children: [_sectionTitle('KETERSEDIAAN WAKTU'), const SizedBox(width: 4), dsBantuanIkon(context, 'ketersediaanWaktu')]),
        const SizedBox(height: 10),
        DsExpandableChips(items: ((p['ketersediaanWaktu'] as List?) ?? []).cast<String>()),
        const SizedBox(height: 18),
        _sectionTitle('TREO ROLE TEAM'),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((p['treo']?['diisi']) != true) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Belum mengisi kuesioner TREO', style: TextStyle(color: _abu)),
                  ),
                ] else
                  ..._treoDimLabelAnggota.entries.map((e) {
                    final nilai = (p['treo']?['norm']?[e.key] as num?)?.toDouble() ?? 0.0;
                    return _metrikTreoAnggota(e.value, nilai);
                  }),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _kotakKontak(p['kontak']?.toString(), p['kontakJenis']?.toString()),
        const SizedBox(height: 8),
      ]),
    );
  }
}
