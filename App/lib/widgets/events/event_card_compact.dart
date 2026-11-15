import 'package:flutter/material.dart';

import '../../models/event_model.dart';
import '../../ui/themes/colors.dart';
import '../common/network_image_with_loader.dart';

class EventCardCompact extends StatelessWidget {
  final EventModel event;
  final String? imageUrl;
  final VoidCallback? onTap;

  const EventCardCompact({
    super.key,
    required this.event,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      height: 100,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Row(
            children: [

              /// 🔥 ACENTO (morado para eventos)
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
              ),

              /// 🖼️ IMAGEN
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: NetworkImageWithLoader(
                  imageUrl: imageUrl,
                  width: 90,
                  height: double.infinity,
                ),
              ),

              /// 📦 CONTENIDO
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        event.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        "Evento",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const Spacer(),

                      const Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            "Ver detalles",
                            style: TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}