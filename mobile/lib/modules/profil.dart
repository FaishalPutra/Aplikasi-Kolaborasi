import 'package:flutter/material.dart';
import '../api.dart';
import '../main.dart' show keluarDariApp;

// Tab Profil (General Features UC04) + edit profil kolaboratif.
// Desain mengikuti mockup Figma.

const _biru = Color(0xFF2563EB);
const _navy = Color(0xFF0F172A);
const _abu = Color(0xFF64748B);

const _skillOpsi = [
  'Python', 'JavaScript', 'Figma', 'Flutter', 'Public Speaking', 'Manajemen Proyek',
  'Penulisan', 'Analisis Data', 'UI Design', 'Riset Pengguna', 'SQL', 'Copywriting',
];
const _minatOpsi = [
  'AI', 'Riset', 'Pengembangan Web', 'Pengembangan Mobile', 'Desain', 'Data Science',
  'Kewirausahaan', 'UI/UX',
];
const _gayaKerjaOpsi = ['Terstruktur', 'Fleksibel'];
const _pengalamanOpsi = ['Pemula', 'Menengah', 'Mahir'];
const _peranOpsi = ['Leader/Coordinator', 'Contributor/Executor', 'Supporter/Facilitator'];
const _waktuOpsi = [
  'Senin malam', 'Selasa sore', 'Rabu sore', 'Kamis malam', 'Jumat sore', 'Sabtu pagi', 'Minggu malam',
];
const _kontakOpsi = ['WHATSAPP', 'LINE', 'LINKEDIN'];

String _teksPengalaman(dynamic v) => v == 1 ? 'Pemula' : (v == 2 ? 'Menengah' : (v == 3 ? 'Mahir' : '-'));

