import 'app_config.dart';

class ApiEndpoints {
  static String get baseUrl => AppConfig.apiBaseUrl;
  static String get uploadsBaseUrl => AppConfig.uploadsBaseUrl;

  static const health = '/health';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const sendRegistrationCode = '/auth/register/email/send-code';
  static const verifyRegistrationCode = '/auth/register/email/verify-code';
  static const verifyGoogleRegistration = '/auth/register/google/verify';
  static const googleLogin = '/auth/google';
  static const verifySession = '/auth/verify';
  static const forgotPassword = '/auth/password/forgot';
  static const verifyPasswordResetCode = '/auth/password/verify-code';
  static const resetPassword = '/auth/password/reset';
  static const me = '/usuarios/perfil';
  static const profileStats = '/usuarios/estadisticas';
  static const changePassword = '/usuarios/cambiar-password';
  static const products = '/productos';
  static const categories = '/categorias';
  static const contact = '/contacto';
  static const chatbotHealth = '/chatbot/health';
  static const chatbotAsk = '/chatbot/ask';
  static const receipts = '/facturacion/mis-comprobantes';
  static const issueReceipt = '/facturacion/emitir';
  static const pendingNotifications = '/notificaciones/pendientes';
  static const markNotificationsShown = '/notificaciones/marcar-mostradas';

  static const orders = '/pedidos';
  static const myOrders = '/pedidos/mis-pedidos';
  static String orderById(String id) => '/pedidos/$id';
  static String cancelOrder(String id) => '/pedidos/$id/cancelar';
  static String orderTracking(String id) => '/pedidos/$id';
  static String orderEvents(String id) => '/pedidos/$id';

  static const loginCandidates = ['/auth/login', '/login'];
  static const registerCandidates = ['/auth/register', '/register'];
  static const ordersCandidates = [
    '/pedidos/mis-pedidos',
    '/pedidos',
    '/orders',
  ];
  static List<String> orderByIdCandidates(String id) => [
    '/pedidos/$id',
    '/orders/$id',
  ];
  static List<String> orderTrackingCandidates(String id) => [
    '/pedidos/$id/tracking',
    '/orders/$id/tracking',
    '/pedidos/$id',
    '/orders/$id',
  ];
}
