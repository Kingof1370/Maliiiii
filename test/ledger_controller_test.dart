import 'package:maliiiii/app/data/ledger_repository.dart';
import 'package:maliiiii/app/state/ledger_controller.dart';
import 'package:maliiiii/maliiiii.dart';
import 'package:test/test.dart';

import 'memory_ledger_store.dart';

void main() {
  test('controller loads store and persists every commit', () async {
    final MemoryLedgerStore store = MemoryLedgerStore();
    final LedgerController controller =
        LedgerController(LedgerRepository(store));

    await controller.init();
    expect(controller.status, LedgerStatus.ready);
    expect(controller.ledger.accounts, isEmpty);

    final FinancialLedger withAccount = await controller.commit(
      (FinancialLedger current) => current.copyWith(
        accounts: <Account>[
          Account(
            id: 'bank',
            name: 'بانک',
            type: AccountType.bank,
            openingBalance: const Money(1000000),
          ),
        ],
      ),
    );
    expect(withAccount.accounts.single.id, 'bank');
    expect(controller.ledger.accounts.single.id, 'bank');

    await controller.commit(
      (FinancialLedger current) => current.recordIncome(
        id: 'inc1',
        accountId: 'bank',
        amount: const Money(2500000),
        date: DateTime(2026, 8, 15),
        category: 'حقوق',
      ),
    );
    expect(controller.ledger.totalBalance(), const Money(3500000));

    // جرئیات به همان فروشگاه حافظه‌ای persist شده و قابل بارگذاری مجدد است.
    final LedgerController reloaded =
        LedgerController(LedgerRepository(store));
    await reloaded.init();
    expect(reloaded.ledger.transactions.single.kind, TransactionKind.income);
    expect(reloaded.ledger.totalBalance(), const Money(3500000));
  });

  test('invalid mutation surfaces engine validation and does not persist',
      () async {
    final MemoryLedgerStore store = MemoryLedgerStore();
    final LedgerController controller =
        LedgerController(LedgerRepository(store));
    await controller.init();

    await expectLater(
      controller.commit(
        (FinancialLedger current) => current.recordExpense(
          id: 'exp1',
          accountId: 'missing',
          amount: const Money(1000),
          date: DateTime(2026, 8, 15),
        ),
      ),
      throwsA(isA<FinancialValidationException>()),
    );
    expect(controller.ledger.accounts, isEmpty);
  });
}
