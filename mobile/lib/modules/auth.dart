import 'package:flutter/material.dart';
import '../api.dart';

// General Features: Welcome + Login + Register (UC01–UC02).
// Desain mengikuti mockup Figma (tema biru).

const _biru = Color(0xFF2563EB);
const _navy = Color(0xFF0F172A);
const _abu = Color(0xFF64748B);

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
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: loading
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
}

// ============ 1. WELCOME ============
class WelcomePage extends StatelessWidget {
  final VoidCallback onLoggedIn;
  const WelcomePage({super.key, required this.onLoggedIn});

  Widget _fitur(IconData icon, Color bg, String teks) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: _navy),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(teks, style: const TextStyle(fontWeight: FontWeight.w600, color: _navy, height: 1.3))),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const _Logo(),
              const SizedBox(height: 20),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(text: 'Aplikasi ', style: TextStyle(color: _navy)),
                    TextSpan(text: 'Kolaborasi', style: TextStyle(color: _biru)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Temukan rekan kolaborasi yang benar-benar cocok — bukan cuma yang kebetulan kamu kenal.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _abu, height: 1.5, fontSize: 15),
              ),
              const SizedBox(height: 28),
              _fitur(Icons.track_changes, const Color(0xFFDCFCE7), 'Dicocokkan lewat minat, skill & gaya kerja'),
              _fitur(Icons.search, const Color(0xFFE0E7FF), 'Tahu kenapa kalian cocok, transparan'),
              const Spacer(flex: 3),
              PrimaryButton(
                label: 'Daftar akun',
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => RegisterPage(onLoggedIn: onLoggedIn))),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => LoginPage(onLoggedIn: onLoggedIn))),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Masuk',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _biru)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
      // Langsung login setelah daftar → masuk ke app (lalu isi profil)
      final login = await apiPost('/auth/login', {'email': _email.text.trim(), 'password': _password.text});
      if (login is Map && login['token'] != null) {
        authToken = login['token'].toString();
        widget.onLoggedIn();
      } else {
        setState(() => _pesan = 'Akun dibuat, tapi login otomatis gagal. Silakan masuk manual.');
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
