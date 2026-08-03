//lib/features/auth/presentation/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/error_messages.dart';
import '../domain/auth_notifier.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _hideOld = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await ref.read(authNotifierProvider.notifier).changePassword(
            currentPassword: _oldCtrl.text,
            newPassword: _newCtrl.text,
            confirmPassword: _confirmCtrl.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Kata sandi berhasil diubah'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMessages.fromException(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Kata Sandi'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ICON HEADER
            Icon(
              Icons.lock_reset_rounded,
              size: 90,
              color: Colors.blue.shade400,
            ),

            const SizedBox(height: 12),

            const Text(
              'Buat Kata Sandi Baru',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Agar akunmu tetap aman 😊',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  _passwordField(
                    controller: _oldCtrl,
                    label: 'Kata sandi lama',
                    hide: _hideOld,
                    toggle: () => setState(() => _hideOld = !_hideOld),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  _passwordField(
                    controller: _newCtrl,
                    label: 'Kata sandi baru',
                    hide: _hideNew,
                    toggle: () => setState(() => _hideNew = !_hideNew),
                    helper: 'Minimal 8 karakter ya ✨',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  _passwordField(
                    controller: _confirmCtrl,
                    label: 'Ulangi kata sandi baru',
                    hide: _hideConfirm,
                    toggle: () => setState(() => _hideConfirm = !_hideConfirm),
                    textInputAction: TextInputAction.done,
                    onSubmitted: _submit,
                    validator: (v) =>
                        v != _newCtrl.text ? 'Kata sandi belum sama' : null,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Simpan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool hide,
    required VoidCallback toggle,
    TextInputAction textInputAction = TextInputAction.done,
    VoidCallback? onSubmitted,
    String? helper,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: hide,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            hide ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: toggle,
        ),
      ),
      validator: validator ??
          (v) => v == null || v.isEmpty ? 'Tidak boleh kosong' : null,
    );
  }
}
