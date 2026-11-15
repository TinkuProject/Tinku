import 'package:flutter/material.dart';
import '../../../models/business_model.dart';
import '../../../ui/themes/colors.dart';

class BusinessInfoSection extends StatelessWidget {
  final BusinessModel business;
  final String categoryName;
  final String? ownerCi;

  final VoidCallback? onWhatsApp;
  final VoidCallback? onWebsite;

  const BusinessInfoSection({
    super.key,
    required this.business,
    required this.categoryName,
    this.ownerCi,
    this.onWhatsApp,
    this.onWebsite,
  });

  Widget _optionalRow(
      IconData icon,
      String label,
      String? value, {
        VoidCallback? onTap,
        String? displayValue,
        TextStyle? valueStyle,
      }) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                displayValue ?? value,
                style: valueStyle ?? const TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _websiteDisplay(String website) {
    return website
        .trim()
        .replaceFirst(RegExp(r'^https?://', caseSensitive: false), '')
        .replaceFirst(RegExp(r'/$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final b = business;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// TITLE
        Text(
          b.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 6),

        /// ADDRESS
        Text(
          b.address,
          style: const TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 8),

        /// CATEGORY
        if (categoryName.isNotEmpty)
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              categoryName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

        const SizedBox(height: 12),

        /// OPTIONAL FIELDS
        _optionalRow(
          Icons.badge,
          b.nit?.trim().isNotEmpty == true ? "NIT" : "CI",
          b.nit?.trim().isNotEmpty == true ? b.nit : ownerCi,
        ),
        _optionalRow(Icons.email, "Correo", b.email),
        _optionalRow(Icons.phone, "Teléfono", b.phone,
            onTap: onWhatsApp),
        _optionalRow(
          Icons.language,
          "Sitio web",
          b.website,
          onTap: onWebsite,
          displayValue: b.website == null ? null : _websiteDisplay(b.website!),
          valueStyle: const TextStyle(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.darkBlue,
          ),
        ),

        if (b.description != null &&
            b.description!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            "Descripción",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            b.description!,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ],
    );
  }
}
