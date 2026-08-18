import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/maliiiii.dart';

FinancialLedger _ledger({
  List<LedgerTransaction> transactions = const [],
  List<Loan> loans = const [],
  List<Budget> budgets = const [],
  List<Goal> goals = const [],
}) =>
    FinancialLedger(
      transactions: transactions,
      loans: loans,
      budgets: budgets,
      goals: goals,
    );

Installment _installment({
  String id = 'i1',
  String loanId = 'loan-1',
  required DateTime due,
  Money amount = const Money(1000000),
}) =>
    Installment(
      id: id,
      loanId: loanId,
      number: 1,
      dueDate: due,
      totalAmount: amount,
    );

Loan _loan({
  String id = 'loan-1',
  String title = 'خرید خودرو',
  List<Installment> installments = const [],
}) =>
    Loan(
      id: id,
      title: title,
      lender: 'بانک',
      principal: const Money(1000000),
      receivedAmount: const Money(1000000),
      interest: const Money(0),
      fees: const Money(0),
      totalPayable: const Money(1000000),
      startDate: DateTime(2026, 1, 1),
      installments: installments,
    );

UserProfile _profile({NotificationTone tone = NotificationTone.formal}) =>
    UserProfile.create(firstName: 'علی', lastName: 'بهمنی', tone: tone);

