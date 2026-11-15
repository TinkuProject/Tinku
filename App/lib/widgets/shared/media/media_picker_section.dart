import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/media_model.dart';

class MediaPickerSection extends StatelessWidget {
  final List<dynamic> images;
  final VoidCallback onAdd;
  final void Function(dynamic) onRemove;

  const MediaPickerSection({
    super.key,
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  bool _isPdfUrl(String url) {
    return url.toLowerCase().endsWith('.pdf');
  }

  ImageProvider? _providerFor(dynamic item) {
    if (item is MediaModel) {
      if (_isPdfUrl(item.url)) return null;
      return NetworkImage(item.url);
    }

    if (item is String) {
      if (_isPdfUrl(item)) return null;
      return NetworkImage(item);
    }

    if (item is XFile) {
      return FileImage(File(item.path));
    }

    return null;
  }

  Widget _buildPreview(dynamic item,
      {double width = double.infinity, double height = 220}) {
    if (item is MediaModel && _isPdfUrl(item.url)) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.withValues(alpha: 0.08),
        child: const Center(
          child: Icon(Icons.picture_as_pdf, size: 40),
        ),
      );
    }

    if (item is String && _isPdfUrl(item)) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.withValues(alpha: 0.08),
        child: const Center(
          child: Icon(Icons.picture_as_pdf, size: 40),
        ),
      );
    }

    final provider = _providerFor(item);
    if (provider == null) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.withValues(alpha: 0.08),
        child: const Center(
          child: Icon(Icons.broken_image, size: 40),
        ),
      );
    }

    return Image(
      image: provider,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    const maxImages = 5;
    final hasImages = images.isNotEmpty;
    final canAdd = images.length < maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: canAdd ? onAdd : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                hasImages
                    ? _buildPreview(images.first)
                    : Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey.withValues(alpha: 0.08),
                  child: const Center(
                    child: Icon(Icons.add_a_photo, size: 36),
                  ),
                ),
                if (hasImages)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            "Editar",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!canAdd)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.25),
                      child: const Center(
                        child: Text(
                          "Máximo 5 imágenes",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: canAdd ? images.length + 1 : images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == 0 && canAdd) {
                return GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.withValues(alpha: 0.08),
                    ),
                    child: const Icon(Icons.add),
                  ),
                );
              }

              final img = canAdd ? images[i - 1] : images[i];

              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildPreview(
                      img,
                      width: 80,
                      height: 80,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemove(img),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}