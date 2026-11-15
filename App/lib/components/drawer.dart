import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'drawer_menu.dart';
import '../ui/themes/colors.dart';

class MenuZoom extends StatelessWidget {
  final Widget mainScreen;

  const MenuZoom({
    super.key,
    required this.mainScreen,
  });

  @override
  Widget build(BuildContext context) {
    return ZoomDrawer(
      style: DrawerStyle.Style1,
      angle: 0.0,
      mainScreen: mainScreen,
      menuScreen: const DrawerMenu(),

      borderRadius: 28, // menos exagerado
      showShadow: true,

      backgroundColor: AppColors.darkBlue,

      slideWidth: MediaQuery.of(context).size.width * 0.75,

      openCurve: Curves.easeOutCubic,
      closeCurve: Curves.easeInCubic,

      duration: const Duration(milliseconds: 500),
    );
  }
}