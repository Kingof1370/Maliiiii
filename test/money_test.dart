import 'package:maliiiii/maliiiii.dart';
import 'package:test/test.dart';

void main() {
  test('negative balances remain exact integers', () {
    const balance = Money(-125, currency: 'IRR');
    expect(balance.isNegative, isTrue);
    expect(balance.abs(), const Money(125, currency: 'IRR'));
  });
}