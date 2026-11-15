import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/notification_model.dart';
import '../../helpers/notification_history_helper.dart';
import '../../providers/notification_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/notification_service.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late NotificationService _notificationService;
  final List<NotificationModel> _notifications = [];

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _clearingAll = false;
  bool _initialized = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  int _total = 0;
  String? _error;
  static const int _pageSize = 20;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) {
          _loadNotifications(reset: true);
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final auth = context.read<UserProvider>().authService;
    _notificationService = NotificationService(auth);

    _initialized = true;
    _loadNotifications(reset: true);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications({bool reset = false}) async {
    if (_loadingMore || (!reset && !_hasMore)) return;

    if (reset) {
      _offset = 0;
      setState(() {
        _loading = _notifications.isEmpty;
        _error = null;
      });
    } else {
      setState(() {
        _loadingMore = true;
        _error = null;
      });
    }

    try {
      final page = await _notificationService.getMinePage(
        limit: _pageSize,
        offset: _offset,
      );
      if (!mounted) return;

      setState(() {
        if (reset) _notifications.clear();
        final knownIds = _notifications.map((item) => item.id).toSet();
        _notifications.addAll(
          page.items.where((item) => knownIds.add(item.id)),
        );
        _offset = _notifications.length;
        _total = page.total;
        _hasMore = page.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
          _error = 'No se pudieron actualizar las notificaciones';
        });
      }
    }
  }

  Future<void> _refresh() async => _loadNotifications(reset: true);

  Future<void> _markAsRead(NotificationModel notif) async {
    try {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notif.id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(read: true);
        }
      });

      await _notificationService.markAsRead(notif.id);
      if (mounted) {
        context.read<NotificationProvider>().decreaseUnread();
      }

      if (!mounted) return;
    } catch (_) {}
  }

  String _relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 10) return 'Justo ahora';
    if (diff.inMinutes < 1) return 'Hace ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';

    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  IconData _pickIcon(String message) {
    final m = message.toLowerCase();
    if (m.contains('evento')) return Icons.event;
    if (m.contains('reserva')) return Icons.bookmark_added;
    if (m.contains('pago') || m.contains('compra')) {
      return Icons.payments_outlined;
    }
    if (m.contains('coment') || m.contains('reseña')) return Icons.reviews;
    if (m.contains('oferta') || m.contains('promo')) {
      return Icons.local_offer_outlined;
    }
    if (m.contains('negocio') || m.contains('servicio')) {
      return Icons.storefront_outlined;
    }
    return Icons.notifications;
  }

  Color _softBgForIcon(IconData icon) {
    if (icon == Icons.event) return Colors.indigo.shade50;
    if (icon == Icons.bookmark_added) return Colors.teal.shade50;
    if (icon == Icons.payments_outlined) return Colors.amber.shade50;
    if (icon == Icons.reviews) return Colors.purple.shade50;
    if (icon == Icons.local_offer_outlined) return Colors.pink.shade50;
    return Colors.blue.shade50;
  }

  Future<void> _deleteOne(int id) async {
    final removed = _notifications.firstWhere((n) => n.id == id);

    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });

    try {
      await _notificationService.deleteNotification(id);
      if (!mounted) return;
      if (!removed.read) {
        context.read<NotificationProvider>().decreaseUnread();
      }
    } catch (_) {}
  }

  Future<void> _deleteAll(List<NotificationModel> list) async {
    if (_clearingAll) return;

    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Borrar todas'),
        content: const Text(
          '¿Seguro que quieres eliminar todas las notificaciones?',
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => navigator.pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _clearingAll = true);

    try {
      await _notificationService.deleteAllNotifications();
    } catch (_) {
      if (mounted) setState(() => _clearingAll = false);
      return;
    }

    if (!mounted) return;

    setState(() {
      _clearingAll = false;
      _notifications.clear();
    });
    context.read<NotificationProvider>().reset();
  }

  @override
  Widget build(BuildContext context) {
    final all = _notifications;

    final filtered = _query.isEmpty
        ? all
        : all.where((n) {
            final text = '${n.title ?? ''} ${n.message}'.toLowerCase();
            return text.contains(_query);
          }).toList();

    final unreadCount = all.where((n) => !n.read).length;

    final role = context.watch<UserProvider>().user?.role;
    final Map<NotificationHistorySection, List<NotificationModel>> groups = {};
    for (final n in filtered) {
      final section = NotificationHistoryHelper.sectionFor(n.createdAt);
      groups.putIfAbsent(section, () => []).add(n);
    }

    const order = NotificationHistorySection.values;
    final sections = order.where(groups.containsKey).toList();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Notificaciones'),
      body: _loading
          ? const AppLoader(message: 'Cargando notificaciones...')
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      children: [
                        _HeroHeader(
                          total: _total,
                          unreadCount: unreadCount,
                          onClearAll: () => _deleteAll(all),
                          clearing: _clearingAll,
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(height: 32),
                        _EmptyState(
                          title: _query.isEmpty
                              ? 'No hay notificaciones'
                              : 'Sin resultados',
                          subtitle: _query.isEmpty
                              ? 'Cuando tengas actividad, aparecerá aquí.'
                              : 'Prueba buscar con otras palabras.',
                          onRefresh: _refresh,
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      children: [
                        _HeroHeader(
                          total: _total,
                          unreadCount: unreadCount,
                          onClearAll: () => _deleteAll(all),
                          clearing: _clearingAll,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchCtrl,
                          onChanged: (value) => setState(
                            () => _query = value.trim().toLowerCase(),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Buscar notificaciones',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Limpiar búsqueda',
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _query = '');
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final section in sections) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                            child: Text(
                              section.label,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .2,
                              ),
                            ),
                          ),
                          for (final n in groups[section]!)
                            _NotificationTile(
                              notif: n,
                              relativeTime: _relativeTime(n.createdAt),
                              icon: _pickIcon(n.message),
                              softBg: _softBgForIcon(_pickIcon(n.message)),
                              onDelete: () => _deleteOne(n.id),
                              onRead: () => _markAsRead(n),
                              action: role == null
                                  ? null
                                  : NotificationHistoryHelper.actionFor(
                                      n,
                                      role,
                                    ),
                              onAction: (action) async {
                                if (!n.read) await _markAsRead(n);
                                if (!context.mounted) return;
                                Navigator.pushNamed(context, action.route);
                              },
                            ),
                        ],
                        if (_hasMore || _error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: _loadingMore
                                  ? const CircularProgressIndicator()
                                  : TextButton(
                                      onPressed: () => _loadNotifications(),
                                      child: Text(
                                        _error == null
                                            ? 'Cargar más'
                                            : 'Reintentar',
                                      ),
                                    ),
                            ),
                          ),
                      ],
                    ),
            ),
    );
  }
}

