import 'dart:async';
import 'dart:developer';

import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import 'app_config.dart';

class PusherService {
  PusherService._();

  static final PusherService instance = PusherService._();

  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  final StreamController<PusherEvent> _eventsController =
      StreamController<PusherEvent>.broadcast();

  bool _initialized = false;
  bool _connected = false;
  final Set<String> _subscribedChannels = <String>{};

  Stream<PusherEvent> get events => _eventsController.stream;

  bool get isConfigured =>
      AppConfig.pusherKey.isNotEmpty && AppConfig.pusherCluster.isNotEmpty;

  Future<void> ensureInitialized({
    void Function(String message)? onInfo,
    void Function(String message)? onError,
  }) async {
    if (_initialized) return;

    if (!isConfigured) {
      onError?.call('Pusher no está configurado (PUSHER_KEY/PUSHER_CLUSTER).');
      return;
    }

    await _pusher.init(
      apiKey: AppConfig.pusherKey,
      cluster: AppConfig.pusherCluster,
      onConnectionStateChange: (currentState, previousState) {
        onInfo?.call('Pusher: $previousState -> $currentState');
      },
      onError: (message, code, e) {
        onError?.call(message);
        log('Pusher error: $message (code=$code) $e');
      },
      onSubscriptionSucceeded: (channelName, data) {
        onInfo?.call('Suscripción activa en $channelName');
      },
      onEvent: (event) {
        if (_eventsController.isClosed) return;
        _eventsController.add(event);
      },
    );

    _initialized = true;
  }

  Future<void> connect({
    void Function(String message)? onInfo,
    void Function(String message)? onError,
  }) async {
    await ensureInitialized(onInfo: onInfo, onError: onError);
    if (!_initialized) return;
    if (_connected) return;
    await _pusher.connect();
    _connected = true;
  }

  Future<void> subscribe(
    String channelName, {
    void Function(String message)? onInfo,
    void Function(String message)? onError,
  }) async {
    await connect(onInfo: onInfo, onError: onError);
    if (!_connected) return;
    if (_subscribedChannels.contains(channelName)) return;
    await _pusher.subscribe(channelName: channelName);
    _subscribedChannels.add(channelName);
  }

  Future<void> unsubscribe(String channelName) async {
    if (!_subscribedChannels.contains(channelName)) return;
    try {
      await _pusher.unsubscribe(channelName: channelName);
    } catch (_) {
      // Best-effort: plugin may throw if already unsubscribed/disconnected.
    } finally {
      _subscribedChannels.remove(channelName);
    }
  }

  Future<void> disconnect() async {
    for (final channel in _subscribedChannels.toList()) {
      await unsubscribe(channel);
    }
    try {
      await _pusher.disconnect();
    } catch (_) {
      // Best-effort.
    } finally {
      _connected = false;
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _eventsController.close();
    _initialized = false;
  }
}
