import 'package:flutter/material.dart';
import '../../../controllers/business/business_form_controller.dart';
import '../../common/form/app_text_field.dart';

class BusinessTextFieldsSection extends StatelessWidget {
  final BusinessFormController c;

  const BusinessTextFieldsSection({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
          children: [
            AppTextField(
                label: "Nombre *",
                controller: c.nameCtrl,
                validator: (v) => v == null || v.isEmpty ? "Requerido" : null),
            const SizedBox(height: 12),
            AppTextField(label: "NIT (opcional)", controller: c.nitCtrl),
            const SizedBox(height: 12),
            AppTextField(
                label: "Teléfono (opcional)",
                controller: c.phoneCtrl,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            AppTextField(
                label: "Correo electrónico (opcional)",
                controller: c.emailCtrl,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            AppTextField(
                label: "Sitio web (opcional)",
                controller: c.websiteCtrl,
                keyboardType: TextInputType.url),
            const SizedBox(height: 12),
            AppTextField(
                label: "Descripción *",
                controller: c.descCtrl,
                maxLines: 3,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Requerido" : null),
          ],
        );
  }
}
