import 'package:flutter/material.dart';
import '../api.dart';

// Modul People-to-People (Ahmad). Tersambung ke backend /api/people-to-people.
// Desain mengikuti mockup Figma.

const _biru = Color(0xFF2563EB);
const _navy = Color(0xFF0F172A);
const _abu = Color(0xFF64748B);
const _hijau = Color(0xFF16A34A);

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
Color _labelBg(String b) => (b == 'Sangat Cocok') ? const Color(0xFFDCFCE7) : const Color(0xFFEEF2F7);
Color _labelFg(String b) => (b == 'Sangat Cocok') ? _hijau : _abu;

Widget _badge(String teks) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: _labelBg(teks), borderRadius: BorderRadius.circular(20)),
      child: Text(teks, style: TextStyle(color: _labelFg(teks), fontWeight: FontWeight.bold, fontSize: 12)),
    );

Widget _avatar(String nama, String key, {double size = 52}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: _avatarColor(key), borderRadius: BorderRadius.circular(size * 0.3)),
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
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: persen / 100,
            strokeWidth: 9,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation(warna),
          ),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${persen.round()}%',
              style: TextStyle(fontSize: size * 0.24, fontWeight: FontWeight.bold, color: _navy)),
          Text('COCOK', style: TextStyle(fontSize: size * 0.1, color: _abu, letterSpacing: 1)),
        ]),
      ]),
    );
  }
}

Widget _chipList(List<String> items) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
                child: Text(s, style: const TextStyle(color: _navy, fontSize: 13)),
              ))
          .toList(),
    );

Widget _sectionTitle(String t) =>
    Text(t, style: const TextStyle(color: _biru, fontWeight: FontWeight.bold, letterSpacing: 0.5));

void _snack(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

// ---------- HALAMAN UTAMA ----------
class PeopleToPeoplePage extends StatefulWidget {
  const PeopleToPeoplePage({super.key});
  @override
  State<PeopleToPeoplePage> createState() => _PeopleToPeoplePageState();
}

class _PeopleToPeoplePageState extends State<PeopleToPeoplePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            const SizedBox(height: 8),
            _toggleAtas(),
            const SizedBox(height: 16),
            Expanded(child: _tab == 0 ? const _RekomendasiTab() : const _KoneksiTab()),
          ]),
        ),
      ),
    );
  }

  Widget _toggleAtas() {
    Widget seg(String label, int i) {
      final aktif = _tab == i;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = i),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: aktif ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: aktif ? [const BoxShadow(color: Color(0x14000000), blurRadius: 8)] : null,
            ),
            alignment: Alignment.center,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: aktif ? _biru : _abu)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFEEF2F7), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [seg('Rekomendasi', 0), seg('Koneksi', 1)]),
    );
  }
}

// ---------- TAB REKOMENDASI ----------
class _RekomendasiTab extends StatefulWidget {
  const _RekomendasiTab();
  @override
  State<_RekomendasiTab> createState() => _RekomendasiTabState();
}

