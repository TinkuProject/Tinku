import 'package:flutter/material.dart';
import '../../../components/utils.dart';
import '../../../controllers/shared/social/social_links_controller.dart';
import '../../common/form/app_text_field.dart';
import '../../common/form/app_dropdown_field.dart';
import '../../../ui/themes/colors.dart';

class SocialLinksSection extends StatelessWidget {
  final SocialLinksController c;

  const SocialLinksSection({
    super.key,
    required this.c,
  });

  String _normalize(String value) => value.trim().toLowerCase();

  String _label(String value) {
    final v = _normalize(value);
    if (v.isEmpty) return v;
    return v[0].toUpperCase() + v.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final items = c.availableSocialTypes
        .map(_normalize)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final currentValue = c.selectedSocialType == null
        ? null
        : _normalize(c.selectedSocialType!);

    final safeValue = items.contains(currentValue) ? currentValue : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppDropdownField<String>(
          key: ValueKey('social-type-${items.join("|")}-${safeValue ?? "null"}'),
          label: "Tipo de red",
          value: safeValue,
          items: items
              .map(
                (type) => DropdownMenuItem<String>(
              value: type,
              child: Text(_label(type)),
            ),
          )
              .toList(),
          onChanged: (v) => c.selectedSocialType = v == null ? null : _normalize(v),
        ),

        const SizedBox(height: 12),

        AppTextField(
          label: "Usuario",
          controller: c.urlController,
          hint: "@usuario",
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              final url = c.urlController.text.trim();
              final type = c.selectedSocialType?.trim().toLowerCase();

              if (url.isEmpty || type == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  tinkuSnackBar("Complete tipo y usuario", isError: true),
                );
                return;
              }

              c.addSocialNetwork(type, url);
              c.urlController.clear();
            },
            icon: const Icon(Icons.add),
            label: const Text("Agregar red"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        if (c.socialNetworks.isNotEmpty)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: c.socialNetworks.map((s) {
              final platform = _normalize(s.platform);

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.navyBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.navyBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_label(platform)}: @${c.usernameFromUrl(platform, s.url)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => c.removeSocialNetwork(s),
                      child: const Icon(Icons.close, size: 16),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
