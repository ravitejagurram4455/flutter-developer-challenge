import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tui_challenege/features/trip_planner/presentation/price_format.dart';

void main() {
  test('formats whole and fractional amounts', () {
    expect(formatPrice(0), '0');
    expect(formatPrice(12000), '120');
    expect(formatPrice(12050), '120.50');
    expect(formatPrice(1205), '12.05');
  });
}
