import 'package:flutter/material.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  static const String _contactEmail = 'soporte@tinku.app';

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  int _topicIndex = 0; // 0=Todos

  final List<String> _topics = const [
    'Todos',
    'Explorar',
    'Negocios',
    'Eventos',
    'Marketplace',
    'Transporte',
    'Cuenta',
    'Pagos',
    'Soporte',
  ];

  final List<_Faq> _faqs = const [
    _Faq(
      q: '¿Cómo filtro lugares en Explorar?',
      a: 'En Explorar puedes cambiar entre Todos, Negocios, Lugares, Eventos y Servicios. Luego usa los chips de categoría o el buscador; la lista y el mapa se actualizan con esos filtros.',
      topic: 'Explorar',
    ),
    _Faq(
      q: '¿Puedo guardar favoritos?',
      a: 'Puedes guardar negocios y lugares turísticos como favoritos. También puedes llevar un registro de lugares visitados.',
      topic: 'Explorar',
    ),
    _Faq(
      q: '¿Dónde veo rutas y líneas de transporte?',
      a: 'En Rutas y líneas puedes buscar líneas activas, seleccionar una o varias y ver sus recorridos, paradas, ida y vuelta en el mapa.',
      topic: 'Transporte',
    ),
    _Faq(
      q: '¿Qué muestra el mapa de recarga y almacenes?',
      a: 'Muestra puntos de recarga activos y almacenes disponibles. Cada tipo tiene un marcador distinto y puedes abrir el detalle para ver dirección o cómo llegar.',
      topic: 'Pagos',
    ),
    _Faq(
      q: '¿Puedo dejar reseñas?',
      a: 'Sí. En negocios puedes calificar y comentar. En eventos, solo pueden reseñar quienes tengan una reserva confirmada.',
      topic: 'Negocios',
    ),
    _Faq(
      q: '¿Cómo reservo un cupo en un evento?',
      a: 'En el detalle del evento toca reservar. Si el evento requiere tinkus, el cobro se procesa automáticamente y la reserva queda confirmada si tienes saldo y hay cupo.',
      topic: 'Eventos',
    ),
    _Faq(
      q: '¿Cómo funciona el QR de asistencia?',
      a: 'Cuando tu reserva está confirmada, puedes generar un QR para el día vigente del evento. El organizador lo valida desde la cámara en la sección de asistentes.',
      topic: 'Eventos',
    ),
    _Faq(
      q: '¿Dónde veo mis eventos?',
      a: 'En Calendario aparecen los eventos que organizas y aquellos a los que asistirás. También puedes revisar eventos anteriores.',
      topic: 'Eventos',
    ),
    _Faq(
      q: '¿Qué puedo hacer como organizador o negocio?',
      a: 'Puedes administrar negocios, servicios, eventos, impulsos, promociones, productos, certificaciones, ventas y almacenes desde Gestionar Servicios.',
      topic: 'Negocios',
    ),
    _Faq(
      q: '¿Cómo funcionan las ventas en Marketplace?',
      a: 'Los socios publican productos activos y pagan la publicación con Tinkus según stock y precio. Si aumentan la publicación, se cobra solo el adicional; si reducen stock, no se devuelve el monto ya invertido.',
      topic: 'Marketplace',
    ),
    _Faq(
      q: '¿Cómo busco productos en Marketplace?',
      a: 'Busca por producto o negocio y usa Filtros para elegir disponibilidad, volumen, rango de precio en Tinkus y orden. Puedes limpiar los filtros cuando quieras.',
      topic: 'Marketplace',
    ),
    _Faq(
      q: '¿Cómo pago y retiro una compra?',
      a: 'Los productos del Marketplace se pagan con Tinkus. Antes de confirmar eliges retiro en tienda o en un almacén disponible. Revisa Mis compras para seguir el estado del pedido y presentar su QR o código de retiro cuando esté listo.',
      topic: 'Marketplace',
    ),
    _Faq(
      q: '¿Puedo comprar mis propios productos?',
      a: 'No. Tinku bloquea la compra de productos publicados por tus propios negocios para evitar movimientos incorrectos.',
      topic: 'Marketplace',
    ),
    _Faq(
      q: '¿Para qué sirven los almacenes?',
      a: 'Los almacenes son puntos de retiro asociados al Marketplace. Un socio puede solicitar uno; queda pendiente hasta que lo apruebe un administrador. El dueño del almacén gestiona solicitudes, inventario, ubicaciones físicas y entregas.',
      topic: 'Marketplace',
    ),
    _Faq(
      q: '¿Cómo llegan mis productos a un almacén?',
      a: 'Desde Almacenes solicitas enviar productos a un almacén asociado. El almacén acepta la solicitud y el negocio confirma el envío. El personal del almacén registra la recepción y gestiona el inventario y las entregas.',
      topic: 'Marketplace',
    ),
    _Faq(
      q: '¿Cómo configuro retiro o entrega para mis productos?',
      a: 'Desde Almacenes puedes configurar si un negocio permite retiro en tienda o entrega por almacén. De momento esa configuración aplica al negocio completo.',
      topic: 'Marketplace',
    ),
    _Faq(
      q: '¿Puedo responder reseñas de mis negocios?',
      a: 'Sí. En Gestionar reseñas puedes ver los comentarios de tus negocios y eventos y responderlos. No puedes borrar ni calificar las reseñas de otras personas.',
      topic: 'Negocios',
    ),
    _Faq(
      q: '¿Cómo reclamo un negocio sin dueño?',
      a: 'Si eres socio, entra a Reclamar negocio, elige un negocio sin propietario y adjunta documentación que acredite tu vínculo. Puedes consultar el estado e historial de tus reclamos.',
      topic: 'Negocios',
    ),
    _Faq(
      q: '¿Para qué sirve la billetera?',
      a: 'La billetera permite comprar tinkus, revisar movimientos, pagar reservas o solicitudes y gestionar actividad financiera dentro de la app.',
      topic: 'Pagos',
    ),
    _Faq(
      q: '¿Qué formas de pago existen?',
      a: 'Puedes pagar con tarjeta mediante Stripe cuando esté disponible para el paquete, o usar pago con QR si el paquete tiene un QR configurado.',
      topic: 'Pagos',
    ),
    _Faq(
      q: '¿Cómo recupero mi cuenta?',
      a: 'En “Iniciar sesión”, toca “¿Olvidaste tu contraseña?” y sigue las instrucciones del correo.',
      topic: 'Cuenta',
    ),
    _Faq(
      q: '¿Dónde reporto un error?',
      a: 'Escríbenos a soporte@tinku.app con capturas y pasos para replicarlo. Te responderemos pronto.',
      topic: 'Soporte',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
        () => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Faq> _filteredFaqs() {
    Iterable<_Faq> list = _faqs;

    if (_topicIndex != 0) {
      list = list.where((f) => f.topic == _topics[_topicIndex]);
    }
    if (_query.isNotEmpty) {
      list = list.where((f) =>
          f.q.toLowerCase().contains(_query) ||
          f.a.toLowerCase().contains(_query));
    }
    return list.toList();
  }

  Map<String, List<_Faq>> _groupFaqsByTopic(List<_Faq> faqs) {
    final grouped = <String, List<_Faq>>{};

    for (final topic in _topics.where((t) => t != 'Todos')) {
      final items = faqs.where((f) => f.topic == topic).toList();
      if (items.isNotEmpty) grouped[topic] = items;
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final faqs = _filteredFaqs();

    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: const CustomAppBar(title: 'Ayuda'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          // HERO
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [AppColors.darkBlue, AppColors.mediumBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: .08),
                    blurRadius: 14,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -24,
                  top: -24,
                  child: _circle(130, Colors.white.withValues(alpha: .08)),
                ),
                Positioned(
                  left: -20,
                  bottom: -20,
                  child: _circle(100, Colors.white.withValues(alpha: .06)),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.help_outline,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('¿Necesitas ayuda?',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800)),
                            SizedBox(height: 6),
                            Text(
                              'Encuentra respuestas rápidas o contáctanos para soporte personalizado.',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Buscador
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar en preguntas y respuestas',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
            ),
          ),

          const SizedBox(height: 12),

          // Chips de tema
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_topics.length, (i) {
                final selected = _topicIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_topics[i]),
                    selected: selected,
                    onSelected: (_) => setState(() => _topicIndex = i),
                    selectedColor: AppColors.mediumBlue.withValues(alpha: .20),
                    labelStyle: TextStyle(
                      color: selected ? AppColors.darkBlue : Colors.black87,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 14),

          // Lista de FAQs
          if (faqs.isEmpty)
            _SectionCard(
              child: Row(
                children: [
                  Icon(Icons.search_off, color: Colors.grey.shade600),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'No encontramos resultados. Intenta con otras palabras o cambia el tema.',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            )
          else if (_topicIndex == 0)
            ..._groupFaqsByTopic(faqs).entries.expand(
                  (entry) => [
                    _HelpSectionHeader(entry.key),
                    ...entry.value.map((f) => _FaqTile(faq: f)),
                  ],
                )
          else
            ...faqs.map((f) => _FaqTile(faq: f)),

          const SizedBox(height: 18),

          Center(
            child: Text(
              '¿Aún con dudas? Escríbenos: $_contactEmail',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }
}

class _HelpSectionHeader extends StatelessWidget {
  const _HelpSectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final _Faq faq;
  const _FaqTile({required this.faq});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          collapsedIconColor: AppColors.darkBlue,
          iconColor: AppColors.darkBlue,
          initiallyExpanded: false,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          title: Text(
            widget.faq.q,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: _expanded ? AppColors.darkBlue : Colors.black87,
            ),
          ),
          children: [
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.faq.a,
                  style: const TextStyle(fontSize: 15, height: 1.35)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 12,
              offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

class _Faq {
  final String q;
  final String a;
  final String topic;
  const _Faq({required this.q, required this.a, required this.topic});
}
