import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../ui/themes/colors.dart';

final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showSnackbar(
  String message, {
  bool isError = false,
}) {
  final messenger = rootMessengerKey.currentState;

  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      tinkuSnackBar(message, isError: isError),
    );
}

SnackBar tinkuSnackBar(
  String message, {
  bool isError = false,
}) {
  final iconColor = isError ? AppColors.error : AppColors.darkBlue;
  final icon = isError ? Icons.error_rounded : Icons.info_rounded;

  return SnackBar(
    behavior: SnackBarBehavior.floating,
    elevation: 0,
    backgroundColor: Colors.transparent,
    padding: EdgeInsets.zero,
    shape: const RoundedRectangleBorder(
      side: BorderSide.none,
    ),
    margin: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 18,
    ),
    duration: const Duration(seconds: 3),
    content: Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.darkBlue,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.darkBlue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget warningIf(bool condition, String message) {
  if (!condition) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      message,
      style: const TextStyle(color: Colors.red, fontSize: 13),
    ),
  );
}

Future<File> compressImage(File file) async {
  try {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${const Uuid().v4()}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 50,
      minWidth: 600,
      minHeight: 600,
      format: CompressFormat.jpeg,
    );

    if (result != null) {
      return File(result.path);
    } else {
      return file;
    }
  } catch (e) {
    return file;
  }
}

