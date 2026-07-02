import 'package:flutter/material.dart';
import '../api.dart';

// General Features: Login & Register (UC01–UC02).
class AuthPage extends StatefulWidget {
  final VoidCallback onLogin;
  const AuthPage({super.key, required this.onLogin});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nama = TextEditingController();
  bool _modeRegister = false;
  bool _loading = false;
  String? _pesan;

  Future<void> _submit() async {
    setState(() {
      _pesan = null;
      _loading = true;
    });
    try {
      if (_modeRegister) {
        final res = await apiPost('/auth/register', {
          'nama': _nama.text,
          'email': _email.text,
          'password': _password.text,
        });
        if (res is Map && res['error'] != null) {
          setState(() => _pesan = res['error'].toString());
          return;
        }
        setState(() {
          _modeRegister = false;
          _pesan = 'Registrasi berhasil, silakan login.';
        });
        return;
      }
      final res = await apiPost('/auth/login', {
        'email': _email.text,
        'password': _password.text,
      });
      if (res is Map && res['token'] != null) {
        authToken = res['token'].toString();
        widget.onLogin();
      } else {
        setState(() => _pesan = (res is Map ? res['error']?.toString() : null) ?? 'Login gagal');
      }
    } catch (e) {
      setState(() => _pesan = 'Gagal terhubung ke server. Pastikan backend jalan.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.groups_rounded, size: 36, color: cs.onPrimaryContainer),
                ),
                const SizedBox(height: 16),
                Text('Collab Platform',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text('Temukan kegiatan kolaboratif yang cocok',
                    style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 28),
                if (_modeRegister) ...[
                  TextField(
                    controller: _nama,
                    decoration: const InputDecoration(
                        labelText: 'Nama lengkap', prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 20),
                if (_pesan != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_pesan!, style: TextStyle(color: cs.error)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _loading
                        ? const SizedBox(
                            height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_modeRegister ? 'Daftar' : 'Masuk'),
                  ),
                ),
                TextButton(
                  onPressed: _loading ? null : () => setState(() => _modeRegister = !_modeRegister),
                  child: Text(_modeRegister ? 'Sudah punya akun? Login' : 'Belum punya akun? Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
