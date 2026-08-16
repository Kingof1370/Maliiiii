import 'package:maliiiii/app/data/ledger_store.dart';
import 'package:maliiiii/maliiiii.dart';

/// ذخیره‌سازی حافظه‌ای دفترکل برای تست‌های ویجت (بدون I/O واقعی فایل).
class MemoryLedgerStore implements LedgerStore {
  MemoryLedgerStore([this._ledger]);

  FinancialLedger? _ledger;

  @override
  Future<FinancialLedger?> load() async => _ledger;

  @override
  Future<FinancialLedger> save(FinancialLedger ledger) async {
    _ledger = ledger;
    return ledger;
  }
}
