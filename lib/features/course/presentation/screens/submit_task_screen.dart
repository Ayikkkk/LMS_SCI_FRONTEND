import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/task_repository.dart';
import 'package:lms_frontend/features/auth/domain/auth_notifier.dart';

class SubmitTaskScreen extends ConsumerStatefulWidget {
  final int assignmentId;      // post_id dari tugas
  final String assignmentTitle;
  final bool isSubmitted;      

  const SubmitTaskScreen({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.isSubmitted,
  });

  @override
  ConsumerState<SubmitTaskScreen> createState() => _SubmitTaskScreenState();
}

class _SubmitTaskScreenState extends ConsumerState<SubmitTaskScreen> {
  final _descriptionController = TextEditingController();
  PlatformFile? _pickedFile;

  bool _alreadySubmitted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set dari backend
    _alreadySubmitted = widget.isSubmitted;
  }

  /// Pilih file
  Future<void> _pickFile() async {
    if (_alreadySubmitted) {
      _showSnackbar('Kamu sudah mengirim tugas ini.', Colors.orange);
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'zip', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
      });
    } else {
      _showSnackbar('Tidak ada file yang dipilih.', Colors.orange);
    }
  }

  /// Submit tugas
  Future<void> _submitTask() async {
    if (_alreadySubmitted) {
      _showSnackbar('Kamu sudah mengirim tugas ini sebelumnya.', Colors.orange);
      return;
    }

    if (_pickedFile == null) {
      _showSnackbar('Mohon pilih file tugas terlebih dahulu.', Colors.orange);
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showSnackbar('Deskripsi tidak boleh kosong.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final repo = ref.read(taskRepositoryProvider);
    final authToken =
        await ref.read(authNotifierProvider.notifier).getCurrentToken();

    if (authToken == null) {
      _showSnackbar('Autentikasi gagal. Silakan login ulang.', Colors.red);
      setState(() => _isLoading = false);
      return;
    }

    final result = await repo.submitTask(
      assignmentId: widget.assignmentId,
      description: _descriptionController.text.trim(),
      file: _pickedFile!,
      authToken: authToken,
    );

    setState(() => _isLoading = false);

    if (result == null) {
      // sukses submit
      _showSnackbar('✅ Tugas berhasil dikirim!', Colors.green);

      setState(() => _alreadySubmitted = true);

      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    // Jika backend kirim pesan “sudah mengirim”
    if (result.toLowerCase().contains('sudah') ||
        result.contains('409')) {
      setState(() => _alreadySubmitted = true);
      _showSnackbar('Kamu sudah mengirim tugas ini sebelumnya.', Colors.orange);
      return;
    }

    // Error lain
    _showSnackbar(result, Colors.red);
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kirim Tugas: ${widget.assignmentTitle}',
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Input Deskripsi
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Deskripsi / Catatan Tambahan',
                hintText: 'Misalnya: Tugas sudah saya kerjakan dengan metode A.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              enabled: !_alreadySubmitted, // otomatis disable
            ),
            const SizedBox(height: 25),

            // Pilih File
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                onTap: (_isLoading || _alreadySubmitted) ? null : _pickFile,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file,
                          color: Colors.deepPurple, size: 30),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _pickedFile == null
                            ? const Text(
                                'Pilih File Tugas (.pdf, .doc, .jpg, dll.)',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pickedFile!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Ukuran: ${(_pickedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      if (_pickedFile != null)
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Tombol Submit
            ElevatedButton(
              onPressed:
                  (_isLoading || _alreadySubmitted) ? null : _submitTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: _alreadySubmitted
                    ? Colors.grey
                    : Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 25,
                      height: 25,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      _alreadySubmitted ? 'Tugas Sudah Dikirim' : 'Kirim Tugas',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
