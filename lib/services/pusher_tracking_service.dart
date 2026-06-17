import 'dart:async';
import 'dart:convert';

import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../models/order_status_update.dart';
import 'app_config.dart';
import 'pusher_service.dart';

class PusherTrackingService {
  String? _subscribedChannel;
  StreamSubscription<PusherEvent>? _subscription;

  String get subscribedChannel => _subscribedChannel ?? '';
  String get expectedEvent => AppConfig.pusherEventName;

  Future<void> connectToOrder({
    required String orderId,
    required void Function(OrderStatusUpdate update) onUpdate,
    void Function(String message)? onError,
    void Function(String message)? onInfo,
  }) async {
    if (!PusherService.instance.isConfigured) {
      onError?.call('Pusher no está configurado (PUSHER_KEY/PUSHER_CLUSTER).');
      return;
    }

    final nextChannel = '${AppConfig.pusherChannelPrefix}$orderId';
    if (_subscribedChannel != null && _subscribedChannel != nextChannel) {
      await PusherService.instance.unsubscribe(_subscribedChannel!);
    }
    _subscribedChannel = nextChannel;

    await _subscription?.cancel();
    _subscription = PusherService.instance.events.listen((event) {
      if (event.channelName != _subscribedChannel) return;
      onInfo?.call(
        'Evento: canal=${event.channelName} evento=${event.eventName}',
      );
      if (event.eventName != AppConfig.pusherEventName) return;

      final data = event.data;
      if (data == null) return;

      try {
        final dynamic decoded = data is String ? jsonDecode(data) : data;
        if (decoded is! Map) return;
        onUpdate(OrderStatusUpdate.fromMap(decoded.cast<String, dynamic>()));
      } catch (e) {
        onInfo?.call('Pusher: no se pudo parsear data ($e)');
      }
    });

    onInfo?.call('Suscribiendo a $_subscribedChannel');
    await PusherService.instance.subscribe(
      _subscribedChannel!,
      onInfo: onInfo,
      onError: onError,
    );
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    if (_subscribedChannel != null) {
      await PusherService.instance.unsubscribe(_subscribedChannel!);
      _subscribedChannel = null;
    }
  }
}
