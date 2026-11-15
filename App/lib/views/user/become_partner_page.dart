import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../components/utils.dart';
import '../../config/config.dart';
import '../../core/enums.dart';
import '../../helpers/error_message_helper.dart';
import '../../models/coin_package_model.dart';
import '../../models/payment_model.dart';
import '../../models/payment_request_model.dart';
import '../../providers/user_provider.dart';
import '../../services/coin_package_service.dart';
import '../../services/media_service.dart';
import '../../services/payment_request_service.dart';
import '../../services/payment_service.dart';
import '../../services/stripe_payment_service.dart';
import '../../services/storage_service.dart';
import '../../ui/themes/colors.dart';
import '../../views/user/edit_profile.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';

class BecomePartnerPage extends StatefulWidget {
  const BecomePartnerPage({super.key});

  @override
  State<BecomePartnerPage> createState() => _BecomePartnerPageState();
}

class _BecomePartnerPageState extends State<BecomePartnerPage> {
  late CoinPackageService _coinPackageSvc;
  late PaymentService _paymentService;
  late PaymentRequestService _paymentRequestService;
  late StripePaymentService _stripePaymentService;
  late StorageService _storageSvc;
  late MediaService _mediaService;

  CoinPackageModel? pack;
  File? _proofFile;

  bool loading = true;
  bool submitting = false;
  bool _hasPendingPartnerUpgrade = false;
  bool _initialized = false;
  bool _profileDialogVisible = false;
  String? error;

  String? _qrUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final userProvider = context.watch<UserProvider>();

    if (userProvider.isLoading) return;

    if (userProvider.user == null) {
      setState(() {
        error = "Debes iniciar sesión para volverte socio.";
        loading = false;
      });
      return;
    }

    final auth = userProvider.authService;

    _coinPackageSvc = CoinPackageService(auth);
    _paymentService = PaymentService(auth);
    _paymentRequestService = PaymentRequestService(auth);
    _stripePaymentService = StripePaymentService(auth);
    _storageSvc = StorageService(auth);
    _mediaService = MediaService(auth);

    _initialized = true;

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final freshUser = await context.read<UserProvider>().refreshCurrentUser();

      if (!mounted) return;

      if (freshUser == null) {
        setState(() {
          error = "No se pudo validar tu sesión.";
          loading = false;
        });
        return;
      }

      if (freshUser.role != UserRole.user) {
        setState(() => loading = false);
        return;
      }

      if (!isProfileComplete(freshUser)) {
        setState(() => loading = false);
        _showIncompleteProfileDialog();
        return;
      }

