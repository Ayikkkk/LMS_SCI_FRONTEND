import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../providers/laporan_provider.dart';
import '../../data/laporan_repository.dart';
import '../../../../core/constants/error_messages.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';

class LaporanHarianScreen extends ConsumerStatefulWidget {
  const LaporanHarianScreen({super.key});

  @override
  ConsumerState<LaporanHarianScreen> createState() =>
      _LaporanHarianScreenState();
}

class _LaporanHarianScreenState extends ConsumerState<LaporanHarianScreen> {
  /// ❗ Semua jawaban default = null (tidak dipilih)
  String? q1;
  String? q2;
  String? q3;
  String? q4;
  String? q5;

  /// ❗ Kondisi tubuh juga null dulu
  String? kondisi;

  final kegiatanController = TextEditingController();
  File? foto;

  Future<void> pickFoto() async {
    final res = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (res != null) setState(() => foto = File(res.path));
  }

  Future<void> submit() async {
    final repo = ref.read(laporanRepositoryProvider);

    /// VALIDASI
    if (q1 == null || q2 == null || q3 == null || q4 == null || q5 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap jawab semua pertanyaan")),
      );
      return;
    }

    if (kondisi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap pilih kondisi tubuh")),
      );
      return;
    }

    final listReport = [
      q1!,
      q2!,
      q3!,
      q4!,
      q5!,
      kondisi!,
      kegiatanController.text.isEmpty ? "-" : kegiatanController.text,
    ];

    MultipartFile? imgFile;
    if (foto != null) {
      imgFile = await MultipartFile.fromFile(
        foto!.path,
        filename: "foto_${DateTime.now().millisecondsSinceEpoch}.jpg",
        contentType: MediaType("image", "jpeg"),
      );
    }

    try {
      await repo.submitReport(report: listReport, img: imgFile);

      ref.invalidate(laporanCheckProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Laporan berhasil dikirim")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMessages.fromException(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cek = ref.watch(laporanCheckProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Laporan Harian")),
      body: cek.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: ErrorMessages.fromException(e),
          onRetry: () => ref.invalidate(laporanCheckProvider),
        ),
        data: (sudahIsi) {
          if (sudahIsi) {
            return EmptyStateWidget(
              title: 'Laporan sudah terisi',
              subtitle:
                  'Kamu sudah mengisi laporan hari ini.\nSilakan isi lagi besok.',
              icon: Icons.check_circle_outline_rounded,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _radio(
                  "Tetap Belajar Mandiri?", (v) => setState(() => q1 = v), q1),
              _radio("Mengerjakan Tugas Pembelajaran?",
                  (v) => setState(() => q2 = v), q2),
              _radio("Membantu Orang Tua?", (v) => setState(() => q3 = v), q3),
              _radio(
                  "Tetap Berada Dirumah?", (v) => setState(() => q4 = v), q4),
              _radio("Melaksanakan Ibadah?", (v) => setState(() => q5 = v), q5),
              const SizedBox(height: 15),
              DropdownButtonFormField(
                value: kondisi,
                items: const [
                  DropdownMenuItem(value: "Sehat", child: Text("Sehat")),
                  DropdownMenuItem(
                      value: "Kurang Sehat", child: Text("Kurang Sehat")),
                  DropdownMenuItem(value: "Sakit", child: Text("Sakit")),
                ],
                onChanged: (v) => setState(() => kondisi = v),
                decoration: const InputDecoration(
                  labelText: "Kondisi Tubuh",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: kegiatanController,
                decoration: const InputDecoration(
                  labelText: "Kegiatan lain-lain",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: pickFoto,
                icon: const Icon(Icons.image),
                label: const Text("Tambah Dokumentasi"),
              ),
              if (foto != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Image.file(foto!, height: 120),
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: submit,
                child: const Text("Kirim Laporan"),
              )
            ],
          );
        },
      ),
    );
  }

  /// RADIO BUILDER
  Widget _radio(String title, Function(String?) onChanged, String? group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Radio(
              value: "Ya",
              groupValue: group,
              onChanged: onChanged,
            ),
            const Text("Ya"),
            Radio(
              value: "Tidak",
              groupValue: group,
              onChanged: onChanged,
            ),
            const Text("Tidak"),
          ],
        ),
      ],
    );
  }
}
