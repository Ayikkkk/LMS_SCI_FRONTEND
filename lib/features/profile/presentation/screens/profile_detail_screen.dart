import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../providers/profile_provider.dart';
import '../../../auth/data/models/student_model.dart';
import '../../../../core/constants/error_messages.dart';
import '../../../../core/widgets/error_widget.dart';

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
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  bool _saving = false;
  String? _error;

  File? _pickedImage;
  CancelToken? _cancelToken;

  final ImagePicker _picker = ImagePicker();

  String? _remotePhotoUrl;

  @override
  void initState() {
    super.initState();
    _cancelToken = CancelToken();
    _nameCtrl = TextEditingController(text: widget.student.name);
    _usernameCtrl = TextEditingController(text: widget.student.username);
    _emailCtrl = TextEditingController(text: widget.student.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.student.phone ?? '');
    _remotePhotoUrl = widget.student.photo;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel("disposed");
    }
    super.dispose();
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text("Pilih dari Galeri"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text("Ambil dari Kamera"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_remotePhotoUrl != null || _pickedImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  "Hapus Foto",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deletePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  // ==========================
  // IMAGE PICKER
  // ==========================
  Future<void> _pickImage(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(source: source, imageQuality: 80);
      if (xfile == null || !mounted) return;
      setState(() => _pickedImage = File(xfile.path));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memilih gambar")),
        );
      }
    }
  }

  // ==========================
  // BUILD FORM DATA (ONLY CHANGED)
  // ==========================
  Future<FormData> _buildFormDataOnlyChanged() async {
    final original = widget.student;
    final Map<String, dynamic> map = {};

    final nameVal = _nameCtrl.text.trim();
    final usernameVal = _usernameCtrl.text.trim();
    final emailVal = _emailCtrl.text.trim();
    final phoneVal = _phoneCtrl.text.trim();

    if (nameVal.isNotEmpty && nameVal != original.name) {
      map['name'] = nameVal;
    }
    if (usernameVal.isNotEmpty && usernameVal != original.username) {
      map['username'] = usernameVal;
    }
    if (emailVal.isNotEmpty && emailVal != (original.email ?? '')) {
      map['email'] = emailVal;
    }
    if (phoneVal.isNotEmpty && phoneVal != (original.phone ?? '')) {
      map['phone'] = phoneVal;
    }

    final form = FormData.fromMap(map);

    if (_pickedImage != null) {
      final fileName = _pickedImage!.path.split('/').last;
      final mp =
          await MultipartFile.fromFile(_pickedImage!.path, filename: fileName);
      form.files.add(MapEntry('photo', mp));
    }

    return form;
  }

  // ==========================
  // SAVE PROFILE
  // ==========================
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final repo = ref.read(profileRepositoryProvider);

    try {
      final formData = await _buildFormDataOnlyChanged();
      final hasChanges = (_pickedImage != null) || formData.fields.isNotEmpty;

      if (!hasChanges) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tidak ada perubahan untuk disimpan")),
          );
        }
        setState(() => _saving = false);
        return;
      }

      final resp = await repo.updateProfile(
        formData,
        onSendProgress: null,
      );

      if (!mounted) return;

      // resp selalu Map — ambil 'data' jika ada, fallback ke resp langsung
      final updated = resp.containsKey('data')
          ? resp['data'] as Map<String, dynamic>?
          : resp;

      ref.invalidate(profileDataProvider);

      if (updated != null) {
        setState(() {
          if (updated['photo'] != null &&
              (updated['photo'] as String).isNotEmpty) {
            _remotePhotoUrl = updated['photo'] as String;
          }
          _nameCtrl.text = updated['name'] ?? _nameCtrl.text;
          _usernameCtrl.text = updated['username'] ?? _usernameCtrl.text;
          _emailCtrl.text = updated['email'] ?? _emailCtrl.text;
          _phoneCtrl.text = updated['phone'] ?? _phoneCtrl.text;
          _pickedImage = null;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil berhasil diperbarui")),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = ErrorMessages.fromException(e));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // ==========================
  // DELETE PHOTO
  // ==========================
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto berhasil dihapus")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ==========================
  // READ ONLY FIELD
  // ==========================
  Widget _readOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline,
            color: isDark ? Colors.grey[600] : Colors.black38,
          ),
        ],
      ),
    );
  }

  Widget _avatarWidget() {
    if (_pickedImage != null) {
      return CircleAvatar(
          radius: 48, backgroundImage: FileImage(_pickedImage!));
    }
    if (_remotePhotoUrl != null && _remotePhotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        backgroundColor: Colors.blue,
        child: ClipOval(
          child: Image.network(
            _remotePhotoUrl!,
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    return const CircleAvatar(
      radius: 48,
      backgroundColor: Colors.blue,
      child: Icon(Icons.person, size: 40, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _saving;
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
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    _avatarWidget(),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: isBusy ? null : _showPhotoOptions,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _nameCtrl.text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.student.className ?? "-",
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]
                        : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ==========================
          // DATA SISWA (READ ONLY)
          // ==========================
          _readOnlyField(
            label: "Nomor Absen",
            value: widget.student.absenNumber?.toString() ?? "-",
            icon: Icons.format_list_numbered,
          ),
          const SizedBox(height: 8),
          _readOnlyField(
            label: "NIS",
            value: widget.student.nis ?? "-",
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 16),

          Text(
            "Nomor Absen dan NIS tidak bisa diubah.\nJika ada kesalahan, hubungi guru ya 😊",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.black54,
            ),
          ),

          const SizedBox(height: 20),

          // ==========================
          // FORM EDIT PROFIL
          // ==========================
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Nama",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Nama diperlukan"
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Username",
                        prefixIcon: Icon(Icons.alternate_email),
                        helperText: "Hanya huruf, angka, - dan _",
                      ),
                      keyboardType: TextInputType.visiblePassword,
                      autocorrect: false,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Username diperlukan";
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(v.trim())) {
                          return "Hanya huruf, angka, - dan _";
                        }
                        if (v.trim().length < 3) {
                          return "Minimal 3 karakter";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: "Telepon",
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _saving
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              child: const Text("Simpan Perubahan"),
                            ),
                          ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      AppErrorWidget.inline(message: _error!),
                    ]
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
