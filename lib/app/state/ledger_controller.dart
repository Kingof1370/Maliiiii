import 'package:flutter/foundation.dart';

import '../../src/engine.dart';
import '../data/ledger_repository.dart';

enum LedgerStatus { loading, ready }

/// کنترل‌کنندهٔ دفترکل؛ تنها مسیر ارتباط UI با لایهٔ داده.
final class LedgerController extends ChangeNotifier {
  LedgerController(this._repository);

  final LedgerRepository _repository;

  LedgerStatus _status = LedgerStatus.loading;
  FinancialLedger _ledger = const FinancialLedger();

  LedgerStatus get status => _status;
  FinancialLedger get ledger => _ledger;

  Future<void> init() async {
    _ledger = await _repository.load() ?? const FinancialLedger();
    _status = LedgerStatus.ready;
    notifyListeners();
  }

  /// تنها مسیر تغییر دفترکل: یک تغییر در مهندسی مالی اجرا و نتیجهٔ آن
  /// بلافاصله و به‌صورت اتمیک روی دیسک پایدار (persist) می‌شود.
  Future<FinancialLedger> commit(
    FinancialLedger Function(FinancialLedger current) mutation,
  ) async {
    _ledger = await _repository.save(mutation(_ledger));
    notifyListeners();
    return _ledger;
  }
}
