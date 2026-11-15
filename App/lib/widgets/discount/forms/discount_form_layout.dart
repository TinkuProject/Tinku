import 'package:flutter/material.dart';

import '../../../controllers/discount/discount_form_controller.dart';
import '../../../ui/themes/colors.dart';
import '../../common/actions/submit_button.dart';
import '../../common/form/app_form_section.dart';
import '../../common/form/app_date_field.dart';
import '../../common/form/app_text_field.dart';
import '../../shared/media/media_hero.dart';
import '../../shared/media/media_picker_section.dart';

class DiscountFormLayout extends StatelessWidget {
  final DiscountFormController c;
  final Future<void> Function() onSubmit;

  const DiscountFormLayout({
    super.key,
    required this.c,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: c.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          children: [
            MediaHero(images: c.mediaController.items),
            const SizedBox(height: 20),

            AppFormSection(
              title: "Información básica",
              child: Column(
                children: [
                  AppTextField(
                    label: "Descripción",
                    controller: c.descriptionCtrl,
                    maxLines: 3,
                    hint: "Escribe una descripción",
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Campo requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: "Descuento",
                    controller: c.percentCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    hint: "0 - 100",
                    validator: (v) {
                      final d = double.tryParse(
                        (v ?? '').replaceAll(',', '.'),
                      );

                      if (d == null) {
                        return 'Valor inválido';
                      }

                      if (d < 0 || d > 100) {
                        return 'Debe estar entre 0 y 100';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),

            AppFormSection(
              title: "Fechas",
              child: Column(
                children: [
                  AppDateField(
                    label: "Inicio",
                    value: c.startDate == null
                        ? null
                        : '${c.startDate!.day.toString().padLeft(2, '0')}/'
                        '${c.startDate!.month.toString().padLeft(2, '0')}/'
                        '${c.startDate!.year}',
                    icon: Icons.event_available,
                    onTap: () => c.pickStartDate(context),
                  ),
                  const SizedBox(height: 12),
                  AppDateField(
                    label: "Fin",
                    value: c.endDate == null
                        ? null
                        : '${c.endDate!.day.toString().padLeft(2, '0')}/'
                        '${c.endDate!.month.toString().padLeft(2, '0')}/'
                        '${c.endDate!.year}',
                    icon: Icons.event_busy,
                    onTap: () => c.pickEndDate(context),
                  ),
                ],
              ),
            ),

            if (!c.editing)
              AppFormSection(
                title: "Costo de publicación",
                child: _DiscountCostNotice(c: c),
              ),

            if (c.editing)
              AppFormSection(
                title: "Estado",
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: c.active,
                  onChanged: c.setActive,
                  title: const Text("Activo"),
                ),
              ),

            AppFormSection(
              title: "Imágenes",
              child: MediaPickerSection(
                images: c.mediaController.items,
                onAdd: () => c.pickImages(context),
                onRemove: c.mediaController.removeItem,
              ),
            ),

            const SizedBox(height: 24),

            SubmitButton(
              loading: c.loading,
              text: c.editing ? "Guardar cambios" : "Crear promoción",
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscountCostNotice extends StatelessWidget {
  const _DiscountCostNotice({required this.c});

  final DiscountFormController c;

  @override
  Widget build(BuildContext context) {
    final days = c.selectedDays;
    final cost = c.estimatedCreateCost;
    final hasDates = days > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.darkBlue.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.darkBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: AppColors.darkBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Cobro en Tinkus",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasDates
                      ? "$days días x ${c.createCostPerDay.toStringAsFixed(0)} T = ${cost.toStringAsFixed(0)} T"
                      : "Selecciona las fechas para calcular el costo.",
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                if (hasDates) ...[
                  const SizedBox(height: 6),
                  const Text(
                    "Este monto se descontará de tu monedero al crear la promoción.",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
