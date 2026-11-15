import 'package:flutter/material.dart';

import '../../controllers/boost/boost_controller.dart';
import '../../controllers/boost/boost_navigation.dart';
import '../../ui/themes/colors.dart';
import '../common/empty/app_empty.dart';
import 'boosts_carousel.dart';

class BoostsSection extends StatelessWidget {
  final BoostController controller;
  final PageController pageController;

  const BoostsSection({
    super.key,
    required this.controller,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    final navigation = BoostNavigation(
      businessService: controller.businessService,
      eventService: controller.eventService,
      touristPlaceService: controller.touristPlaceService,
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.loading) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 300,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (controller.activeBoosts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppEmptyState(
              icon: Icons.campaign_outlined,
              title: 'Sin boosts por ahora',
              subtitle:
              'Vuelva más tarde para descubrir nuevos destacados.',
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Lugares destacados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
              child: Text(
                'Promociones activas que vale la pena mirar.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
              ),
            ),

            const SizedBox(height: 8),

            BoostsCarousel(
              title: '',
              boosts: controller.activeBoosts,
              controller: pageController,
              boostController: controller,
              onTap: (context, boost) {
                navigation.open(context, boost);
              },
            ),
          ],
        );
      },
    );
  }
}