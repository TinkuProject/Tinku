import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/utils.dart';
import '../providers/user_provider.dart';
import '../services/business_claim_request_service.dart';

Future<void> openClaimDocument(
    BuildContext context, int claimId, int index) async {
  try {
    final service =
        BusinessClaimRequestService(context.read<UserProvider>().authService);
    final claim = await service.getById(claimId);
    if (claim == null || index < 0 || index >= claim.documents.length) {
      throw StateError('Document not found');
    }
    final uri = Uri.parse(claim.documents[index]);
    if (uri.scheme != 'https') throw StateError('Invalid document URL');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('Document unavailable');
    }
  } catch (_) {
    showSnackbar('No se pudo abrir el documento. Intenta nuevamente.',
        isError: true);
  }
}
