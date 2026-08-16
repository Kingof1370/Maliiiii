typedef MinorUnits = int;

/// A deterministic monetary value stored as integer minor units.
///
/// The UI decides whether minor units mean ریال or تومان. Financial logic
/// never uses floating point numbers.
final class Money implements Comparable<Money> {
  const Money(this.minorUnits, {this.currency = 'IRR'});

  final MinorUnits minorUnits;
  final String currency;

  Money operator +(Money other) {
    _requireSameCurrency(other);
    return Money(minorUnits + other.minorUnits, currency: currency);
  }

  Money operator -(Money other) {
    _requireSameCurrency(other);
    return Money(minorUnits - other.minorUnits, currency: currency);
  }

  Money operator -() => Money(-minorUnits, currency: currency);

  Money times(int multiplier) =>
      Money(minorUnits * multiplier, currency: currency);

  Money abs() => Money(minorUnits.abs(), currency: currency);

  bool get isZero => minorUnits == 0;
  bool get isPositive => minorUnits > 0;
  bool get isNegative => minorUnits < 0;

  @override
  int compareTo(Money other) {
    _requireSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.currency == currency &&
      other.minorUnits == minorUnits;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => '$minorUnits $currency';

  Map<String, Object?> toJson() => <String, Object?>{
        'minor': minorUnits,
        'currency': currency,
      };

  factory Money.fromJson(Map<String, Object?> json) => Money(
        (json['minor'] as num?)?.toInt() ?? 0,
        currency: json['currency'] as String? ?? 'IRR',
      );

  void _requireSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError(
        'Currency mismatch: $currency and ${other.currency}',
      );
    }
  }
}