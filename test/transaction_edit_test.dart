import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/app/data/ledger_repository.dart';
import 'package:maliiiii/app/state/account_controller.dart';
import 'package:maliiiii/app/state/ledger_controller.dart';
import 'package:maliiiii/maliiiii.dart';

import 'memory_ledger_store.dart';

Account _account() => const Account(
      id: 'acc-1',
      name: 'بانک',
      type: AccountType.bank,
      openingBalance: Money(10000000),
    );

FinancialLedger _base() => FinancialLedger(accounts: <Account>[_account()]);

void main() {
  group('engine updateTransaction', () {
    test('edits amount and category in place', () {
      final FinancialLedger ledger = _base().recordIncome(
        id: 't1',
        accountId: 'acc-1',
        amount: const Money(500000),
        date: DateTime(2026, 8, 1),
        category: 'حقوق',
      );
      final FinancialLedger updated = ledger.updateTransaction(
        id: 't1',
        amount: const Money(700000),
        category: 'فروش',
        description: 'ویرایش شد',
      );
      expect(updated.transactions.length, 1);
      expect(updated.transactions.single.amount.minorUnits, 700000);
      expect(updated.transactions.single.category, 'فروش');
      expect(updated.transactions.single.description, 'ویرایش شد');
    });

    test('updates both legs of a transfer, preserving accounts', () {
      final FinancialLedger ledger = _base()
          .copyWith(
            accounts: <Account>[
              _account(),
              const Account(
                id: 'acc-2',
                name: 'نقدی',
                type: AccountType.cash,
                openingBalance: Money(5000000),
              ),
            ],
          )
          .recordTransfer(
            transferId: 'tr-1',
            fromAccountId: 'acc-1',
            toAccountId: 'acc-2',
            amount: const Money(200000),
            date: DateTime(2026, 8, 2),
          );
      final FinancialLedger updated = ledger.updateTransaction(
        id: 'tr-1:out',
        amount: const Money(300000),
        description: 'بیشتر',
      );
      final Iterable<LedgerTransaction> legs =
          updated.transactions.where((t) => t.transferId == 'tr-1');
      expect(legs.length, 2);
      for (final LedgerTransaction tx in legs) {
        expect(tx.amount.minorUnits, 300000);
        expect(tx.description, 'بیشتر');
      }
      expect(updated.transactions.firstWhere((t) => t.id == 'tr-1:out').accountId,
          'acc-1');
    });

    test('rejects editing installment payments', () {
      final FinancialLedger ledger = FinancialLedger(
        accounts: <Account>[_account()],
        transactions: <LedgerTransaction>[
          LedgerTransaction(
            id: 'p1',
            accountId: 'acc-1',
            amount: const Money(100000),
            date: DateTime(2026, 8, 3),
            kind: TransactionKind.installmentPayment,
            referenceId: 'loan-1',
          ),
        ],
      );
      expect(
        () => ledger.updateTransaction(id: 'p1', amount: const Money(1)),
        throwsA(isA<FinancialValidationException>()),
      );
    });
  });

  group('engine deleteTransaction', () {
    test('removes a plain transaction', () {
      final FinancialLedger ledger = _base()
          .recordExpense(
            id: 't1',
            accountId: 'acc-1',
            amount: const Money(100000),
            date: DateTime(2026, 8, 4),
          )
          .recordIncome(
            id: 't2',
            accountId: 'acc-1',
            amount: const Money(200000),
            date: DateTime(2026, 8, 5),
          );
      final FinancialLedger updated = ledger.deleteTransaction('t1');
      expect(updated.transactions.length, 1);
      expect(updated.transactions.single.id, 't2');
    });

    test('removes both legs of a transfer', () {
      final FinancialLedger ledger = _base()
          .copyWith(
            accounts: <Account>[
              _account(),
              const Account(
                id: 'acc-2',
                name: 'نقدی',
                type: AccountType.cash,
                openingBalance: Money(5000000),
              ),
            ],
          )
          .recordTransfer(
            transferId: 'tr-1',
            fromAccountId: 'acc-1',
            toAccountId: 'acc-2',
            amount: const Money(200000),
            date: DateTime(2026, 8, 6),
          );
      final FinancialLedger updated = ledger.deleteTransaction('tr-1:in');
      expect(updated.transactions.where((t) => t.transferId == 'tr-1'),
          isEmpty);
      expect(updated.transactions, isEmpty);
    });

    test('rejects deleting installment payments', () {
      final FinancialLedger ledger = FinancialLedger(
        accounts: <Account>[_account()],
        transactions: <LedgerTransaction>[
          LedgerTransaction(
            id: 'p1',
            accountId: 'acc-1',
            amount: const Money(100000),
            date: DateTime(2026, 8, 7),
            kind: TransactionKind.installmentPayment,
          ),
        ],
      );
      expect(
        () => ledger.deleteTransaction('p1'),
        throwsA(isA<FinancialValidationException>()),
      );
    });
  });

  group('engine updateAccount / deleteAccount', () {
    test('renames an account and keeps opening balance', () {
      final FinancialLedger updated = _base().updateAccount(
        id: 'acc-1',
        name: 'بانک ملی',
        notes: 'حساب اصلی',
      );
      expect(updated.accounts.single.name, 'بانک ملی');
      expect(updated.accounts.single.openingBalance.minorUnits, 10000000);
      expect(updated.accounts.single.notes, 'حساب اصلی');
    });

    test('deletes an account without transactions', () {
      final FinancialLedger updated = _base().deleteAccount('acc-1');
      expect(updated.accounts, isEmpty);
    });

    test('rejects deleting an account with transactions', () {
      final FinancialLedger ledger = _base().recordExpense(
        id: 't1',
        accountId: 'acc-1',
        amount: const Money(1000),
        date: DateTime(2026, 8, 8),
      );
      expect(
        () => ledger.deleteAccount('acc-1'),
        throwsA(isA<FinancialValidationException>()),
      );
    });

    test('rejects deleting an account used by a recurring transaction', () {
      final FinancialLedger ledger = FinancialLedger(
        accounts: <Account>[_account()],
        recurrings: <RecurringTransaction>[
          RecurringTransaction(
            id: 'r1',
            name: 'اجاره',
            amount: const Money(3000000),
            kind: TransactionKind.expense,
            accountId: 'acc-1',
            frequency: RecurringFrequency.monthly,
            startDate: DateTime(2026, 1, 1),
          ),
        ],
      );
      expect(
        () => ledger.deleteAccount('acc-1'),
        throwsA(isA<FinancialValidationException>()),
      );
    });
  });

  group('controller wiring through commit', () {
    test('update and delete persist through LedgerController', () async {
      final MemoryLedgerStore store = MemoryLedgerStore();
      final LedgerController ledgerController =
          LedgerController(LedgerRepository(store));
      await ledgerController.init();
      final AccountController controller = AccountController(ledgerController);

      await controller.addAccount(
        id: 'acc-1',
        name: 'بانک',
        type: AccountType.bank,
        openingMinorUnits: 10000000,
      );
      await controller.recordIncome(
        id: 't1',
        accountId: 'acc-1',
        amountMinorUnits: 500000,
        date: DateTime(2026, 8, 10),
        category: 'حقوق',
      );
      await controller.updateTransaction(
        id: 't1',
        accountId: 'acc-1',
        amountMinorUnits: 600000,
        date: DateTime(2026, 8, 10),
        category: 'فروش',
      );
      expect(ledgerController.ledger.transactions.single.amount.minorUnits,
          600000);
      expect(ledgerController.ledger.transactions.single.category, 'فروش');

      await controller.deleteTransaction('t1');
      expect(ledgerController.ledger.transactions, isEmpty);

      await controller.updateAccount(id: 'acc-1', name: 'بانک ملت');
      expect(ledgerController.ledger.accounts.single.name, 'بانک ملت');
    });
  });
}
