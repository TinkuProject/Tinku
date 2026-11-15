import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/media_model.dart';

class MediaHero extends StatelessWidget {
  final List<dynamic> images;

  const MediaHero({
    super.key,
    required this.images,
  });

  bool _isPdf(String value) {
    return value.toLowerCase().endsWith('.pdf');
  }

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.withValues(alpha: 0.1),
        ),
        child: const Icon(
          Icons.image,
          size: 60,
          color: Colors.grey,
        ),
      );
    }

    final img = images.first;

    // =========================
    // MEDIA MODEL
    // =========================
    if (img is MediaModel) {
      if (_isPdf(img.url)) {
        return _buildPdfPlaceholder();
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          img.url,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    // =========================
    // XFILE
    // =========================
    if (img is XFile) {
      if (_isPdf(img.path)) {
        return _buildPdfPlaceholder();
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(img.path),
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    // =========================
    // STRING URL (legacy)
    // =========================
    if (img is String) {
      if (_isPdf(img)) {
        return _buildPdfPlaceholder();
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          img,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.withValues(alpha: 0.1),
      ),
      child: const Icon(
        Icons.broken_image,
        size: 60,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildPdfPlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.withValues(alpha: 0.1),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 52,
            color: Colors.red,
          ),
          SizedBox(height: 8),
          Text("Documento PDF"),
        ],
      ),
    );
  }
}