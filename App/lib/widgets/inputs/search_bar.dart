import 'package:flutter/material.dart';
import '../../ui/themes/colors.dart';

class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final String initialValue;

  const SearchBarWidget({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.initialValue = '',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {}); // solo para icono
    widget.onChanged(_controller.text);
  }

  void _clear() {
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;

    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        hintText: widget.hintText,
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textSecondary,
        ),
        suffixIcon: hasText
            ? IconButton(
          icon: const Icon(
            Icons.clear,
            color: AppColors.textSecondary,
          ),
          onPressed: _clear,
        )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}