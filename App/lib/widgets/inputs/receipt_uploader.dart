import 'dart:io';
import 'package:flutter/material.dart';

import '../../../ui/themes/colors.dart';
import '../../../utils/files/file_picker_helper.dart';

class ReceiptUploader extends StatefulWidget {
  final ValueChanged<File?> onChanged;

  const ReceiptUploader({
    super.key,
    required this.onChanged,
  });

  @override
  State<ReceiptUploader> createState() => _ReceiptUploaderState();
}

class _ReceiptUploaderState extends State<ReceiptUploader> {
  File? _file;

  Future<void> _pick() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir imagen desde galería'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Seleccionar archivo PDF'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    try {
      File? selected;

      if (choice == 'gallery') {
        selected = await FilePickerHelper.pickImage();
      } else if (choice == 'pdf') {
        selected = await FilePickerHelper.pickPdf();
      }

      if (selected != null) {
        setState(() => _file = selected);
        widget.onChanged(selected);
      }
    } catch (_) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _file?.path.split('/').last;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subir comprobante',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pick,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.upload_file_rounded,
                      color: AppColors.darkBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fileName ?? 'Seleccionar imagen o PDF',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