void main() {
  final DateTime asOf = DateTime(2026, 8, 18, 10);

  group('buildNotifications', () {
    test('empty ledger produces only low noRecentActivity', () {
      final List<AppNotification> result =
          buildNotifications(ledger: _ledger(), profile: _profile(), asOf: asOf);

      expect(result.length, 1);
      expect(result.single.kind, NotificationKind.noRecentActivity);
      expect(result.single.priority, NotificationPriority.low);
    });

    test('overdue installment is urgent and uses serious tone in mixed', () {
      final List<AppNotification> result = buildNotifications(
        ledger: _ledger(
          loans: <Loan>[
            _loan(
              installments: <Installment>[
                _installment(due: DateTime(2026, 7, 10)),
              ],
            ),
          ],
        ),
        profile: _profile(tone: NotificationTone.mixed),
        asOf: asOf,
      );

      final AppNotification n = result
          .firstWhere((n) => n.kind == NotificationKind.overdueInstallment);
      expect(n.priority, NotificationPriority.urgent);
      expect(n.title, contains('معوق'));
      expect(n.body, contains('خرید خودرو'));
    });

    test('due today installment is high priority', () {
      final List<AppNotification> result = buildNotifications(
        ledger: _ledger(
          loans: <Loan>[
            _loan(
              installments: <Installment>[
                _installment(due: DateTime(2026, 8, 18)),
              ],
            ),
          ],
        ),
        profile: _profile(),
        asOf: asOf,
      );

      final AppNotification n = result
          .firstWhere((n) => n.kind == NotificationKind.dueInstallment);
      expect(n.priority, NotificationPriority.high);
      expect(n.title, contains('خرید خودرو'));
    });

    test('upcoming installment within three days is normal', () {
      final List<AppNotification> result = buildNotifications(
        ledger: _ledger(
          loans: <Loan>[
            _loan(
              installments: <Installment>[
                _installment(due: DateTime(2026, 8, 20)),
              ],
            ),
          ],
        ),
        profile: _profile(),
        asOf: asOf,
      );

      final AppNotification n = result
          .firstWhere((n) => n.kind == NotificationKind.upcomingInstallment);
      expect(n.priority, NotificationPriority.normal);
    });

    test('dedup: several overdue installments produce a single notification',
        () {
      final List<AppNotification> result = buildNotifications(
        ledger: _ledger(
          loans: <Loan>[
            _loan(
              id: 'loan-1',
              installments: <Installment>[
                _installment(loanId: 'loan-1', due: DateTime(2026, 7, 1)),
              ],
            ),
            _loan(
              id: 'loan-2',
              title: 'وام مسکن',
              installments: <Installment>[
                _installment(loanId: 'loan-2', due: DateTime(2026, 7, 2)),
              ],
            ),
          ],
        ),
        profile: _profile(),
        asOf: asOf,
      );

      expect(
        result.where((n) => n.kind == NotificationKind.overdueInstallment).length,
        1,
      );
    });

    test('budget overrun detected from real expenses', () {
      final List<AppNotification> result = buildNotifications(
        ledger: _ledger(
          transactions: <LedgerTransaction>[
            LedgerTransaction(
              id: 't1',
              accountId: 'acc-1',
              amount: const Money(6000000),
              date: DateTime(2026, 8, 10),
              kind: TransactionKind.expense,
              category: 'خوراک',
            ),
          ],
          budgets: <Budget>[
            Budget(
              id: 'b1',
              name: 'غذا',
              amount: const Money(5000000),
              startDate: DateTime(2026, 8, 1),
              endDate: DateTime(2026, 8, 31),
              category: 'خوراک',
            ),
          ],
        ),
        profile: _profile(),
        asOf: asOf,
      );

      final AppNotification n = result
          .firstWhere((n) => n.kind == NotificationKind.budgetOverrun);
      expect(n.priority, NotificationPriority.high);
      expect(n.body, contains('غذا'));
    });

    test('budget near limit (>=80%) is normal priority', () {
      final List<AppNotification> result = buildNotifications(
        ledger: _ledger(
          transactions: <LedgerTransaction>[
            LedgerTransaction(
              id: 't1',
              accountId: 'acc-1',
              amount: const Money(4000000),
              date: DateTime(2026, 8, 10),
              kind: TransactionKind.expense,
              category: 'خوراک',
            ),
          ],
          budgets: <Budget>[
            Budget(
              id: 'b1',
              name: 'غذا',
              amount: const Money(5000000),
              startDate: DateTime(2026, 8, 1),
              endDate: DateTime(2026, 8, 31),
              category: 'خوراک',
            ),
          ],
        ),
        profile: _profile(),
        asOf: asOf,
      );

      expect(
        result.where((n) => n.kind == NotificationKind.budgetOverrun),
        isEmpty,
      );
      expect(
        result.where((n) => n.kind == NotificationKind.budgetNearLimit).length,
        1,
      );
    });

    test('completed goal triggers goalMilestone', () {
      final List<AppNotification> result = buildNotifications(
        ledger: _ledger(
          goals: <Goal>[
            Goal(
              id: 'g1',
              name: 'پس‌انداز سفر',
              type: GoalType.savings,
              target: const Money(10000000),
              current: const Money(10000000),
              deadline: DateTime(2026, 12, 1),
            ),
          ],
        ),
        profile: _profile(tone: NotificationTone.friendly),
        asOf: asOf,
      );

      final AppNotification n = result
          .firstWhere((n) => n.kind == NotificationKind.goalMilestone);
      expect(n.body, contains('سفر'));
      expect(n.title, contains('محقق'));
    });

    test('negative free money raises lowBalance', () {
      final List<AppNotification> result = buildNotifications(
        ledger: _ledger(
          budgets: <Budget>[
            Budget(
              id: 'b1',
              name: 'اجاره',
              amount: const Money(5000000),
              startDate: DateTime(2026, 8, 1),
              endDate: DateTime(2026, 8, 31),
            ),
          ],
        ),
        profile: _profile(),
        asOf: asOf,
      );

      final AppNotification n = result
          .firstWhere((n) => n.kind == NotificationKind.lowBalance);
      expect(n.priority, NotificationPriority.high);
    });

    test('tones produce different wording for the same fact', () {
      final FinancialLedger ledger = _ledger(
        loans: <Loan>[
          _loan(
            installments: <Installment>[
              _installment(due: DateTime(2026, 7, 10)),
            ],
          ),
        ],
      );

      final String formalTitle = buildNotifications(
        ledger: ledger,
        profile: _profile(tone: NotificationTone.formal),
        asOf: asOf,
      )
          .firstWhere((n) => n.kind == NotificationKind.overdueInstallment)
          .title;

      final String funnyTitle = buildNotifications(
        ledger: ledger,
        profile: _profile(tone: NotificationTone.humorous),
        asOf: asOf,
      )
          .firstWhere((n) => n.kind == NotificationKind.overdueInstallment)
          .title;

      expect(formalTitle, isNot(funnyTitle));
      expect(funnyTitle, contains('😅'));
    });

    test('quiet night hours keep only important notifications', () {
      final DateTime night = DateTime(2026, 8, 18, 23, 30);
      final List<AppNotification> result = buildNotifications(
        ledger: _ledger(
          loans: <Loan>[
            _loan(
              installments: <Installment>[
                _installment(due: DateTime(2026, 7, 10)),
                _installment(id: 'i2', due: DateTime(2026, 8, 20)),
              ],
            ),
          ],
        ),
        profile: _profile(),
        asOf: night,
        quietHours: true,
      );

      final Set<NotificationKind> kinds =
          result.map((n) => n.kind).toSet();
      expect(kinds, contains(NotificationKind.overdueInstallment));
      expect(kinds, isNot(contains(NotificationKind.upcomingInstallment)));
      expect(kinds, isNot(contains(NotificationKind.noRecentActivity)));
    });

    test('results are sorted by priority descending', () {
      final List<AppNotification> result = buildNotifications(
        ledger: _ledger(
          loans: <Loan>[
            _loan(
              installments: <Installment>[
                _installment(due: DateTime(2026, 7, 10)),
                _installment(id: 'i2', due: DateTime(2026, 8, 20)),
              ],
            ),
          ],
          budgets: <Budget>[
            Budget(
              id: 'b1',
              name: 'اجاره',
              amount: const Money(5000000),
              startDate: DateTime(2026, 8, 1),
              endDate: DateTime(2026, 8, 31),
            ),
          ],
        ),
        profile: _profile(),
        asOf: asOf,
      );

      for (int i = 0; i + 1 < result.length; i++) {
        expect(
          result[i].priority.rank >= result[i + 1].priority.rank,
          isTrue,
          reason: '${result[i].kind} should come before ${result[i + 1].kind}',
        );
      }
    });
  });
}
