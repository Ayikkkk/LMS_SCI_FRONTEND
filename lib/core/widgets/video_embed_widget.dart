import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Displays a YouTube video thumbnail with play button.
/// Opens in YouTube app or browser when tapped.
/// This is the most reliable approach — YouTube blocks in-app WebView playback.
class VideoEmbedWidget extends StatelessWidget {
  final String embedCode;
  const VideoEmbedWidget({super.key, required this.embedCode});

  static String? _extractVideoId(String embedCode) {
    final srcRegex = RegExp(r'''src=["']([^"']+)["']''');
    final src = srcRegex.firstMatch(embedCode)?.group(1);
    if (src == null) return null;
    final idRegex = RegExp(r'embed/([a-zA-Z0-9_-]{11})');
    return idRegex.firstMatch(src)?.group(1);
  }

  Future<void> _open(BuildContext context, String videoId) async {
    final appUri = Uri.parse('youtube://watch?v=$videoId');
    final webUri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka video')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _extractVideoId(embedCode);

    if (videoId == null) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text('Embed video tidak valid',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return GestureDetector(
      onTap: () => _open(context, videoId),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              Image.network(
                'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black87,
                  child: const Icon(Icons.videocam,
                      color: Colors.white54, size: 48),
                ),
              ),

              // Overlay
              Container(color: Colors.black.withValues(alpha: 0.25)),

              // Play button
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),

              // Label
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Buka di YouTube',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
