import 'package:flutter/material.dart';
import '../../ui/themes/colors.dart';

class AppTabs extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final List<Widget> children;

  const AppTabs({
    super.key,
    required this.controller,
    required this.tabs,
    required this.children,
  }) : assert(tabs.length == children.length);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        TabBar(
          controller: controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.darkBlue,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.darkBlue,
          tabs: tabs.map((t) => Tab(text: t)).toList(),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: children,
          ),
        ),
      ],
    );
  }
}
