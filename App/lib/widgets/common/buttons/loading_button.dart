import 'package:flutter/material.dart';
import '../../../ui/themes/colors.dart';

class LoadingButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  final String text;
  final double height;

  const LoadingButton({
    super.key,
    required this.loading,
    required this.onPressed,
    required this.text,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = loading || onPressed == null;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyBlue,
          disabledBackgroundColor:
          AppColors.navyBlue.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: loading
              ? const SizedBox(
            key: ValueKey('loading'),
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
              : Text(
            text,
            key: const ValueKey('text'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}