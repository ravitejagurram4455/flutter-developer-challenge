/// Formats whole cents as "120" or "120.50". The API gives no currency, so none
/// is shown.
String formatPrice(int cents) {
  final whole = cents ~/ 100;
  final remainder = cents % 100;
  if (remainder == 0) return '$whole';
  return '$whole.${remainder.toString().padLeft(2, '0')}';
}
