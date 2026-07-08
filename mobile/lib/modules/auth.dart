import 'package:flutter/material.dart';
import '../api.dart';
import '../design_system.dart';
import '../main.dart' show masukKeApp;
import 'profil.dart' show EditProfilPage;
import 'team_formation.dart' show TreoQuestionnairePage;

// General Features: Welcome + Login + Register (UC01–UC02).
// Desain mengikuti design system bersama (lihat design_system.dart) — monokrom
// hitam/putih/abu dengan aksen pill hitam, gaya travel/marketplace app modern.

const _biru = DS.active;
const _navy = DS.primaryText;
const _abu = DS.secondaryText;
const _krem = Color(0xFFF3E9D2); // teks hero WelcomePage di atas foto

// Logo kotak "AK"
class _Logo extends StatelessWidget {
  final double size;
  const _Logo({this.size = 96});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _biru,
          borderRadius: BorderRadius.circular(size * 0.28),
          boxShadow: [BoxShadow(color: _biru.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        alignment: Alignment.center,
        child: Text('AK',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.34)),
      );
}

// Field berlabel (label di atas, kolom putih di bawah)
class LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboard;
  final ValueChanged<String>? onChanged;
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint = '',
    this.obscure = false,
    this.suffix,
    this.keyboard,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: _navy)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9AA5B8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: suffix,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: _biru, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// Tombol utama biru penuh-lebar
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const PrimaryButton({super.key, required this.label, this.onPressed, this.loading = false});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: _biru,
            disabledBackgroundColor: const Color(0xFFCBD5E1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          child: loading
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
}

