class AppConfig {
  static const serverOrigin = 'https://api.saborcentral.com';
  static const apiBaseUrl = '$serverOrigin/api';
  static const uploadsBaseUrl = '$serverOrigin/uploads';
  static const apiHostLabel = 'api.saborcentral.com';

  static const pusherKey = String.fromEnvironment(
    'PUSHER_KEY',
    defaultValue: '1e3a8925dd99d50c035e',
  );
  static const pusherCluster = String.fromEnvironment(
    'PUSHER_CLUSTER',
    defaultValue: 'mt1',
  );
  static const pusherChannelPrefix = String.fromEnvironment(
    'PUSHER_CHANNEL_PREFIX',
    defaultValue: 'pedido.',
  );
  static const pusherEventName = String.fromEnvironment(
    'PUSHER_EVENT_NAME',
    defaultValue: 'pedido.estado.actualizado',
  );
}