String _inisial(String nama) {
  final parts = nama.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts[0].substring(0, 1).toUpperCase();
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
    Text(t, style: const TextStyle(color: _biru, fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 13));

void _snack(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

// ================= HALAMAN PROFIL (BACA) =================
class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});
  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  Map<String, dynamic>? _me;
  bool _loading = true;

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
      final res = await apiGet('/auth/me');
      setState(() => _me = res is Map ? Map<String, dynamic>.from(res) : null);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ubahVisibilitas(bool nilai) async {
    setState(() => _me = {...?_me, 'profil': {...?_me?['profil'], 'visibilitas': nilai}});
    try {
      await apiPatch('/people-to-people/visibility', {'visible': nilai});
    } catch (_) {
      if (!mounted) return;
      _snack(context, 'Gagal menyimpan, coba lagi.');
      _muat();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final me = _me;
    if (me == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Gagal memuat profil.', style: TextStyle(color: _abu)),
              const SizedBox(height: 12),
              FilledButton(onPressed: _muat, child: const Text('Coba lagi')),
            ]),
          ),
        ),
      );
    }
    final nama = me['nama']?.toString() ?? 'Kamu';
    final profil = me['profil'] as Map?;
    final skill = (profil?['skill'] as List?)?.cast<String>() ?? [];
    final minat = (profil?['minatTag'] as List?)?.cast<String>() ?? [];
    final waktu = (profil?['ketersediaanWaktu'] as List?)?.cast<String>() ?? [];
    final visible = profil?['visibilitas'] != false;
    final kontak = me['kontak']?.toString() ?? '';
    final kontakJenis = me['kontakJenis']?.toString() ?? 'WHATSAPP';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _muat,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
            if (profil == null || profil['lengkap'] != true) ...[
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: Color(0xFFD97706)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Lengkapi profil kolaborasimu agar rekomendasi partner & proyek lebih akurat.',
                        style: TextStyle(color: Color(0xFF92400E), fontSize: 13)),
                  ),
                ]),
              ),
            ],
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: _biru, borderRadius: BorderRadius.circular(16)),
                    alignment: Alignment.center,
                    child: Text(_inisial(nama),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Kamu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _navy)),
                      Text('Profil kolaborasi kamu', style: TextStyle(color: _abu, fontSize: 13)),
                    ]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: _navy),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9)),
                    onPressed: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditProfilPage(me: me)));
                      _muat();
                    },
                  ),
                ]),
              ),
            ),
            Card(
              margin: const EdgeInsets.only(top: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Icon(visible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _biru),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Visibilitas profil', style: TextStyle(fontWeight: FontWeight.bold, color: _navy)),
                      Text('Kamu muncul di feed rekomendasi partner', style: TextStyle(color: _abu, fontSize: 12)),
                    ]),
                  ),
                  Switch(value: visible, activeColor: _biru, onChanged: _ubahVisibilitas),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('MINAT'),
            const SizedBox(height: 10),
            minat.isEmpty ? const Text('Belum diisi', style: TextStyle(color: _abu)) : _chipList(minat),
            const SizedBox(height: 18),
            _sectionTitle('SKILL'),
            const SizedBox(height: 10),
            skill.isEmpty ? const Text('Belum diisi', style: TextStyle(color: _abu)) : _chipList(skill),
            const SizedBox(height: 18),
            Card(
              margin: EdgeInsets.zero,
              child: Column(children: [
                _baris('Pengalaman', profil != null ? _teksPengalaman(profil['pengalaman']) : '-'),
                const Divider(height: 1),
                _baris('Gaya kerja', profil?['gayaKerja']?.toString().isNotEmpty == true ? profil!['gayaKerja'].toString() : '-'),
                const Divider(height: 1),
                _baris('Preferensi peran',
                    profil?['preferensiPeran']?.toString().isNotEmpty == true ? profil!['preferensiPeran'].toString() : '-'),
              ]),
            ),
            const SizedBox(height: 18),
            _sectionTitle('KETERSEDIAAN WAKTU'),
            const SizedBox(height: 10),
            waktu.isEmpty ? const Text('Belum diisi', style: TextStyle(color: _abu)) : _chipList(waktu),
            const SizedBox(height: 18),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.chat_bubble_outline, color: _navy),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('KONTAK UTAMA · $kontakJenis',
                          style: const TextStyle(color: _abu, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text(kontak.isNotEmpty ? kontak : '(belum diisi)',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: _navy, fontSize: 15)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Privat', style: TextStyle(color: _abu, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _konfirmasiKeluar(context),
                icon: const Icon(Icons.logout, size: 18, color: Color(0xFFDC2626)),
                label: const Text('Keluar', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text('Aplikasi Kolaborasi · versi purwarupa', style: TextStyle(color: Color(0xFFB0B8C4), fontSize: 12)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _baris(String kiri, String kanan) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(kiri, style: const TextStyle(color: _abu)),
          Text(kanan, style: const TextStyle(fontWeight: FontWeight.bold, color: _navy)),
        ]),
      );

  void _konfirmasiKeluar(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu perlu login lagi untuk mengakses aplikasi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              keluarDariApp(context);
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

// ================= EDIT PROFIL =================
class EditProfilPage extends StatefulWidget {
  final Map<String, dynamic> me;
  const EditProfilPage({super.key, required this.me});
  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  late final TextEditingController _nama;
  late final TextEditingController _kontak;
  String _kontakJenis = 'WHATSAPP';
  final Set<String> _skill = {};
  final Set<String> _minat = {};
  String _gayaKerja = 'Fleksibel';
  String _pengalaman = 'Menengah';
  String _peran = 'Contributor/Executor';
  final Set<String> _waktu = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final me = widget.me;
    final profil = me['profil'] as Map?;
    _nama = TextEditingController(text: me['nama']?.toString() ?? '');
    _kontak = TextEditingController(text: me['kontak']?.toString() ?? '');
    _kontakJenis = _kontakOpsi.contains(me['kontakJenis']) ? me['kontakJenis'].toString() : 'WHATSAPP';
    if (profil != null) {
      _skill.addAll((profil['skill'] as List?)?.cast<String>() ?? []);
      _minat.addAll((profil['minatTag'] as List?)?.cast<String>() ?? []);
      _waktu.addAll((profil['ketersediaanWaktu'] as List?)?.cast<String>() ?? []);
      if (_gayaKerjaOpsi.contains(profil['gayaKerja'])) _gayaKerja = profil['gayaKerja'].toString();
      if (_peranOpsi.contains(profil['preferensiPeran'])) _peran = profil['preferensiPeran'].toString();
      final p = profil['pengalaman'];
      if (p == 1) _pengalaman = 'Pemula';
      if (p == 2) _pengalaman = 'Menengah';
      if (p == 3) _pengalaman = 'Mahir';
    }
  }

  bool get _valid => _nama.text.trim().isNotEmpty;
  int get _pengalamanReq => _pengalamanOpsi.indexOf(_pengalaman) + 1;

  Future<void> _simpan() async {
    setState(() => _loading = true);
    try {
      final resAkun = await apiPut('/auth/akun', {
        'nama': _nama.text.trim(),
        'kontak': _kontak.text.trim(),
        'kontakJenis': _kontakJenis,
      });
      final resProfil = await apiPut('/auth/profil', {
        'skill': _skill.toList(),
        'pengalaman': _pengalamanReq,
        'minatTag': _minat.toList(),
        'gayaKerja': _gayaKerja,
        'preferensiPeran': _peran,
        'ketersediaanWaktu': _waktu.toList(),
      });
      if (!mounted) return;
      if (resAkun is Map && resAkun['error'] != null) {
        _snack(context, resAkun['error'].toString());
      } else if (resProfil is Map && resProfil['error'] != null) {
        _snack(context, resProfil['error'].toString());
      } else {
        _snack(context, 'Profil berhasil disimpan');
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) _snack(context, 'Gagal terhubung ke server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 8, top: 20), child: _sectionTitle(t));

  Widget _field(TextEditingController c, String hint) => TextField(
        controller: c,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _biru)),
        ),
      );

  Widget _pilihan(List<String> opsi, bool Function(String) aktif, void Function(String) onTap) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: opsi.map((o) {
          final a = aktif(o);
          return GestureDetector(
            onTap: () => setState(() => onTap(o)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: a ? const Color(0xFFEEF2FF) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: a ? _biru : const Color(0xFFE2E8F0)),
              ),
              child: Text(o, style: TextStyle(color: a ? _biru : _navy, fontWeight: a ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        }).toList(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profil', style: TextStyle(fontWeight: FontWeight.bold, color: _navy)),
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 10)]),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: (_valid && !_loading) ? _simpan : null,
            style: FilledButton.styleFrom(
                backgroundColor: _biru,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _loading
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
        _label('NAMA'),
        _field(_nama, 'Nama lengkap'),
        _label('KONTAK UTAMA'),
        _pilihan(_kontakOpsi, (o) => _kontakJenis == o, (o) => _kontakJenis = o),
        const SizedBox(height: 10),
        _field(_kontak, 'cth: 0812xxxxxxx atau username'),
        _label('MINAT'),
        _pilihan(_minatOpsi, (o) => _minat.contains(o), (o) => _minat.contains(o) ? _minat.remove(o) : _minat.add(o)),
        _label('SKILL'),
        _pilihan(_skillOpsi, (o) => _skill.contains(o), (o) => _skill.contains(o) ? _skill.remove(o) : _skill.add(o)),
        _label('PENGALAMAN'),
        _pilihan(_pengalamanOpsi, (o) => _pengalaman == o, (o) => _pengalaman = o),
        _label('GAYA KERJA'),
        _pilihan(_gayaKerjaOpsi, (o) => _gayaKerja == o, (o) => _gayaKerja = o),
        _label('PREFERENSI PERAN'),
        _pilihan(_peranOpsi, (o) => _peran == o, (o) => _peran = o),
        _label('KETERSEDIAAN WAKTU'),
        _pilihan(_waktuOpsi, (o) => _waktu.contains(o), (o) => _waktu.contains(o) ? _waktu.remove(o) : _waktu.add(o)),
      ]),
    );
  }
}
