import 'package:flutter/material.dart';

import '../../../../controllers/business/business_detail_controller.dart';
import '../sections/business_social_section.dart';
import '../sections/business_hours_section.dart';
import '../sections/business_certifications_section.dart';
import '../sections/business_discounts_section.dart';
import '../sections/business_products_section.dart';

class DescriptionTab extends StatelessWidget {
  final BusinessDetailController controller;
  final bool isService;

  const DescriptionTab({
    super.key,
    required this.controller,
    required this.isService,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
          /// 🧾 CERTIFICACIONES
          BusinessCertificationsSection(
            certifications: controller.certificationsC.certifications,
            mediaMap: controller.certificationsC.certificationMedia,
          ),

          const SizedBox(height: 20),

          /// 💸 DESCUENTOS
          BusinessDiscountsSection(
            discounts: controller.discounts,
          ),

          const SizedBox(height: 20),

          /// 🛍️ PRODUCTOS / SERVICIOS
          BusinessProductsSection(
            products: controller.productsC.products,
            controller: controller.carouselC,
            isService: isService,
          ),

          const SizedBox(height: 20),

          /// 🌐 REDES
          BusinessSocialSection(
            controller: controller.socialsC,
          ),

          const SizedBox(height: 20),

          /// ⏰ HORARIOS
          BusinessHoursSection(
            hours: controller.hoursC.operatingHours,
          ),
        ]
      );
  }
}