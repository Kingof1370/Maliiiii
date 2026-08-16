import 'dart:convert';
import 'dart:io';

import '../../src/engine.dart';

/// مرز ذخیره‌سازی دفترکل؛ پیاده‌سازی فایل برای اجرای آفلاین و تست‌پذیری.
abstract interface class LedgerStore {
  Future<FinancialLedger?> load();

  Future<FinancialLedger> save(FinancialLedger ledger);
}

/// ذخیره‌سازی JSON روی فایل محلی با نوشتن اتمیک (فایل موقت + rename).
///
/// اگر فایل موجود نباشد یا خراب باشد، [load] بدون خطا `null` برمی‌گرداند؛
/// تصمیم دربارهٔ شروع مجدد با دفترکل خالی بر عهدهٔ لایهٔ بالاتر است.
final class FileLedgerStore implements LedgerStore {
  FileLedgerStore(this.file);

  final File file;

  @override
  Future<FinancialLedger?> load() async {
    if (!await file.exists()) return null;
    try {
      final String raw = await file.readAsString();
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return null;
      return FinancialLedger.fromJson(decoded);
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<FinancialLedger> save(FinancialLedger ledger) async {
    await file.parent.create(recursive: true);
    final File temp = File('${file.path}.tmp');
    await temp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(ledger.toJson()),
      flush: true,
    );
    await temp.rename(file.path);
    return ledger;
  }
}
