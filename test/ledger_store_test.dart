import 'dart:io';

import 'package:maliiiii/app/data/ledger_store.dart';
import 'package:maliiiii/maliiiii.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ledger_store_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('store returns null when no file exists', () async {
    final FileLedgerStore store =
        FileLedgerStore(File('${tempDir.path}/missing.json'));
    expect(await store.load(), isNull);
  });

  test('save then load round-trips a full ledger', () async {
    final File file = File('${tempDir.path}/ledger.json');
    final FileLedgerStore store = FileLedgerStore(file);
    final FinancialLedger ledger = FinancialLedger(
      accounts: <Account>[
        Account(
          id: 'bank',
          name: 'بانک',
          type: AccountType.bank,
          openingBalance: const Money(500000),
        ),
      ],
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 'inc1',
          accountId: 'bank',
          amount: const Money(2500000),
          date: DateTime(2026, 8, 10),
          kind: TransactionKind.income,
          category: 'حقوق',
        ),
      ],
      loans: <Loan>[
        Loan(
          id: 'loan1',
          title: 'وام مسکن',
          lender: 'بانک',
          principal: const Money(90000000),
          receivedAmount: const Money(90000000),
          interest: const Money(10000000),
          fees: const Money(0),
          totalPayable: const Money(100000000),
          startDate: DateTime(2026, 6, 1),
          installments: <Installment>[
            Installment(
              id: 'i1',
              loanId: 'loan1',
              number: 1,
              dueDate: DateTime(2026, 9, 1),
              totalAmount: const Money(20000000),
            ),
          ],
        ),
      ],
    );

    await store.save(ledger);
    expect(await file.exists(), isTrue);

    final FinancialLedger? restored = await store.load();
    expect(restored, isNotNull);
    expect(restored!.accounts.single.name, 'بانک');
    expect(restored.transactions.single.kind, TransactionKind.income);
    expect(restored.loans.single.title, 'وام مسکن');
    expect(restored.totalBalance(), const Money(3000000));
  });

  test('corrupted file is treated as missing ledger', () async {
    final File file = File('${tempDir.path}/ledger.json');
    await file.writeAsString('{not valid json');
    final FileLedgerStore store = FileLedgerStore(file);
    expect(await store.load(), isNull);
  });

  test('unsupported schema version is treated as missing ledger', () async {
    final File file = File('${tempDir.path}/ledger.json');
    await file.writeAsString('{"schemaVersion": 99}');
    final FileLedgerStore store = FileLedgerStore(file);
    expect(await store.load(), isNull);
  });
}
