// lib/features/auth/presentation/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Controller untuk mengambil input dari TextFormField
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // GlobalKey untuk validasi form
  final _formKey = GlobalKey<FormState>();

  // State lokal untuk mengontrol loading indicator
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi utama untuk menangani proses login
  Future<void> _submitLogin() async {
    // 1. Validasi Form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true); // Mulai loading

    // 2. Panggil fungsi doLogin dari AuthNotifier
    // ref.read() digunakan karena kita hanya perlu memanggil method/fungsi
    final success = await ref.read(authNotifierProvider.notifier).doLogin(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );

    setState(() => _isLoading = false); // Hentikan loading

    // 3. Feedback ke Pengguna
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login Gagal. Pastikan Username dan Password benar.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    // Jika success, status Riverpod (AuthStatus) akan berubah menjadi authenticated,
    // dan main.dart akan otomatis mengarahkan ke DashboardScreen.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Siswa'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 50),
              //

              // 🖼️ Placeholder untuk Logo Aplikasi
              const Center(
                child: Icon(Icons.school, size: 80, color: Colors.blue),
              ),
              const SizedBox(height: 40),

              // --- Input Username ---
              TextFormField(
                controller: _usernameController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- Input Password ---
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // --- Tombol Login ---
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text(
                        'LOGIN',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
              const SizedBox(height: 20),

              // Opsi lupa password (jika ada)
              TextButton(
                onPressed: () {
                  // Arahkan ke halaman Lupa Password
                },
                child: const Text('Lupa Password?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}