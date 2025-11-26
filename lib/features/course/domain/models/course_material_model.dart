class CourseMaterialModel {
  final int id;
  final int mapelId;
  final String title;
  final String? description;
  final String? link;
  final String? attachment;
  final String? embed;
  final String fileType;
  final String subjectName;

  CourseMaterialModel({
    required this.id,
    required this.mapelId,
    required this.title,
    this.description,
    this.link,
    this.attachment,
    this.embed,
    required this.fileType,
    required this.subjectName,
  });

  factory CourseMaterialModel.fromJson(Map<String, dynamic> json) {
    // Pastikan semua nilai diambil dengan tipe data yang benar dan aman.
    final int id = json['id'] as int? ?? 0;
    final int mapelId = json['mapel_id'] as int? ?? 0;
    final String title = json['title'] as String? ?? 'Judul Tidak Diketahui';

    // String? field. Gunakan as String?
    final String? description = json['description'] as String?;
    final String? link = json['link'] as String?;
    final String? attachment = json['attachment'] as String?;
    final String? embed = json['embed'] as String?;

    // =========================
    // SUBJECT NAME HANDLING (Menggunakan key 'subject_name' yang dikirim dari Controller)
    // =========================
    String subjectName = (json['subject_name'] as String? ?? 'Mapel Tidak Diketahui');

    // Fallback jika 'subject_name' tidak ada (meskipun sudah diperbaiki di Controller)
    if (subjectName == 'Mapel Tidak Diketahui') {
        final Map<String, dynamic>? mapelObject = json['mapel'] as Map<String, dynamic>?;
        if (mapelObject != null && mapelObject['name'] is String) {
            subjectName = mapelObject['name'];
        }
    }


    // =========================
    // DETEKSI FILE TYPE OTOMATIS
    // =========================
    String mappedFileType = 'TEXT';

    final String nonNullEmbed = embed ?? '';
    final String nonNullAttachment = attachment ?? '';
    final String nonNullLink = link ?? '';

    if (nonNullEmbed.isNotEmpty && nonNullEmbed.toLowerCase().contains('iframe')) {
      mappedFileType = 'VIDEO';
    } else if (nonNullAttachment.isNotEmpty) {
      // Hanya mengecek attachment jika tidak ada embed
      final String att = nonNullAttachment.toLowerCase();
      if (att.endsWith('.pdf')) {
        mappedFileType = 'PDF';
      } else if (att.endsWith('.doc') || att.endsWith('.docx')) {
        mappedFileType = 'DOC';
      } else {
        mappedFileType = 'FILE';
      }
    } else if (nonNullLink.isNotEmpty) {
      mappedFileType = 'LINK';
    }

    // =========================
    // PEMBENTUKAN MODEL AKHIR
    // =========================
    return CourseMaterialModel(
      id: id,
      mapelId: mapelId,
      title: title,
      description: description,
      link: link,
      attachment: attachment,
      embed: embed,
      fileType: mappedFileType,
      subjectName: subjectName,
    );
  }
}