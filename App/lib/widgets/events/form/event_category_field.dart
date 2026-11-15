import 'package:flutter/material.dart';
import '../../../controllers/event/event_form_controller.dart';
import '../../common/form/app_dropdown_field.dart';

class EventCategoryField extends StatelessWidget {
  final EventFormController controller;

  const EventCategoryField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AppDropdownField<String>(
      label: "Categoría *",
      value: controller.selectedCategoryId,
      items: controller.categories.entries.map((e) {
        return DropdownMenuItem(
          value: e.key,
          child: Text(e.value),
        );
      }).toList(),
      validator: (v) =>
      v == null ? "Seleccione una categoría" : null,
      onChanged: controller.setCategory,
    );
  }
}