// ============ 1. WELCOME ============
// Foto full-bleed + gradient gelap + teks overlay, gaya hero/onboarding modern
// (referensi: foto tangan bertumpuk — melambangkan kolaborasi tim).
class WelcomePage extends StatelessWidget {
  final VoidCallback onLoggedIn;
  const WelcomePage({super.key, required this.onLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/welcome.jpeg', fit: BoxFit.cover),
          // gelap dari tengah ke bawah — supaya teks & tombol tetap terbaca di atas foto
          Container(decoration: dsPhotoFade()),
          // sedikit gelap juga di atas — supaya logo & status bar tetap kontras
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Color(0x99000000), Colors.transparent],
                stops: [0.0, 0.6],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                children: [
                  const _Logo(size: 64),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    child: RichText(
                      textAlign: TextAlign.left,
                      text: TextSpan(
                        style: DS.fontCover.copyWith(height: 1.25),
                        children: [
                          TextSpan(
                              text: 'Temukan ',
                              style: TextStyle(color: _krem.withValues(alpha: 0.88), fontSize: 17)),
                          TextSpan(
                              text: 'rekan, proyek,\ndan tim\n',
                              style: TextStyle(color: _krem, fontSize: 30, fontWeight: FontWeight.w700)),
                          TextSpan(
                              text: 'yang benar-benar ',
                              style: TextStyle(color: _krem.withValues(alpha: 0.88), fontSize: 17)),
                          TextSpan(
                              text: 'cocok denganmu\n',
                              style: TextStyle(color: _krem, fontSize: 30, fontWeight: FontWeight.w700)),
                          TextSpan(
                              text: 'bukan cuma yang kebetulan kamu kenal.',
                              style: TextStyle(color: _krem.withValues(alpha: 0.88), fontSize: 17)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  DsCtaButton(
                    label: 'Daftar akun',
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => RegisterPage(onLoggedIn: onLoggedIn))),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => LoginPage(onLoggedIn: onLoggedIn))),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        side: const BorderSide(color: Colors.white70),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      child: const Text('Masuk',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ 2. LOGIN ============
class LoginPage extends StatefulWidget {
  final VoidCallback onLoggedIn;
  const LoginPage({super.key, required this.onLoggedIn});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _show = false;
  bool _loading = false;
  String? _pesan;

  bool get _valid => _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

  Future<void> _masuk() async {
    setState(() {
      _loading = true;
      _pesan = null;
    });
    try {
      final res = await apiPost('/auth/login', {'email': _email.text.trim(), 'password': _password.text});
      if (res is Map && res['token'] != null) {
        authToken = res['token'].toString();
        widget.onLoggedIn();
      } else {
        setState(() => _pesan = (res is Map ? res['error']?.toString() : null) ?? 'Login gagal');
      }
    } catch (_) {
      setState(() => _pesan = 'Gagal terhubung ke server. Pastikan backend jalan.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: _navy),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Logo(size: 64),
              const SizedBox(height: 20),
              const Text('Masuk', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: _navy)),
              const SizedBox(height: 6),
              const Text('Selamat datang kembali di Aplikasi Kolaborasi', style: TextStyle(color: _abu)),
              const SizedBox(height: 28),
              LabeledField(
                label: 'Email kampus',
                controller: _email,
                hint: 'nama@student.ac.id',
                keyboard: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              LabeledField(
                label: 'Kata sandi',
                controller: _password,
                hint: 'Kata sandi',
                obscure: !_show,
                onChanged: (_) => setState(() {}),
                suffix: TextButton(
                  onPressed: () => setState(() => _show = !_show),
                  child: Text(_show ? 'Sembunyikan' : 'Tampilkan',
                      style: const TextStyle(color: _biru, fontWeight: FontWeight.bold)),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () {}, child: const Text('Lupa sandi?', style: TextStyle(color: _abu))),
              ),
              const SizedBox(height: 8),
              if (_pesan != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_pesan!, style: const TextStyle(color: Colors.red)),
                ),
              PrimaryButton(label: 'Masuk', loading: _loading, onPressed: _valid ? _masuk : null),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => RegisterPage(onLoggedIn: widget.onLoggedIn))),
                  child: const Text.rich(TextSpan(
                    style: TextStyle(color: _abu),
                    children: [
                      TextSpan(text: 'Belum punya akun? '),
                      TextSpan(text: 'Daftar', style: TextStyle(color: _biru, fontWeight: FontWeight.bold)),
                    ],
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ 3. REGISTER ============
class RegisterPage extends StatefulWidget {
  final VoidCallback onLoggedIn;
  const RegisterPage({super.key, required this.onLoggedIn});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _show = false;
  bool _loading = false;
  String? _pesan;

  bool get _valid =>
      _nama.text.trim().isNotEmpty && _email.text.trim().isNotEmpty && _password.text.length >= 4;

  Future<void> _daftar() async {
    setState(() {
      _loading = true;
      _pesan = null;
    });
    try {
      final reg = await apiPost('/auth/register',
          {'nama': _nama.text.trim(), 'email': _email.text.trim(), 'password': _password.text});
      if (reg is Map && reg['error'] != null) {
        setState(() => _pesan = reg['error'].toString());
        return;
      }
      // Langsung login setelah daftar → onboarding (isi profil + TREO, bisa dilewati) →
      // masuk ke app dengan tur singkat fitur utama (cuma sekali, saat baru daftar)
      final login = await apiPost('/auth/login', {'email': _email.text.trim(), 'password': _password.text});
      if (login is Map && login['token'] != null) {
        authToken = login['token'].toString();
        if (mounted) await _onboarding(context);
        if (mounted) masukKeApp(context, showTour: true);
      } else {
        setState(() => _pesan = 'Akun dibuat, tapi login otomatis gagal. Silakan masuk manual.');
      }
    } catch (_) {
      setState(() => _pesan = 'Gagal terhubung ke server. Pastikan backend jalan.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Onboarding setelah akun baru dibuat: isi Profil Kolaboratif lalu Kuesioner TREO,
  // masing-masing bisa dilewati (tombol "Lewati" di AppBar) — datanya dipakai
  // AffinityEngine ketiga modul (People-to-People, People-to-Project, Team Formation).
  Future<void> _onboarding(BuildContext context) async {
    Map<String, dynamic> me = {};
    try {
      final res = await apiGet('/auth/me');
      if (res is Map) me = Map<String, dynamic>.from(res);
    } catch (_) {
      // lanjut dengan map kosong kalau gagal memuat — EditProfilPage tetap bisa dipakai
    }
    if (!context.mounted) return;
    // Hasil push dipakai buat membedakan "step selesai" (Simpan/Lewati, pop(true))
    // dari "user menekan tombol back" (pop tanpa nilai, default null) — supaya
    // tombol back tidak salah dikira "lanjut ke langkah berikutnya".
    final r1 = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (ctx) => EditProfilPage(me: me, onLewati: () => Navigator.of(ctx).pop(true)),
    ));
    if (!context.mounted || r1 != true) return;
    await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (ctx) => TreoQuestionnairePage(onLewati: () => Navigator.of(ctx).pop(true)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: _navy),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text('Buat akun', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: _navy)),
              const SizedBox(height: 6),
              const Text('Langkah pertama sebelum mengisi profil kolaborasimu', style: TextStyle(color: _abu)),
              const SizedBox(height: 28),
              LabeledField(
                  label: 'Nama lengkap',
                  controller: _nama,
                  hint: 'cth: Andini Kusuma',
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 18),
              LabeledField(
                  label: 'Email kampus',
                  controller: _email,
                  hint: 'nama@student.ac.id',
                  keyboard: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 18),
              LabeledField(
                label: 'Kata sandi',
                controller: _password,
                hint: 'Minimal 4 karakter',
                obscure: !_show,
                onChanged: (_) => setState(() {}),
                suffix: TextButton(
                  onPressed: () => setState(() => _show = !_show),
                  child: Text(_show ? 'Sembunyikan' : 'Tampilkan',
                      style: const TextStyle(color: _biru, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Dengan mendaftar, kamu menyetujui Ketentuan Layanan & Kebijakan Privasi Aplikasi Kolaborasi.',
                style: TextStyle(color: _abu, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 20),
              if (_pesan != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_pesan!, style: const TextStyle(color: Colors.red)),
                ),
              PrimaryButton(label: 'Daftar & isi profil', loading: _loading, onPressed: _valid ? _daftar : null),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => LoginPage(onLoggedIn: widget.onLoggedIn))),
                  child: const Text.rich(TextSpan(
                    style: TextStyle(color: _abu),
                    children: [
                      TextSpan(text: 'Sudah punya akun? '),
                      TextSpan(text: 'Masuk', style: TextStyle(color: _biru, fontWeight: FontWeight.bold)),
                    ],
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
