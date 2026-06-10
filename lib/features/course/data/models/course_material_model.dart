class CourseMaterialModel {
  final int id;
  final int postId;
  final int mapelId;
  final int? classroomId; // null = untuk semua kelas
  final String title;
  final String? description;
  final String? link;
  final String? attachment;
  final String? embed;
  final String fileType;
  final String subjectName;

  CourseMaterialModel({
    required this.id,
    required this.postId,
    required this.mapelId,
    this.classroomId,
    required this.title,
    this.description,
    this.link,
    this.attachment,
    this.embed,
    required this.fileType,
    required this.subjectName,
  });

  factory CourseMaterialModel.fromJson(Map<String, dynamic> json) {
    final int id = json['id'] as int? ?? 0;
    final int postId = json['post_id'] as int? ?? json['id'];
    final int mapelId = json['mapel_id'] as int? ?? 0;
    final String title = json['title'] as String? ?? 'Judul Tidak Diketahui';

    final String? description = json['description'] as String?;
    final String? link = json['link'] as String?;
    final String? attachment = json['attachment'] as String?;
    final String? embed = json['embed'] as String?;

    String subjectName =
        json['subject_name'] as String? ?? 'Mapel Tidak Diketahui';

    if (subjectName == 'Mapel Tidak Diketahui') {
      final Map<String, dynamic>? mapelObject =
          json['mapel'] as Map<String, dynamic>?;
      if (mapelObject != null && mapelObject['name'] is String) {
        subjectName = mapelObject['name'];
      }
    }

    // Deteksi file type otomatis
    String mappedFileType = 'TEXT';
    final String nonNullEmbed = embed ?? '';
    final String nonNullAttachment = attachment ?? '';
    final String nonNullLink = link ?? '';

    if (nonNullEmbed.contains('iframe')) {
      mappedFileType = 'VIDEO';
    } else if (nonNullAttachment.isNotEmpty) {
      final att = nonNullAttachment.toLowerCase();
      if (att.endsWith('.pdf'))
        mappedFileType = 'PDF';
      else if (att.endsWith('.doc') || att.endsWith('.docx'))
        mappedFileType = 'DOC';
      else
        mappedFileType = 'FILE';
    } else if (nonNullLink.isNotEmpty) {
      mappedFileType = 'LINK';
    }

    return CourseMaterialModel(
      id: id,
      postId: postId,
      mapelId: mapelId,
      classroomId: json['classroom_id'] as int?,
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