/* ---------- Widgets de UI ---------- */

class _HeroHeader extends StatelessWidget {
  final int total;
  final int unreadCount;
  final VoidCallback? onClearAll;
  final bool clearing;

  const _HeroHeader({
    required this.total,
    required this.unreadCount,
    required this.onClearAll,
    required this.clearing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppColors.darkBlue, AppColors.mediumBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: _circle(110, Colors.white.withValues(alpha: .08)),
          ),
          Positioned(
            left: -16,
            bottom: -16,
            child: _circle(90, Colors.white.withValues(alpha: .06)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$unreadCount notificaciones sin leer',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: .6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: (onClearAll == null || clearing || total == 0)
                      ? null
                      : onClearAll,
                  icon: clearing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Borrar todo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notif;
  final String relativeTime;
  final IconData icon;
  final Color softBg;
  final VoidCallback onDelete;
  final VoidCallback onRead;
  final NotificationDirectAction? action;
  final ValueChanged<NotificationDirectAction> onAction;

  const _NotificationTile({
    required this.notif,
    required this.relativeTime,
    required this.icon,
    required this.softBg,
    required this.onDelete,
    required this.onRead,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notif.read;

    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.redAccent),
      ),
      onDismissed: (_) => onDelete(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.grey.shade100 : Colors.lightBlue.shade50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(icon, color: AppColors.darkBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notif.title?.trim().isNotEmpty == true) ...[
                        Text(
                          notif.title!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        notif.message,
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight:
                              isRead ? FontWeight.w500 : FontWeight.w700,
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        relativeTime,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontStyle:
                              isRead ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: isRead ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.fiber_manual_record,
                    color: Colors.blueAccent,
                    size: 10,
                  ),
                ),
              ],
            ),
            if (!isRead || action != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (action != null)
                      TextButton.icon(
                        onPressed: () => onAction(action!),
                        icon: Icon(action!.icon, size: 18),
                        label: Text(action!.label),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.darkBlue,
                        ),
                      ),
                    if (!isRead)
                      TextButton(
                        onPressed: onRead,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.darkBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 28),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Marcar como leído'),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final Future<void> Function() onRefresh;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.notifications_none, size: 56, color: Colors.grey.shade500),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Actualizar'),
        ),
      ],
    );
  }
}
