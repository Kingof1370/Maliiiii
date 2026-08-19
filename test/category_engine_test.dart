import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/maliiiii.dart';

void main() {
  UserCategory cat(String id, String name, CategoryKind kind) =>
      UserCategory(id: id, name: name, kind: kind);

  group('addCustomCategory', () {
    test('adds an expense and an income category', () {
      final FinancialLedger ledger = const FinancialLedger()
          .addCustomCategory(category: cat('c1', 'حیات‌وحوش', CategoryKind.expense))
          .addCustomCategory(category: cat('c2', 'پاداش', CategoryKind.income));
      expect(ledger.customCategories.length, 2);
      expect(ledger.customCategories.first.kind, CategoryKind.expense);
      expect(ledger.customCategories.last.kind, CategoryKind.income);
    });

    test('rejects duplicate name with the same kind', () {
      final FinancialLedger ledger = const FinancialLedger()
          .addCustomCategory(category: cat('c1', 'پاداش', CategoryKind.income));
      expect(
        () => ledger.addCustomCategory(
          category: cat('c2', 'پاداش', CategoryKind.income),
        ),
        throwsA(isA<FinancialValidationException>()),
      );
    });

    test('allows the same name in the other kind', () {
      final FinancialLedger ledger = const FinancialLedger()
          .addCustomCategory(category: cat('c1', 'پاداش', CategoryKind.income));
      final FinancialLedger updated = ledger.addCustomCategory(
        category: cat('c2', 'پاداش', CategoryKind.expense),
      );
      expect(updated.customCategories.length, 2);
    });
  });

  group('deleteCustomCategory', () {
    test('removes the category', () {
      final FinancialLedger ledger = const FinancialLedger()
          .addCustomCategory(category: cat('c1', 'حیات‌وحوش', CategoryKind.expense));
      final FinancialLedger updated = ledger.deleteCustomCategory('c1');
      expect(updated.customCategories, isEmpty);
    });

    test('rejects deleting a missing category', () {
      expect(
        () => const FinancialLedger().deleteCustomCategory('nope'),
        throwsA(isA<FinancialValidationException>()),
      );
    });
  });

  group('json round-trip', () {
    test('preserves custom categories', () {
      final FinancialLedger ledger = const FinancialLedger()
          .addCustomCategory(category: cat('c1', 'حیات‌وحوش', CategoryKind.expense))
          .addCustomCategory(category: cat('c2', 'پاداش', CategoryKind.income));
      final FinancialLedger restored =
          FinancialLedger.fromJson(ledger.toJson());
      expect(restored.customCategories.length, 2);
      expect(restored.customCategories.first.name, 'حیات‌وحوش');
      expect(restored.customCategories.last.kind, CategoryKind.income);
    });

    test('tolerates missing customCategories (old files)', () {
      final Map<String, Object?> json = <String, Object?>{
        'schemaVersion': 1,
        'accounts': <Object?>[],
        'transactions': <Object?>[],
        'loans': <Object?>[],
        'budgets': <Object?>[],
        'goals': <Object?>[],
        'recurrings': <Object?>[],
      };
      final FinancialLedger restored = FinancialLedger.fromJson(json);
      expect(restored.customCategories, isEmpty);
    });
  });
}
