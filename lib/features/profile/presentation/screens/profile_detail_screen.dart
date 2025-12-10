// lib/features/profile/presentation/screens/profile_detail_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../data/profile_repository.dart';
import '../providers/profile_provider.dart';
import '../../../auth/data/models/student_model.dart';

class ProfileDetailScreen extends ConsumerStatefulWidget {
  final StudentModel student;
  const ProfileDetailScreen({super.key, required this.student});

  @override
  ConsumerState<ProfileDetailScreen> createState() =>
      _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _saving = false;
  bool _changingPassword = false;
  String? _error;

  File? _pickedImage;
  CancelToken? _cancelToken;

  double _uploadProgress = 0.0;

  final ImagePicker _picker = ImagePicker();

  /// Local remote photo URL (from server). We initialize from widget.student.photo,
  /// and update this when server returns new photo URL so avatar refreshes immediately.
  String? _remotePhotoUrl;

  @override
  void initState() {
    super.initState();
    _cancelToken = CancelToken();
    _nameCtrl = TextEditingController(text: widget.student.name);
    _emailCtrl = TextEditingController(text: widget.student.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.student.phone ?? '');

    // initialize remote photo url from model (may be null)
    _remotePhotoUrl = widget.student.photo;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel("disposed");
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(source: source, imageQuality: 80);
      if (xfile == null) return;
      if (!mounted) return;
      setState(() => _pickedImage = File(xfile.path));
    } catch (e) {
      debugPrint("Image pick error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Gagal memilih gambar")));
      }
    }
  }

  String _extractDioMessage(DioError dioErr) {
    try {
      final data = dioErr.response?.data;
      if (data is Map) {
        if (data['message'] != null) return data['message'].toString();
        if (data['errors'] != null) return data['errors'].toString();
        return data.toString();
      }
      if (data is String && data.isNotEmpty) return data;
      if (dioErr.error != null) return dioErr.error.toString();
    } catch (_) {}
    return dioErr.toString();
  }

  /// Build FormData only with changed (or non-empty) fields.
  /// Async because we use MultipartFile.fromFile
  Future<FormData> _buildFormDataOnlyChanged() async {
    final original = widget.student;
    final Map<String, dynamic> map = {};

    final nameVal = _nameCtrl.text.trim();
    final emailVal = _emailCtrl.text.trim();
    final phoneVal = _phoneCtrl.text.trim();

    // Tambahkan hanya jika berbeda dari original DAN tidak kosong
    if (nameVal.isNotEmpty && nameVal != original.name) map['name'] = nameVal;
    if (emailVal.isNotEmpty && emailVal != (original.email ?? ''))
      map['email'] = emailVal;
    if (phoneVal.isNotEmpty && phoneVal != (original.phone ?? ''))
      map['phone'] = phoneVal;

    final form = FormData.fromMap(map);

    // tambahkan file jika dipilih (async)
    if (_pickedImage != null) {
      final fileName = _pickedImage!.path.split('/').last;
      final mp =
          await MultipartFile.fromFile(_pickedImage!.path, filename: fileName);
      form.files.add(MapEntry('photo', mp));
    }

    return form;
  }

  Future<void> _saveProfile() async {
    // Validate form (name is required in this UI). If you want name optional, adapt validator.
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
      _uploadProgress = 0.0;
    });

    final repo = ref.read(profileRepositoryProvider);

    try {
      final formData = await _buildFormDataOnlyChanged();

      // Kalau tidak ada perubahan sama sekali, beri tahu user dan return
      final hasChanges = (_pickedImage != null) || formData.fields.isNotEmpty;
      if (!hasChanges) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Tidak ada perubahan untuk disimpan")));
        }
        setState(() => _saving = false);
        return;
      }

      final resp = await repo.updateProfile(
        formData,
        onSendProgress: (sent, total) {
          if (total > 0 && mounted) {
            setState(() => _uploadProgress = sent / total);
          }
        },
      );

      if (!mounted) return;

      // backend mungkin mengembalikan { success: true, data: {...} } atau langsung object
      final updated = resp is Map && resp.containsKey('data') ? resp['data'] : resp;

      // invalidate supaya profile utama reload (parent)
      try {
        ref.invalidate(profileDataProvider);
      } catch (_) {}

      // Update local UI immediately:
      if (updated is Map<String, dynamic>) {
        setState(() {
          // If server returned a photo URL, update remote photo URL
          if (updated['photo'] != null && (updated['photo'] as String).isNotEmpty) {
            _remotePhotoUrl = updated['photo'] as String;
          }
          // update controllers (name/email/phone)
          _nameCtrl.text = updated['name'] ?? _nameCtrl.text;
          _emailCtrl.text = updated['email'] ?? _emailCtrl.text;
          _phoneCtrl.text = updated['phone'] ?? _phoneCtrl.text;
          // clear local picked image only after server returns success
          _pickedImage = null;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Profil berhasil diperbarui")));
      }
    } on DioError catch (dioErr) {
      if (dioErr.type == DioErrorType.cancel) return;
      final message = _extractDioMessage(dioErr);
      if (mounted) setState(() => _error = message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted)
        setState(() {
          _saving = false;
          _uploadProgress = 0.0;
        });
    }
  }

  Future<void> _changePassword() async {
    final oldPass = _oldPasswordCtrl.text.trim();
    final newPass = _newPasswordCtrl.text.trim();
    final confirm = _confirmPasswordCtrl.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Isi semua field password")));
      return;
    }
    if (newPass != confirm) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Password baru dan konfirmasi tidak cocok")));
      return;
    }

    setState(() => _changingPassword = true);
    final repo = ref.read(profileRepositoryProvider);

    try {
      await repo.changePassword(oldPass, newPass);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password berhasil diubah")));
      _oldPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
    } on DioError catch (dioErr) {
      if (dioErr.type == DioErrorType.cancel) return;
      final message = _extractDioMessage(dioErr);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal: $message")));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  Future<void> _deletePhoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Foto"),
        content: const Text("Yakin ingin menghapus foto profil?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Hapus")),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    final repo = ref.read(profileRepositoryProvider);

    try {
      await repo.deletePhoto();

      if (!mounted) return;
      ref.invalidate(profileDataProvider);

      setState(() {
        _pickedImage = null;
        _remotePhotoUrl = null;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Foto dihapus")));
    } on DioError catch (dioErr) {
      if (dioErr.type == DioErrorType.cancel) return;
      final message = _extractDioMessage(dioErr);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal hapus foto: $message")));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal hapus foto: $e")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _avatarWidget() {
    // priority: local picked image preview > remotePhotoUrl > default avatar
    if (_pickedImage != null) {
      return CircleAvatar(radius: 48, backgroundImage: FileImage(_pickedImage!));
    }

    if (_remotePhotoUrl != null && _remotePhotoUrl!.isNotEmpty) {
      return CircleAvatar(radius: 48, backgroundImage: NetworkImage(_remotePhotoUrl!));
    }

    return const CircleAvatar(
        radius: 48,
        backgroundColor: Colors.blue,
        child: Icon(Icons.person, size: 40, color: Colors.white));
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _saving || _changingPassword;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Saya"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Hapus Foto",
            onPressed: isBusy ? null : _deletePhoto,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                _avatarWidget(),
                const SizedBox(height: 8),
                // Use controller text so name updates immediately after save
                Text(_nameCtrl.text,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                    widget.student.nis?.toString() ??
                        widget.student.username.toString(),
                    style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed:
                          isBusy ? null : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text("Pilih Foto"),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed:
                          isBusy ? null : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text("Ambil Foto"),
                    ),
                  ],
                ),
                if (_uploadProgress > 0.0 && _uploadProgress < 1.0) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: _uploadProgress),
                ]
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Nama tetap wajib (silakan ubah jadi optional kalau mau)
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: "Nama"),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Nama diperlukan"
                          : null,
                    ),
                    const SizedBox(height: 8),
                    // Email -> OPSIONAL: hanya validasi format jika diisi
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: "Email"),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return null; // optional
                        if (!RegExp(r"^[^@]+@[^@]+\.[^@]+").hasMatch(s))
                          return "Email tidak valid";
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    // Telepon -> OPSIONAL: hanya validasi jika diisi
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: "Telepon"),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return null; // optional
                        // kamu bisa tambahkan validasi nomor telepon lebih ketat jika perlu
                        if (s.length < 6) return "Nomor telepon terlalu pendek";
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _saving
                        ? const CircularProgressIndicator()
                        : Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saving ? null : _saveProfile,
                                  child: const Text("Simpan Perubahan"),
                                ),
                              ),
                            ],
                          ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ]
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Ganti Password",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _oldPasswordCtrl,
                    decoration:
                        const InputDecoration(labelText: "Password Lama"),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _newPasswordCtrl,
                    decoration:
                        const InputDecoration(labelText: "Password Baru"),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordCtrl,
                    decoration: const InputDecoration(
                        labelText: "Konfirmasi Password Baru"),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  _changingPassword
                      ? const CircularProgressIndicator()
                      : Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    _changingPassword ? null : _changePassword,
                                child: const Text("Ubah Password"),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
