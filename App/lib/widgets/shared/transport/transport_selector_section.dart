import 'package:flutter/material.dart';
import '../../../utils/transport/transport_line_color_manager.dart';

class TransportSelectorSection extends StatelessWidget {
  final Map<String, String> lines;
  final List<String> selected;
  final void Function(String) onToggle;

  const TransportSelectorSection({
    super.key,
    required this.lines,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Selecciona líneas de transporte",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width > 400 ? 3 : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lines.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 3.2,
              ),
              itemBuilder: (_, i) {
                final entry = lines.entries.elementAt(i);
                final id = int.parse(entry.key);
                final isSelected = selected.contains(entry.key);
                final color =
                TransportLineColorManager.getBaseColor(id);

                return GestureDetector(
                  onTap: () => onToggle(entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? color.withValues(alpha: 0.25)
                          : color.withValues(alpha: 0.08),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 20,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.value,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}