import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../controllers/event/event_form_controller.dart';
import '../../../controllers/business/location_controller.dart';
import '../../../controllers/shared/notification/notification_controller.dart';
import '../../../components/utils.dart';

import '../../common/form/app_form_section.dart';
import '../../shared/media/media_picker_section.dart';
import '../../shared/media/media_hero.dart';
import '../../shared/location/location_picker_section.dart';
import '../../common/actions/submit_button.dart';

import 'event_text_fields_section.dart';
import 'event_category_field.dart';
import 'event_business_field.dart';
import 'event_date_section.dart';

class EventFormLayout extends StatelessWidget {
  final EventFormController c;
  final LocationController locC;
  final NotificationController notifC;
  final GlobalKey<FormState> formKey;
  final bool isEdit;
  final int? eventId;
  final bool mapError;
  final Function(bool) setMapError;

  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  const EventFormLayout({
    super.key,
    required this.c,
    required this.locC,
    required this.notifC,
    required this.formKey,
    required this.isEdit,
    required this.eventId,
    required this.mapError,
    required this.setMapError,

    required this.onPickStart,
    required this.onPickEnd,
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
              child: Column(
              children: [
                EventTextFieldsSection(controller: c),
                const SizedBox(height: 12),
                EventCategoryField(controller: c),
                const SizedBox(height: 12),
                EventBusinessField(controller: c),
              ],
            )
          ),

          AppFormSection(
            title: "Fechas *",
            child: EventDateSection(
              start: c.startAt,
              end: c.endAt,
              onPickStart: onPickStart,
              onPickEnd: onPickEnd,
            )
          ),

          AppFormSection(
            title: "Ubicación *",
            child: Column(
              children: [
                LocationPickerSection(
                  locC: locC,
                  defaultCenter: const LatLng(-17.3936, -66.1570),
                  polylines: c.transportC.polylines,
                  mapError: mapError,
                  onTap: (pos) async {
                    await locC.onTap(pos);
                    setMapError(false);
                  },
                ),
              ],
            )
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
            text: isEdit ? "Guardar Cambios" : "Crear Evento",
            onPressed: () async {
              if (locC.selected == null) {
                setMapError(true);
                ScaffoldMessenger.of(context).showSnackBar(
                  tinkuSnackBar("Seleccione una ubicación.", isError: true),
                );
                return;
              }

              final res = await c.submit(
                context: context,
                formKey: formKey,
                address: locC.address,
                lat: locC.selected!.latitude,
                lng: locC.selected!.longitude,
                editing: isEdit,
                eventId: eventId,
              );

              if (!context.mounted) return;

              ScaffoldMessenger.of(context)
                  .showSnackBar(tinkuSnackBar(res.message, isError: !res.ok));

              if (res.ok) Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );
  }
}
