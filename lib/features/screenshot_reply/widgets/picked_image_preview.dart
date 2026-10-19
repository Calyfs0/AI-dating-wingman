import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Cross-platform preview for [XFile] (works on web — no `dart:io` / [Image.file]).
class PickedImagePreview extends StatelessWidget {
  const PickedImagePreview({
    super.key,
    required this.file,
    this.fit = BoxFit.fitWidth,
    this.width = double.infinity,
    this.errorHeight = 200,
  });

  final XFile file;
  final BoxFit fit;
  final double width;
  final double errorHeight;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            height: errorHeight,
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty || snapshot.hasError) {
          return SizedBox(
            height: errorHeight,
            child: const Center(
              child: Icon(Icons.broken_image_outlined, color: Color(0xFF7E738F)),
            ),
          );
        }
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => SizedBox(
            height: errorHeight,
            child: const Center(
              child: Icon(Icons.broken_image_outlined, color: Color(0xFF7E738F)),
            ),
          ),
        );
      },
    );
  }
}
