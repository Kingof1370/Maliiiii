String toPersianDigits(Object value) {
  const latin = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final input = value.toString();
  return input.split('').map((character) {
    final index = latin.indexOf(character);
    return index == -1 ? character : persian[index];
  }).join();
}

String formatMinorUnits(int minorUnits, {String suffix = 'تومان'}) {
  final sign = minorUnits < 0 ? '-' : '';
  final digits = minorUnits.abs().toString();
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = (end - 3).clamp(0, end);
    groups.insert(0, digits.substring(start, end));
  }
  return '$sign${toPersianDigits(groups.join(','))} $suffix';
}