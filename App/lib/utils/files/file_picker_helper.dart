import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class FilePickerHelper {
  static final ImagePicker _imagePicker = ImagePicker();

  static Future<File?> pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    return picked != null ? File(picked.path) : null;
  }

  static Future<File?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }

    return null;
  }
}