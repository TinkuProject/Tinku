import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../controllers/shared/social/social_links_controller.dart';
import '../../../../ui/themes/colors.dart';

class BusinessSocialSection extends StatelessWidget {
  final SocialLinksController controller;

  const BusinessSocialSection({
    super.key,
    required this.controller,
  });

  Icon _iconForNetwork(String type) {
    switch (type.toLowerCase()) {
      case 'facebook':
        return const Icon(FontAwesomeIcons.facebookF,
            size: 16, color: AppColors.darkBlue);
      case 'instagram':
        return const Icon(FontAwesomeIcons.instagram,
            size: 16, color: Colors.pink);
      case 'tiktok':
        return const Icon(FontAwesomeIcons.tiktok,
            size: 16, color: Colors.black);
      case 'twitter':
      case 'x':
        return const Icon(FontAwesomeIcons.twitter,
            size: 16, color: Colors.lightBlue);
      case 'youtube':
        return const Icon(FontAwesomeIcons.youtube,
            size: 16, color: Colors.red);
      default:
        return const Icon(Icons.link, size: 16, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final socials = controller.socialNetworks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Redes sociales",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),

        if (socials.isEmpty)
          const Text(
            "Este negocio no tiene redes sociales registradas.",
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          )
        else
          Column(
            children: socials.map((s) {
              final icon = _iconForNetwork(s.platform);

              return InkWell(
                onTap: () async {
                  final uri = Uri.tryParse(s.url);
                  if (uri != null && await canLaunchUrl(uri)) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.mediumBlue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                        AppColors.mediumBlue.withValues(alpha: 0.14),
                        child: icon,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "${s.platform[0].toUpperCase()}${s.platform.substring(1)}",
                        ),
                      ),
                      const Icon(Icons.open_in_new,
                          size: 18, color: Colors.grey),
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