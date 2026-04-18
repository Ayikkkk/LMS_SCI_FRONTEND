import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../data/repository/task_repository.dart';

// Ekstensi yang diizinkan
const _allowedExtensions = [
  'pdf',
  'doc',
  'docx',
  'zip',
  'jpg',
  'jpeg',
  'png',
  'mp4',
  'mov',
  'avi',
  'mkv',
];

// Batas ukuran file: 10MB
const _maxFileSizeMB = 10;

class SubmitTaskScreen extends ConsumerStatefulWidget {
  final int assignmentId;
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
    _alreadySubmitted = widget.isSubmitted;
  }

  // =============================================================
  // PICK FILE
  // =============================================================

  Future<void> _pickFile() async {
    if (_alreadySubmitted) {
      _showSnackbar('Kamu sudah mengirim tugas ini.', Colors.orange);
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: false, // PENTING: jangan load ke memory, pakai path saja
    );

    if (result == null || result.files.isEmpty) {
      _showSnackbar('Tidak ada file yang dipilih.', Colors.orange);
      return;
    }

    final file = result.files.first;

    // Validasi path tersedia (mobile)
    if (file.path == null) {
      _showSnackbar('File tidak dapat dibaca. Coba file lain.', Colors.red);
      return;
    }

    // Validasi ukuran — file.size tersedia tanpa load data
    final sizeMB = file.size / 1024 / 1024;
    if (sizeMB > _maxFileSizeMB) {
      _showSnackbar(
        'File terlalu besar (${sizeMB.toStringAsFixed(1)} MB). Maksimal ${_maxFileSizeMB} MB.',
        Colors.red,
      );
      return;
    }

    setState(() => _pickedFile = file);
  }

  // =============================================================
  // SUBMIT TASK
  // =============================================================

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

    final result = await repo.submitTask(
      assignmentId: widget.assignmentId,
      description: _descriptionController.text.trim(),
      file: _pickedFile!,
    );

    setState(() => _isLoading = false);

    if (result == null) {
      _showSnackbar('✅ Tugas berhasil dikirim!', Colors.green);
      setState(() => _alreadySubmitted = true);

      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    if (result.toLowerCase().contains('sudah') || result.contains('409')) {
      setState(() => _alreadySubmitted = true);
      _showSnackbar('Kamu sudah mengirim tugas ini sebelumnya.', Colors.orange);
      return;
    }

    _showSnackbar(result, Colors.red);
  }

  // =============================================================
  // UI HELPERS
  // =============================================================

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

  // =============================================================
  // FILE TYPE HELPERS
  // =============================================================

  bool _isVideoFile(String ext) =>
      ['mp4', 'mov', 'avi', 'mkv'].contains(ext.toLowerCase());

  IconData _fileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return Icons.videocam;
      case 'zip':
        return Icons.folder_zip;
      default:
        return Icons.attach_file;
    }
  }

  // =============================================================
  // UI
  // =============================================================

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Deskripsi
            TextFormField(
              controller: _descriptionController,
              enabled: !_alreadySubmitted,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Deskripsi / Catatan Tambahan',
                hintText:
                    'Misalnya: Tugas sudah saya kerjakan dengan metode A.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // File Picker
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                onTap: (_isLoading || _alreadySubmitted) ? null : _pickFile,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Icon(
                        _pickedFile == null
                            ? Icons.attach_file
                            : _fileIcon(_pickedFile!.extension ?? ''),
                        color: Colors.deepPurple,
                        size: 30,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _pickedFile == null
                            ? const Text(
                                'Pilih File Tugas\n(.pdf, .doc, .jpg, .mp4, .mov, dll.)',
                                style: TextStyle(color: Colors.grey),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pickedFile!.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Ukuran: ${(_pickedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (_isVideoFile(
                                      _pickedFile!.extension ?? ''))
                                    const Text(
                                      '🎬 File video',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.deepPurple,
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

            // Info ukuran maksimal
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Maksimal ${_maxFileSizeMB} MB'
                      ' (PDF, DOC, JPG, PNG, MP4, MOV, dll.)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Submit Button
            ElevatedButton(
              onPressed: (_isLoading || _alreadySubmitted) ? null : _submitTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: _alreadySubmitted
                    ? Colors.grey
                    : Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
