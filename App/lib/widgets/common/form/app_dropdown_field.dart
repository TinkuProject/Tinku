import 'package:flutter/material.dart';
import 'app_form_field_container.dart';

class AppDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  List<DropdownMenuItem<T>> _uniqueItems(List<DropdownMenuItem<T>> source) {
    final unique = <DropdownMenuItem<T>>[];

    for (final item in source) {
      final alreadyExists = unique.any((e) => e.value == item.value);
      if (!alreadyExists) {
        unique.add(item);
      }
    }

    return unique;
  }

  T? _safeInitialValue(List<DropdownMenuItem<T>> uniqueItems) {
    if (value == null) return null;

    final matches = uniqueItems.where((item) => item.value == value).length;
    return matches == 1 ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    final uniqueItems = _uniqueItems(items);
    final safeValue = _safeInitialValue(uniqueItems);

    return AppFormFieldContainer(
      label: label,
      child: DropdownButtonFormField<T>(
        initialValue: safeValue,
        items: uniqueItems,
        onChanged: onChanged,
        validator: validator,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
        icon: const Icon(Icons.keyboard_arrow_down),
      ),
    );
  }
}