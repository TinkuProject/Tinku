import 'package:flutter/material.dart';

import '../../models/event_model.dart';
import '../../ui/themes/colors.dart';
import '../../utils/date/date_formatter.dart';
import '../common/overlay_chip.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final String? imageUrl;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );

    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.white70,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            /// 🖼️ IMAGE
            Positioned.fill(
              child: imageUrl != null
                  ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
                  : _placeholder(),
            ),

            /// 🌑 OVERLAY
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.textPrimary.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            /// 📅 DATE BADGE (reutilizable)
            Positioned(
              top: 12,
              left: 12,
              child: OverlayChip(
                icon: Icons.calendar_today,
                text: DateFormatter.eventRange(
                  event.startDate,
                  event.endDate,
                ),
              ),
            ),

            /// 📍 INFO
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons.place,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: subtitleStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// 👇 TOUCH
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor:
                  Colors.white.withValues(alpha: 0.2),
                  highlightColor:
                  Colors.white.withValues(alpha: 0.1),
                  onTap: onTap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// =========================
  /// PLACEHOLDER
  /// =========================
  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceSoft,
      alignment: Alignment.center,
      child: Icon(
        Icons.image,
        size: 40,
        color: AppColors.textSecondary.withValues(alpha: 0.5),
      ),
    );
  }
}