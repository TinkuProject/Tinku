import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../components/utils.dart';
import '../../../controllers/certification/certification_form_controller.dart';
import '../../../models/certification_model.dart';
import '../../../providers/user_provider.dart';
import '../../../services/certification_service.dart';
import '../../../services/media_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/common/loaders/app_loader.dart';
import '../../../widgets/common/navigation/custom_app_bar.dart';
import '../../../ui/themes/colors.dart';

class CertificationFormPage extends StatefulWidget {
  final int businessId;
  final CertificationModel? certification;

  const CertificationFormPage({
    super.key,
    required this.businessId,
    this.certification,
  });

  @override
  State<CertificationFormPage> createState() => _CertificationFormPageState();
}

class _CertificationFormPageState extends State<CertificationFormPage> {
  late CertificationFormController c;
  bool _initialized = false;

  bool get editing => widget.certification != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final auth = context.read<UserProvider>().authService;

    c = CertificationFormController(
      CertificationService(auth),
      StorageService(auth),
      MediaService(auth),
    );

    c.addListener(_rebuild);

    Future.microtask(() async {
      await c.init(certification: widget.certification);
    });

    _initialized = true;
  }

  @override
  void dispose() {
    c.removeListener(_rebuild);
    c.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  InputDecoration _dec({
    required String label,
    IconData? icon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: AppColors.darkBlue, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    );
  }

  Future<void> _pickPdf() async {
    final picked = await c.pickPdf();

    if (!mounted || !picked) return;

    ScaffoldMessenger.of(context).showSnackBar(
      tinkuSnackBar('PDF seleccionado'),
    );
  }

  Future<void> _submit() async {
    final valid = c.formKey.currentState?.validate() ?? false;
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar('Completa los campos requeridos', isError: true),
      );
      return;
    }

    final error = await c.submit(
      businessId: widget.businessId,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar(error, isError: true),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      tinkuSnackBar(
        c.editing
            ? 'Certificación actualizada con éxito'
            : 'Certificación guardada con éxito',
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: editing ? 'Editar Certificación' : 'Agregar Certificación',
      ),
      backgroundColor: Colors.grey.shade100,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Form(
                  key: c.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildNameField(),
                      const SizedBox(height: 12),
                      _buildLicenseField(),
                      const SizedBox(height: 16),
                      _buildDocumentSection(),
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (c.loading)
            AppLoader(
              message: editing
                  ? 'Cargando certificación...'
                  : 'Cargando formulario...',
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFEFF4FF),
          child: Icon(
            Icons.verified_rounded,
            color: AppColors.darkBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            editing ? 'Editar certificación' : 'Nueva certificación',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: c.nameCtrl,
      decoration: _dec(
        label: 'Nombre de la certificación',
        icon: Icons.badge_outlined,
        hintText: 'Ej. Registro sanitario, licencia municipal',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Campo requerido';
        }
        return null;
      },
    );
  }

  Widget _buildLicenseField() {
    return TextFormField(
      controller: c.licenseCtrl,
      decoration: _dec(
        label: 'Número de licencia (opcional)',
        icon: Icons.confirmation_number_outlined,
        hintText: 'Código o número de referencia',
      ),
    );
  }

  Widget _buildDocumentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.picture_as_pdf_rounded,
              color: AppColors.darkBlue,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Documento PDF',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            if (c.hasPdf)
              TextButton.icon(
                onPressed: c.clearPdf,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Quitar'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  c.pdfName ?? 'Ningún archivo seleccionado',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.hasPdf ? Colors.black87 : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: _pickPdf,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(c.hasPdf ? 'Cambiar' : 'Seleccionar'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: c.loading ? null : _submit,
        icon: const Icon(Icons.save_rounded),
        label: Text(
          editing ? 'Guardar cambios' : 'Guardar certificación',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
