import '../../src/engine.dart';
import 'ledger_store.dart';

/// مخزن دفترکل با کش حافظه‌ای؛ UI هرگز مستقیم با فایل کار نمی‌کند.
final class LedgerRepository {
  LedgerRepository(this._store);

  final LedgerStore _store;
  FinancialLedger? _cached;

  Future<FinancialLedger?> load() async {
    _cached ??= await _store.load();
    return _cached;
  }

  Future<FinancialLedger> save(FinancialLedger ledger) async {
    final FinancialLedger saved = await _store.save(ledger);
    _cached = saved;
    return saved;
  }
}
