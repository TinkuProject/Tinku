import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

void showPartnerNotificationOverlay({
  required String message,
  IconData icon = Icons.notifications,
}) {
  showSimpleNotification(
    Text(
      message,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
    leading: Icon(icon, color: Colors.white),
    background: Colors.blueAccent,
    duration: const Duration(seconds: 5),
    position: NotificationPosition.top,
    slideDismissDirection: DismissDirection.up,
  );
}