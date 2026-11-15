import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tinkuapp/services/reservation_service.dart';

import '../../controllers/event/my_calendar_controller.dart';
import '../../models/event_model.dart';
import '../../providers/user_provider.dart';
import '../../services/event_service.dart';
import '../../services/media_service.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';

import '../../widgets/calendar/calendar_header.dart';
import '../../widgets/calendar/calendar_widget.dart';
import '../../widgets/calendar/calendar_legend.dart';
import '../../widgets/calendar/calendar_empty_states.dart';
import '../../widgets/calendar/calendar_events_list_section.dart';
import '../../widgets/calendar/past_events_section.dart';

class MyCalendarPage extends StatefulWidget {
  const MyCalendarPage({super.key});

  @override
  State<MyCalendarPage> createState() => _MyCalendarPageState();
}

class _MyCalendarPageState extends State<MyCalendarPage> {
  late MyCalendarController c;
  bool _initialized = false;
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final userProvider = context.watch<UserProvider>();
    final userId = userProvider.user?.id;
    if (_initialized && _loadedUserId == userId) return;

    if (_initialized) {
      c.removeListener(_rebuild);
      c.reset();
      c.dispose();
    }

    final auth = userProvider.authService;

    c = MyCalendarController(
      EventService(auth),
      ReservationService(auth),
      MediaService(auth),
    )..addListener(_rebuild);

    _initialized = true;
    _loadedUserId = userId;

    _init();
  }

  Future<void> _init() async {
    await c.init();

    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    if (_initialized) {
      c.removeListener(_rebuild);
      c.dispose();
    }
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _onRefresh() async => c.refresh();

  @override
  Widget build(BuildContext context) {
    final selectedDay = c.selectedDay;
    final selectedEvents = selectedDay == null
        ? <EventModel>[]
        : c.eventsForDay(selectedDay);
    final nextEvent = selectedDay != null && selectedEvents.isEmpty
        ? c.nextEventAfter(selectedDay)
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: 'Calendario'),
      body: c.loading
          ? const AppLoader(message: 'Cargando calendario...')
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  /// 🧭 HEADER
                  SliverToBoxAdapter(
                    child: CalendarHeader(controller: c),
                  ),

                  /// 📅 CALENDARIO
                  SliverToBoxAdapter(
                    child: CalendarWidget(controller: c),
                  ),

                  /// 🎯 LEYENDA
                  const SliverToBoxAdapter(
                    child: CalendarLegend(),
                  ),

                  /// 🧠 EMPTY STATES
                  SliverToBoxAdapter(
                    child: CalendarEmptyStates(
                      controller: c,
                      eventsForSelected: selectedEvents,
                      hasUpcomingEvent: nextEvent != null,
                    ),
                  ),

                  /// 📌 LISTA DE EVENTOS
                  if (selectedEvents.isNotEmpty)
                    CalendarEventsListSection(
                      controller: c,
                      events: selectedEvents,
                    ),

                  if (nextEvent != null) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 6),
                        child: Text(
                          'Próximo evento',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    CalendarEventsListSection(
                        controller: c, events: [nextEvent]),
                  ],

                  /// ⏳ EVENTOS PASADOS
                  PastEventsSection(
                    controller: c,
                    pastEvents: c.pastEvents,
                  ),
                ],
              ),
            ),
    );
  }
}
