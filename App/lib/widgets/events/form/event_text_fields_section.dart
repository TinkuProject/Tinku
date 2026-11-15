import 'package:flutter/material.dart';
import '../../../controllers/event/event_form_controller.dart';
import '../../common/form/app_text_field.dart';

class EventTextFieldsSection extends StatelessWidget {
  final EventFormController controller;

  const EventTextFieldsSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          AppTextField(
            label: "Nombre del evento *",
            controller: controller.nameCtrl,
            validator: (v) =>
            v == null || v.isEmpty ? "Campo requerido" : null,
          ),

          const SizedBox(height: 12),

          AppTextField(
            label: "Descripción *",
            controller: controller.descCtrl,
            maxLines: 3,
            validator: (v) =>
                v == null || v.trim().isEmpty ? "Campo requerido" : null,
          ),

          const SizedBox(height: 12),

          AppTextField(
            label: "Máximo de asistentes (opcional)",
            controller: controller.attendeesCtrl,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 12),

          AppTextField(
            label: "Precio en Tinku (0 = gratis)",
            controller: controller.tinkuPriceCtrl,
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;

              final n = int.tryParse(v);
              if (n == null) return "Debe ser un número";
              if (n < 0) return "No puede ser negativo";

              return null;
            },
          ),
        ],
    );
  }
}
