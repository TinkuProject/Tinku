import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../common/action_icon.dart';

class BusinessActionsRow extends StatelessWidget {
  final String? phone;
  final String? website;

  final VoidCallback onOpenWhatsApp;
  final VoidCallback onOpenMaps;
  final VoidCallback onOpenWebsite;

  const BusinessActionsRow({
    super.key,
    required this.phone,
    required this.website,
    required this.onOpenWhatsApp,
    required this.onOpenMaps,
    required this.onOpenWebsite,
  });

  bool get _hasPhone => phone != null && phone!.trim().isNotEmpty;
  bool get _hasWebsite => website != null && website!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (_hasPhone)
          ActionIcon(
            icon: FontAwesomeIcons.whatsapp,
            label: "WhatsApp",
            color: Colors.green,
            onTap: onOpenWhatsApp,
          ),

        ActionIcon(
          icon: Icons.location_on,
          label: "Ubicación",
          color: Colors.blue,
          onTap: onOpenMaps,
        ),

        if (_hasWebsite)
          ActionIcon(
            icon: Icons.language,
            label: "Web",
            color: Colors.red,
            onTap: onOpenWebsite,
          ),
      ],
    );
  }
}