class _RekomendasiTabState extends State<_RekomendasiTab> {
  final _filter = const [
    {'label': 'Semua', 'key': 'semua'},
    {'label': 'Sangat Cocok', 'key': 'sangat'},
    {'label': 'Cocok+', 'key': 'cocok'},
    {'label': 'Waktu', 'key': 'waktu'},
  ];
  int _filterAktif = 0;
  int _index = 0;
  bool _loading = true;
  String? _pesan;
  List<dynamic> _feed = [];

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
      final key = _filter[_filterAktif]['key'];
      final res = await apiGet('/people-to-people/feed?filter=$key');
      final feed = (res is Map && res['feed'] is List) ? res['feed'] as List : [];
      setState(() {
        _feed = feed;
        _index = 0;
        if (feed.isEmpty) {
          _pesan = (res is Map ? res['error']?.toString() : null) ?? 'Belum ada rekomendasi.';
        }
      });
    } catch (_) {
      setState(() => _pesan = 'Gagal memuat. Pastikan backend jalan.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final habis = _index >= _feed.length;
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
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0))),
          child: IconButton(onPressed: _muat, icon: const Icon(Icons.refresh, color: _biru)),
        ),
      ]),
      const SizedBox(height: 14),
      SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filter.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final aktif = i == _filterAktif;
            return GestureDetector(
              onTap: () {
                setState(() => _filterAktif = i);
                _muat();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: aktif ? _biru : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: aktif ? _biru : const Color(0xFFE2E8F0)),
                ),
                child: Text(_filter[i]['label']!,
                    style: TextStyle(color: aktif ? Colors.white : _navy, fontWeight: FontWeight.w600)),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_feed.isEmpty || habis)
                ? _EmptyState(
                    icon: Icons.auto_awesome,
                    judul: _feed.isEmpty ? (_pesan ?? 'Belum ada rekomendasi') : 'Kamu sudah lihat semua',
                    subtitle: 'Cek koneksi & profil tersimpan, atau ubah filter untuk lihat lagi.',
                    tombol: 'Muat ulang',
                    onTombol: _muat,
                  )
                : SingleChildScrollView(
                    child: _KartuRekomendasi(
                      item: _feed[_index] as Map,
                      onSkip: () => setState(() => _index++),
                    ),
                  ),
      ),
    ]);
  }
}

class _KartuRekomendasi extends StatelessWidget {
  final Map item;
  final VoidCallback onSkip;
  const _KartuRekomendasi({required this.item, required this.onSkip});

  String get _id => item['mahasiswaId'].toString();

