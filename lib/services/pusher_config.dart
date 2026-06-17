import 'dart:async';
import 'dart:developer';

import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import 'pusher_service.dart';

class PusherConfig {
  String? _channelName;
  StreamSubscription<PusherEvent>? _subscription;

  Future<void> initPusher({
    required String channelName,
    required String eventName,
    required Function(PusherEvent) onEventTriggered,
  }) async {
    if (!PusherService.instance.isConfigured) {
      log('Pusher no configurado: faltan PUSHER_KEY o PUSHER_CLUSTER');
      return;
    }

    if (_channelName != null && _channelName != channelName) {
      await PusherService.instance.unsubscribe(_channelName!);
    }
    _channelName = channelName;

    await _subscription?.cancel();
    _subscription = PusherService.instance.events.listen((event) {
      if (event.channelName != _channelName) return;
      if (event.eventName != eventName) return;
      onEventTriggered(event);
    });

    await PusherService.instance.subscribe(channelName);
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    if (_channelName != null) {
      await PusherService.instance.unsubscribe(_channelName!);
      _channelName = null;
    }
  }
}
