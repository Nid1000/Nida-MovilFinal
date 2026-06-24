import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/checkout_rules.dart';

void main() {
  group('CheckoutRules', () {
    test('formats delivery dates for display and backend', () {
      final date = DateTime(2026, 6, 24);

      expect(CheckoutRules.formatDeliveryDate(date), '24/06/2026');
      expect(CheckoutRules.backendDeliveryDate('24/06/2026'), '2026-06-24');
      expect(CheckoutRules.backendDeliveryDate('2026-06-24'), '2026-06-24');
    });

    test('validates Peru mobile numbers', () {
      expect(CheckoutRules.isValidPeruPhone('987654321'), isTrue);
      expect(CheckoutRules.isValidPeruPhone('887654321'), isFalse);
      expect(CheckoutRules.isValidPeruPhone('98765432'), isFalse);
    });

    test('validates RUC check digit', () {
      expect(CheckoutRules.isValidRuc('20123456786'), isTrue);
      expect(CheckoutRules.isValidRuc('20123456789'), isFalse);
      expect(CheckoutRules.isValidRuc('99123456786'), isFalse);
    });
  });
}
