import 'package:maliiiii/app/data/ledger_repository.dart';
import 'package:maliiiii/app/state/account_controller.dart';
import 'package:maliiiii/app/state/ledger_controller.dart';
import 'package:maliiiii/maliiiii.dart';
import 'package:test/test.dart';

import 'memory_ledger_store.dart';

void main() {
  test('addAccount + income + expense + transfer persist, exact balances', () async {
    final MemoryLedgerStore store = MemoryLedgerStore();
    final LedgerController ledger = LedgerController(LedgerRepository(store));
    final AccountController accounts = AccountController(ledger);
    await ledger.init();

    await accounts.addAccount(
      id: 'bank',
      name: 'بانک',
      type: AccountType.bank,
      openingMinorUnits: 1000000,
    );
    await accounts.addAccount(
      id: 'cash',
      name: 'نقدی',
      type: AccountType.cash,
      openingMinorUnits: 0,
    );
    expect(accounts.accounts, hasLength(2));

    await accounts.recordIncome(
      id: 'inc1',
      accountId: 'bank',
      amountMinorUnits: 500000,
      date: DateTime(2026, 8, 10),
      category: 'حقوق',
    );
    await accounts.recordExpense(
      id: 'exp1',
      accountId: 'bank',
      amountMinorUnits: 200000,
      date: DateTime(2026, 8, 12),
      category: 'خوراک',
    );
    await accounts.recordTransfer(
      transferId: 'tr1',
      fromAccountId: 'bank',
      toAccountId: 'cash',
      amountMinorUnits: 100000,
      date: DateTime(2026, 8, 13),
    );

    // موجودی دقیق: بانک = ۱٬۰۰۰٬۰۰۰ + ۵۰۰٬۰۰۰ − ۲۰۰٬۰۰۰ − ۱۰۰٬۰۰۰ = ۱٬۲۰۰٬۰۰۰
    expect(accounts.balanceOf('bank'), const Money(1200000, currency: 'IRR'));
    expect(accounts.balanceOf('cash'), const Money(100000, currency: 'IRR'));
    expect(accounts.balanceOf('bank').minorUnits, 1200000);

    // خالص دارایی بدون دوباره‌شماری: انتقال فقط جابه‌جا می‌کند
    expect(ledger.ledger.totalBalance(), const Money(1300000, currency: 'IRR'));

    // persist: بارگذاری دوباره از همان فروشگاه
    final LedgerController reloaded =
        LedgerController(LedgerRepository(store));
    await reloaded.init();
    expect(reloaded.ledger.accounts, hasLength(2));
    expect(reloaded.ledger.transactions, hasLength(4)); // درآمد + هزینه + ۲ رکورد انتقال
    expect(reloaded.ledger.totalBalance(), const Money(1300000, currency: 'IRR'));
  });

  test('duplicate account and invalid transfers are rejected', () async {
    final MemoryLedgerStore store = MemoryLedgerStore();
    final LedgerController ledger = LedgerController(LedgerRepository(store));
    final AccountController accounts = AccountController(ledger);
    await ledger.init();

    await accounts.addAccount(
      id: 'a',
      name: 'A',
      type: AccountType.cash,
      openingMinorUnits: 10000,
    );

    await expectLater(
      accounts.addAccount(
        id: 'a',
        name: 'A2',
        type: AccountType.cash,
        openingMinorUnits: 0,
      ),
      throwsA(isA<FinancialValidationException>()),
    );

    // هزینه در حساب ناموجود
    await expectLater(
      accounts.recordExpense(
        id: 'e1',
        accountId: 'nope',
        amountMinorUnits: 10,
        date: DateTime(2026, 8, 1),
      ),
      throwsA(isA<FinancialValidationException>()),
    );

    // انتقال به خودش
    await expectLater(
      accounts.recordTransfer(
        transferId: 't1',
        fromAccountId: 'a',
        toAccountId: 'a',
        amountMinorUnits: 100,
        date: DateTime(2026, 8, 1),
      ),
      throwsA(isA<FinancialValidationException>()),
    );

    // انتقال نامعتبر به حساب ناموجود
    await expectLater(
      accounts.recordTransfer(
        transferId: 't2',
        fromAccountId: 'a',
        toAccountId: 'x',
        amountMinorUnits: 100,
        date: DateTime(2026, 8, 1),
      ),
      throwsA(isA<FinancialValidationException>()),
    );

    // هیچ‌کدام persist نشده‌اند
    expect(ledger.ledger.transactions, isEmpty);
    expect(ledger.ledger.accounts, hasLength(1));
  });
}
