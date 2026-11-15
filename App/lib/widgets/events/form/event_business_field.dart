import 'package:flutter/material.dart';
import '../../../controllers/event/event_form_controller.dart';
import '../../common/form/app_dropdown_field.dart';

class EventBusinessField extends StatelessWidget {
  final EventFormController controller;

  const EventBusinessField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.businesses.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppDropdownField<String>(
      label: "Negocio (opcional)",
      value: controller.selectedBusinessId,
      items: controller.businesses.map((b) {
        return DropdownMenuItem(
          value: b.id.toString(),
          child: Text(b.name),
        );
      }).toList(),
      onChanged: controller.setBusiness,
    );
  }
}