  Widget _kotakAksi(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 52,
          height: 48,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Icon(icon, color: _navy),
        ),
      );

  Future<void> _post(BuildContext c, String path, Map<String, dynamic> body, String sukses) async {
    try {
      final res = await apiPost(path, body);
      final pesan = res is Map && res['pesan'] != null ? res['pesan'].toString() : sukses;
      if (c.mounted) _snack(c, pesan);
    } catch (_) {
      if (c.mounted) _snack(c, 'Gagal terhubung ke server.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final nama = item['nama']?.toString() ?? '-';
    final alasan = (item['alasan'] as List?)?.cast<String>() ?? [];
    final dotWarna = [_hijau, _biru, _biru, const Color(0xFFD97706)];
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
                if ((item['institusi']?.toString() ?? '').isNotEmpty)
                  Text(item['institusi'].toString(), style: const TextStyle(color: _abu)),
                const SizedBox(height: 8),
                _badge(item['label']?.toString() ?? ''),
              ]),
            ),
          ]),
          const SizedBox(height: 18),
          _sectionTitle('KENAPA KALIAN COCOK'),
          const SizedBox(height: 10),
          ...alasan.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF6F8FB), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: dotWarna[e.key % dotWarna.length], shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.value, style: const TextStyle(color: _navy, height: 1.3))),
                ]),
              )),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => PartnerDetailPage(mahasiswaId: _id))),
              child: const Text('Lihat profil lengkap →', style: TextStyle(color: _biru, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            _kotakAksi(Icons.bookmark_border,
                () => _post(context, '/people-to-people/saved', {'targetId': _id}, 'Profil disimpan')),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    _post(context, '/people-to-people/interest', {'receiverId': _id}, 'Kamu menandai tertarik'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Tertarik', style: TextStyle(color: _navy, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: () =>
                    _post(context, '/people-to-people/connect', {'receiverId': _id}, 'Permintaan koneksi dikirim'),
                style: FilledButton.styleFrom(
                    backgroundColor: _biru,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Hubungkan', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
            _kotakAksi(Icons.arrow_forward, onSkip),
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

  Future<void> _post(String path, Map<String, dynamic> body, String sukses) async {
    try {
      final res = await apiPost(path, body);
      final pesan = res is Map && res['pesan'] != null ? res['pesan'].toString() : sukses;
      if (mounted) _snack(context, pesan);
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
              if ((p['institusi']?.toString() ?? '').isNotEmpty)
                Text(p['institusi'].toString(), style: const TextStyle(color: _abu)),
              const SizedBox(height: 8),
              Row(children: [
                Text('${(affinity?['persen'] as num?)?.round() ?? 0}% ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _navy, fontSize: 16)),
                _badge(affinity?['label']?.toString() ?? ''),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 20),
        if (breakdown != null) ...[
          Row(children: [
            _sectionTitle('RINCIAN KECOCOKAN'),
            const SizedBox(width: 8),
            const Text('AffinityEngine', style: TextStyle(color: Color(0xFFB0B8C4))),
          ]),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  children: _labelAtribut.keys.where((k) => breakdown.containsKey(k)).map((k) {
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
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: skor, minHeight: 6, backgroundColor: const Color(0xFFEEF2F7)),
                    ),
                  ]),
                );
              }).toList()),
            ),
          ),
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
            onTap: () => _post('/people-to-people/saved', {'targetId': widget.mahasiswaId}, 'Profil disimpan'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 52,
              height: 48,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: const Icon(Icons.bookmark_border, color: _navy),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  _post('/people-to-people/interest', {'receiverId': widget.mahasiswaId}, 'Kamu menandai tertarik'),
              icon: const Icon(Icons.favorite_border, size: 18, color: _navy),
              label: const Text('Tertarik', style: TextStyle(color: _navy, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: () =>
                  _post('/people-to-people/connect', {'receiverId': widget.mahasiswaId}, 'Permintaan koneksi dikirim'),
              style: FilledButton.styleFrom(
                  backgroundColor: _biru,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Hubungkan', style: TextStyle(fontWeight: FontWeight.bold)),
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
  const _KoneksiTab();
  @override
  State<_KoneksiTab> createState() => _KoneksiTabState();
}

class _KoneksiTabState extends State<_KoneksiTab> {
  int _sub = 1; // default Permintaan
  bool _loading = true;
  List<dynamic> _terhubung = [];
  List<dynamic> _permintaan = [];
  List<dynamic> _disimpan = [];

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
      setState(() {
        _terhubung = (c is Map && c['koneksi'] is List) ? c['koneksi'] as List : [];
        _permintaan = (r is Map && r['permintaan'] is List) ? r['permintaan'] as List : [];
        _disimpan = (s is Map && s['saved'] is List) ? s['saved'] as List : [];
      });
    } catch (_) {
      // biarkan kosong
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    Widget seg(String label, int i) {
      final aktif = _sub == i;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _sub = i),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: aktif ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: aktif ? [const BoxShadow(color: Color(0x14000000), blurRadius: 6)] : null,
            ),
            alignment: Alignment.center,
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: aktif ? _biru : _abu, fontSize: 12)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFEEF2F7), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        seg('Terhubung · ${_terhubung.length}', 0),
        seg('Permintaan · ${_permintaan.length}', 1),
        seg('Disimpan · ${_disimpan.length}', 2),
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
    if (_disimpan.isEmpty) {
      return _listKosong(Icons.bookmark_border, 'Belum ada yang disimpan',
          'Tekan ikon simpan pada kartu rekomendasi untuk menyimpan profil.');
    }
    return ListView(
        children: _disimpan
            .map((o) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.bookmark, color: _biru),
                    title: Text('Profil ${(o as Map)['targetId']}'),
                    subtitle: const Text('Tersimpan'),
                  ),
                ))
            .toList());
  }

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
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _respons(o['requestId'].toString(), 'REJECTED'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Terima koneksi', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _kartuTerhubung(Map o) {
    final nama = o['nama']?.toString() ?? '-';
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
                if ((o['institusi']?.toString() ?? '').isNotEmpty)
                  Text(o['institusi'].toString(), style: const TextStyle(color: _abu, fontSize: 13)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.link, size: 13, color: _hijau),
                SizedBox(width: 4),
                Text('Terhubung', style: TextStyle(color: _hijau, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
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
                  backgroundColor: _biru, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(tombol, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      );
}
