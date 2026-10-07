import 'dart:convert';
import 'dart:io';

/// Encodes local screenshot files as data-URLs for vision analysis.
abstract final class ImageEncoder {
  static const int maxImages = 8;

  static Future<List<String>> toDataUrls(List<String> paths) async {
    final urls = <String>[];
    for (final path in paths.take(maxImages)) {
      final file = File(path);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) continue;
      final lower = path.toLowerCase();
      final mime = lower.endsWith('.png')
          ? 'image/png'
          : lower.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';
      urls.add('data:$mime;base64,${base64Encode(bytes)}');
    }
    return urls;
  }
}
