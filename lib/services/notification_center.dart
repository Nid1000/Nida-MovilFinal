import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'backend_notification_service.dart';
import 'local_notification_service.dart';

class NotificationCenter {
  NotificationCenter._();

  static final NotificationCenter instance = NotificationCenter._();

  static const _seenIdsKey = 'seenNotificationIds';
  static const _maxSeenIds = 250;

  final BackendNotificationService _backend = BackendNotificationService();
  final StreamController<List<BackendNotificationItem>> _inboxController =
      StreamController<List<BackendNotificationItem>>.broadcast();

  Timer? _timer;
  bool _initialized = false;
  bool _running = false;

  final List<BackendNotificationItem> _inbox = [];
  final Set<int> _seenIds = <int>{};

  Stream<List<BackendNotificationItem>> get inboxStream =>
      _inboxController.stream;
  List<BackendNotificationItem> get inbox => List.unmodifiable(_inbox);

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_seenIdsKey) ?? const <String>[];
    for (final raw in stored) {
      final id = int.tryParse(raw);
      if (id != null && id > 0) _seenIds.add(id);
    }
    _initialized = true;
  }

  void start({Duration interval = const Duration(seconds: 20)}) {
    if (_running) return;
    _running = true;
    unawaited(init().then((_) => refresh()));
    _timer = Timer.periodic(interval, (_) => refresh());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  Future<void> refresh() async {
    await init();

    final items = await _backend.fetchPending();
    if (items.isEmpty) return;

    final newItems = <BackendNotificationItem>[];
    for (final item in items) {
      if (_seenIds.contains(item.id)) continue;
      _seenIds.add(item.id);
      newItems.add(item);
    }

    if (newItems.isEmpty) return;

    _inbox.insertAll(0, newItems);
    _emitInbox();

    for (final item in newItems) {
      await LocalNotificationService.instance.show(
        title: item.title,
        body: item.body,
        payload: jsonEncode({'route': item.route, 'targetId': item.targetId}),
      );
    }

    await _persistSeenIds();

    // Best-effort: if the backend supports marking as shown (with/without auth).
    try {
      await _backend.markShown(newItems.map((item) => item.id).toList());
    } catch (_) {
      // Ignore.
    }
  }

  void dismiss(int id) {
    _inbox.removeWhere((item) => item.id == id);
    _emitInbox();
  }

  Future<void> _persistSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = _seenIds.toList()..sort();
    final trimmed = ids.length > _maxSeenIds
        ? ids.sublist(ids.length - _maxSeenIds)
        : ids;
    await prefs.setStringList(
      _seenIdsKey,
      trimmed.map((e) => e.toString()).toList(),
    );
  }

  void _emitInbox() {
    if (_inboxController.isClosed) return;
    _inboxController.add(List.unmodifiable(_inbox));
  }
}
