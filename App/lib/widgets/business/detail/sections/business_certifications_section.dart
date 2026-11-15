import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../models/certification_model.dart';
import '../../../../ui/themes/colors.dart';

class BusinessCertificationsSection extends StatelessWidget {
  final List<CertificationModel> certifications;
  final Map<int, List<String>> mediaMap;

  const BusinessCertificationsSection({
    super.key,
    required this.certifications,
    required this.mediaMap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Certificaciones",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),

        if (certifications.isEmpty)
          const Text(
            "Este negocio no cuenta con certificaciones registradas.",
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          )
        else
          Column(
            children: certifications.map((cert) {
              final mediaList = mediaMap[cert.id] ?? [];
              final fileUrl =
              mediaList.isNotEmpty ? mediaList.first : "";

              final isPdf = fileUrl.toLowerCase().endsWith(".pdf");

              return InkWell(
                onTap: () {
                  if (fileUrl.isNotEmpty) {
                    launchUrl(Uri.parse(fileUrl),
                        mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.mediumBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPdf
                            ? Icons.picture_as_pdf
                            : Icons.verified,
                        color: isPdf
                            ? Colors.redAccent
                            : AppColors.darkBlue,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cert.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (fileUrl.isNotEmpty)
                        const Icon(Icons.open_in_new,
                            size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}