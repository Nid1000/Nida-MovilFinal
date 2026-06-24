class CheckoutRules {
  static DateTime? parseDeliveryDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final slashMatch = RegExp(
      r'^(\d{2})\/(\d{2})\/(\d{4})$',
    ).firstMatch(trimmed);
    if (slashMatch != null) {
      final day = int.tryParse(slashMatch.group(1)!);
      final month = int.tryParse(slashMatch.group(2)!);
      final year = int.tryParse(slashMatch.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return DateTime.tryParse(trimmed);
  }

  static String formatDeliveryDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static String? backendDeliveryDate(String value) {
    final parsed = parseDeliveryDate(value);
    if (parsed == null) return null;

    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }

  static bool isValidPeruPhone(String value) {
    return RegExp(r'^9\d{8}$').hasMatch(value.trim());
  }

  static bool isValidRuc(String value) {
    final ruc = value.trim();
    if (!RegExp(r'^\d{11}$').hasMatch(ruc)) return false;
    if (!['10', '15', '17', '20'].contains(ruc.substring(0, 2))) {
      return false;
    }

    const weights = [5, 4, 3, 2, 7, 6, 5, 4, 3, 2];
    var sum = 0;
    for (var i = 0; i < weights.length; i++) {
      sum += int.parse(ruc[i]) * weights[i];
    }

    var check = 11 - (sum % 11);
    if (check == 10) check = 0;
    if (check == 11) check = 1;
    return check == int.parse(ruc[10]);
  }
}
