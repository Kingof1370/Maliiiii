import 'package:flutter/foundation.dart';

import '../../src/engine.dart';
import '../../src/models.dart';
import 'ledger_controller.dart';

/// کنترل‌کنندهٔ دسته‌های سفارشی؛ همهٔ تغییرات از طریق
/// [LedgerController.commit] اتمیک پایدار می‌شوند.
final class CategoryController extends ChangeNotifier {
  CategoryController(this._ledger);

  final LedgerController _ledger;

  List<UserCategory> get categories => _ledger.ledger.customCategories;

  List<UserCategory> get expense =>
      categories.where((item) => item.kind == CategoryKind.expense).toList();

  List<UserCategory> get income =>
      categories.where((item) => item.kind == CategoryKind.income).toList();

  Future<UserCategory> add({
    required String id,
    required String name,
    required CategoryKind kind,
  }) async {
    final FinancialLedger result = await _ledger.commit(
      (FinancialLedger current) => current.addCustomCategory(
        category: UserCategory(id: id, name: name.trim(), kind: kind),
      ),
    );
    notifyListeners();
    return result.customCategories.lastWhere((item) => item.id == id);
  }

  Future<void> delete(String id) async {
    await _ledger.commit(
      (FinancialLedger current) => current.deleteCustomCategory(id),
    );
    notifyListeners();
  }
}
