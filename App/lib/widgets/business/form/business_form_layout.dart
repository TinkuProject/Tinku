import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../controllers/business/business_form_controller.dart';
import '../../../controllers/business/location_controller.dart';
import '../../common/form/app_form_section.dart';
import '../../schedule/weekly_hours_input.dart';
import '../../common/actions/submit_button.dart';
import '../../shared/location/location_picker_section.dart';
import '../../shared/media/media_picker_section.dart';
import '../../shared/media/media_hero.dart';
import '../../shared/social/social_links_section.dart';
import 'business_category_section.dart';
import 'business_text_fields_section.dart';

class BusinessFormLayout extends StatelessWidget {
  final BusinessFormController c;
  final LocationController locC;
  final GlobalKey<FormState> formKey;
  final Future<void> Function() onSubmit;

  const BusinessFormLayout({
    super.key,
    required this.c,
    required this.locC,
    required this.formKey,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          MediaHero(images: c.media.items),
          const SizedBox(height: 20),

          AppFormSection(
              title: "Información básica",
              child: Column(children: [
            BusinessTextFieldsSection(c: c),
            const SizedBox(height: 12),
            BusinessCategorySection(c: c),
          ])),

          AppFormSection(
            title: "Ubicación *",
            child: Column(
              children: [
                LocationPickerSection(
                  locC: locC,
                  defaultCenter: const LatLng(-17.39, -66.15),
                  polylines: c.transport.polylines,
                  mapError: false,
                  onTap: (pos) => locC.onTap(pos),
                ),
              ],
            ),
          ),

          AppFormSection(
            title: "Redes sociales",
            child: SocialLinksSection(c: c.socials),
          ),

          AppFormSection(
            title: "Horarios *",
            child: WeeklyHoursInput(controller: c.hours),
          ),

          AppFormSection(
            title: "Imágenes",
            child: MediaPickerSection(
              images: c.media.items,
              onAdd: () => c.media.pickFiles(context),
              onRemove: c.media.removeItem,
            ),
          ),

          const SizedBox(height: 30),

          SubmitButton(
            loading: c.loading,
            text: "Guardar",
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}
