import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

import '../../../ui/themes/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool centerTitle;
  final double height;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.centerTitle = false,
    this.height = 80,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final zoomDrawer = ZoomDrawer.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.background,

            /// 🔥 línea inferior sutil (clave)
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.6),
              ),
            ),
          ),
          child: Row(
            children: [
              /// 🔘 BOTÓN
              _LeadingButton(zoomDrawer: zoomDrawer),

              const SizedBox(width: 10),

              /// 📝 TITULO
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),

              /// 🎯 ACTIONS CON ESTILO
              if (actions != null)
                ...actions!.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _ActionWrapper(child: w),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionWrapper extends StatelessWidget {
  final Widget child;

  const _ActionWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: child),
    );
  }
}

class _LeadingButton extends StatelessWidget {
  final dynamic zoomDrawer;

  const _LeadingButton({required this.zoomDrawer});

  @override
  Widget build(BuildContext context) {
    final isDrawer = zoomDrawer != null;

    return Semantics(
      button: true,
      label: isDrawer ? 'Abrir menú' : 'Volver',
      child: InkWell(
        onTap: () {
          if (isDrawer) {
            zoomDrawer.toggle();
          } else {
            Navigator.of(context).maybePop();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isDrawer ? Icons.menu : Icons.arrow_back,
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
