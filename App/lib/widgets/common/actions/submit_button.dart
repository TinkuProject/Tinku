import 'package:flutter/material.dart';
import '../../common/buttons/loading_button.dart';

class SubmitButton extends StatelessWidget {
  final bool loading;
  final String text;
  final VoidCallback onPressed;

  const SubmitButton({
    super.key,
    required this.loading,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: LoadingButton(
          loading: loading,
          text: text,
          onPressed: onPressed,
        ),
      ),
    );
  }
}