      await Future.wait([
        loadBasicPackage(),
        _checkPendingRequest(),
      ]);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        error = "No se pudo validar tu perfil. Intenta nuevamente.";
        loading = false;
      });
    }
  }

  void _showIncompleteProfileDialog() {
    if (_profileDialogVisible) return;

    _profileDialogVisible = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Perfil incompleto"),
          content: const Text(
            "Antes de volverte socio debes completar toda tu información personal.",
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfile()),
                );
                if (!mounted) return;
                setState(() => loading = true);
                await _bootstrap();
              },
              child: const Text("Continuar"),
            ),
          ],
        ),
      );

      _profileDialogVisible = false;
    });
  }

  bool isProfileComplete(user) {
    return user.username.trim().isNotEmpty &&
        user.email.trim().isNotEmpty &&
        user.firstName?.trim().isNotEmpty == true &&
        user.lastName?.trim().isNotEmpty == true &&
        user.address?.trim().isNotEmpty == true &&
        user.phone?.trim().isNotEmpty == true &&
        user.ci?.trim().isNotEmpty == true &&
        user.latitude != null &&
        user.longitude != null;
  }

  Future<void> loadBasicPackage() async {
    try {
      final basic = await _coinPackageSvc.getBasic();

      if (basic == null) {
        if (!mounted) return;

        setState(() {
          error = "No se encontró el paquete básico.";
          loading = false;
        });

        return;
      }

      final media = await _mediaService.getByEntity(
        entityId: basic.id.toString(),
        entityType: MediaEntityType.coin_package,
      );

      String? qrUrl;

      if (media.isNotEmpty) {
        qrUrl = media.first.url; // ajustá si tu campo se llama distinto
      }

      if (!mounted) return;

      setState(() {
        pack = basic;
        _qrUrl = qrUrl;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        error = "No se pudo cargar la información de socio.";
        loading = false;
      });
    }
  }

  Future<void> _checkPendingRequest() async {
    try {
      final hasPending =
      await _paymentRequestService.hasPendingPartnerUpgrade();

      if (!mounted) return;
      setState(() {
        _hasPendingPartnerUpgrade = hasPending;
      });
    } catch (_) {
    }
  }

  Future<void> pickProof() async {
    if (submitting || _hasPendingPartnerUpgrade) return;

    final picker = ImagePicker();

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Elegir imagen desde galería"),
              onTap: () => Navigator.pop(context, "gallery"),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text("Seleccionar archivo PDF"),
              onTap: () => Navigator.pop(context, "pdf"),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    try {
      if (choice == "gallery") {
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          setState(() => _proofFile = File(picked.path));
        }
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ["pdf"],
        );

        if (result?.files.single.path != null) {
          setState(() => _proofFile = File(result!.files.single.path!));
        }
      }
    } catch (_) {
    }
  }

  Future<void> submit() async {
    if (submitting) return;

    final user = context.read<UserProvider>().user;
    final messenger = ScaffoldMessenger.of(context);

    if (user == null) return;

    final freshUser = await context.read<UserProvider>().refreshCurrentUser();

    if (freshUser == null || !isProfileComplete(freshUser)) {
      _showIncompleteProfileDialog();
      return;
    }

    if (_hasPendingPartnerUpgrade) {
      messenger.showSnackBar(
        tinkuSnackBar(
          "Ya tienes una solicitud pendiente de socio.",
          isError: true,
        ),
      );
      return;
    }

    if (_proofFile == null) {
      messenger.showSnackBar(
        tinkuSnackBar("Debes subir tu comprobante.", isError: true),
      );
      return;
    }

    if (pack == null) {
      messenger.showSnackBar(
        tinkuSnackBar("No se pudo cargar el paquete.", isError: true),
      );
      return;
    }

    try {
      setState(() => submitting = true);

      final payment = await _paymentService.createPayment(
        CreatePaymentModel(
          amount: pack!.cashAmount,
          method: PaymentMethod.qr,
          type: PaymentType.partner_upgrade,
        ),
      );

      await _storageSvc.uploadSingleFile(
        entityId: payment.id,
        entityType: MediaEntityType.payment,
        file: XFile(_proofFile!.path),
      );

      await _paymentRequestService.createRequest(
        PaymentRequestModel(
          id: 0,
          userId: user.id,
          paymentId: payment.id,
          type: PaymentType.partner_upgrade,
          status: ApprovalStatus.pending,
          createdAt: DateTime.now(),
        ),
      );

      if (!mounted) return;

      setState(() {
        submitting = false;
        _hasPendingPartnerUpgrade = true;
        _proofFile = null;
      });

      messenger.showSnackBar(
        tinkuSnackBar("Solicitud enviada correctamente"),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => submitting = false);

      messenger.showSnackBar(
        tinkuSnackBar(userFacingError(e), isError: true),
      );
    }
  }

  Future<void> submitWithStripe() async {
    if (submitting) return;

    final messenger = ScaffoldMessenger.of(context);
    final freshUser = await context.read<UserProvider>().refreshCurrentUser();

    if (freshUser == null || !isProfileComplete(freshUser)) {
      _showIncompleteProfileDialog();
      return;
    }

    if (_hasPendingPartnerUpgrade) {
      messenger.showSnackBar(
        tinkuSnackBar(
          "Ya tienes una solicitud pendiente de socio.",
          isError: true,
        ),
      );
      return;
    }

    if (pack == null) {
      messenger.showSnackBar(
        tinkuSnackBar("No se pudo cargar el paquete.", isError: true),
      );
      return;
    }

    try {
      setState(() => submitting = true);

      await _stripePaymentService.pay(
        type: PaymentType.partner_upgrade,
        merchantDisplayName: 'Tinku',
      );

      if (!mounted) return;

      setState(() {
        submitting = false;
        _hasPendingPartnerUpgrade = true;
        _proofFile = null;
      });

      messenger.showSnackBar(
        tinkuSnackBar("Pago procesado. Tu solicitud se aprobará en breve."),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => submitting = false);

      messenger.showSnackBar(
        tinkuSnackBar(userFacingError(e), isError: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: AppLoader(message: 'Cargando información de socio...'),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: const CustomAppBar(title: "Volverse socio"),
        body: Center(
          child: Text(error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final currentUser = context.watch<UserProvider>().user;
    if (currentUser != null && currentUser.role != UserRole.user) {
      final isPartner = currentUser.role == UserRole.partner;
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: const CustomAppBar(title: "Volverse socio"),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPartner
                        ? Icons.workspace_premium
                        : Icons.admin_panel_settings_outlined,
                    color: AppColors.darkBlue,
                    size: 44,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPartner
                        ? "Tu cuenta ya es socio"
                        : "Tu cuenta tiene permisos administrativos",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPartner
                        ? "Ya puedes gestionar negocios, servicios, eventos, productos y promociones desde tu perfil."
                        : "No necesitas solicitar el cambio a socio para gestionar contenido en Tinku.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Ir a mi perfil"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final stripeEnabled = Config.stripePublishableKey.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: "Volverse socio"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Beneficios de ser socio",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Al convertirte en socio obtienes acceso completo a todas las herramientas diseñadas para emprendedores y negocios dentro de Tinku:",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            _benefitItem(
              icon: Icons.person,
              title: "Gestionar servicios",
              description:
                  "Crea, administra y promociona tus servicios, negocios, eventos y promociones.",
            ),
            const SizedBox(height: 15),
            _benefitItem(
              icon: Icons.bolt,
              title: "Boosts y promociones",
              description:
                  "Accedé a herramientas de visibilidad para destacar tu negocio.",
            ),
            const SizedBox(height: 15),
            _benefitItem(
              icon: Icons.monetization_on,
              title: "Monedas y recompensas",
              description:
                  "Sistema de monedas integrado para promociones y campañas.",
            ),
            const SizedBox(height: 15),
            _benefitItem(
              icon: Icons.analytics,
              title: "Estadísticas del negocio",
              description:
                  "Métricas útiles para entender el rendimiento de tus servicios.",
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.darkBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tinku busca dar más herramientas a quienes quieren crecer su negocio.",
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  if (pack != null)
                    Text(
                      "Costo del paquete: ${pack!.cashAmount} Bs",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            if (stripeEnabled)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (!submitting && !_hasPendingPartnerUpgrade)
                      ? submitWithStripe
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.credit_card),
                  label: Text(
                    _hasPendingPartnerUpgrade
                        ? "Solicitud pendiente"
                        : submitting
                            ? "Procesando..."
                            : "Pagar con tarjeta",
                  ),
                ),
              ),

            const SizedBox(height: 18),

            if (_hasPendingPartnerUpgrade)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.35),
                  ),
                ),
                child: const Text(
                  "Ya tienes una solicitud de socio pendiente. No puedes enviar otra hasta que sea aprobada o rechazada.",
                  style: TextStyle(color: Colors.deepOrange),
                ),
              ),

            const SizedBox(height: 8),

            ExpansionTile(
              initiallyExpanded: !stripeEnabled,
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              leading: const Icon(Icons.receipt_long, color: AppColors.darkBlue),
              title: const Text(
                "Pago manual con comprobante",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                stripeEnabled
                    ? "Úsalo solo si no puedes pagar con tarjeta."
                    : "Sube tu comprobante para revisión administrativa.",
              ),
              children: [
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Código QR para el pago",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_qrUrl != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDADFE8)),
                    ),
                    child: Column(
                      children: [
                        Image.network(
                          _qrUrl!,
                          height: 220,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text(
                            "No se pudo cargar el QR.",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Usa este QR para realizar el pago del paquete.",
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  )
                else
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "No hay QR cargado para este paquete.",
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Subir comprobante",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: (submitting || _hasPendingPartnerUpgrade)
                      ? null
                      : pickProof,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDADFE8)),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.upload_file_rounded,
                          color: AppColors.darkBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _proofFile != null
                                ? _proofFile!.path.split('/').last
                                : _hasPendingPartnerUpgrade
                                    ? "Solicitud pendiente"
                                    : "Seleccionar imagen o PDF",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_proofFile != null &&
                            !submitting &&
                            !_hasPendingPartnerUpgrade)
                        ? submit
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: submitting
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : Text(
                            _hasPendingPartnerUpgrade
                                ? "Solicitud pendiente"
                                : "Enviar comprobante",
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 32, color: AppColors.darkBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ],
          ),
        )
      ],
    );
  }
}
