import 'package:flutter/material.dart';

class TransportLegend extends StatelessWidget {
  const TransportLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendText("Color fuerte = ida"),
        SizedBox(width: 16),
        _LegendText("Color suave = vuelta"),
      ],
    );
  }
}

class _LegendText extends StatelessWidget {
  final String text;

  const _LegendText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: Colors.black54,
      ),
    );
  }
}