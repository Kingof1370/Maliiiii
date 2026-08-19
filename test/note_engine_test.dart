import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/maliiiii.dart';

DailyNote _note({
  String id = 'n1',
  String dateKey = '1404-05-28',
  String text = 'متن یادداشت',
  DateTime? updatedAt,
}) =>
    DailyNote(
      id: id,
      dateKey: dateKey,
      text: text,
      createdAt: DateTime(2026, 8, 19),
      updatedAt: updatedAt,
    );

void main() {
  group('setDailyNote', () {
    test('adds a note for a day', () {
      final FinancialLedger ledger = const FinancialLedger()
          .setDailyNote(note: _note());
      expect(ledger.dailyNotes.length, 1);
      expect(ledger.dailyNotes.single.text, 'متن یادداشت');
    });

    test('replaces existing note for the same day', () {
      final FinancialLedger ledger = const FinancialLedger()
          .setDailyNote(note: _note(id: 'n1', text: 'قدیمی'))
          .setDailyNote(note: _note(id: 'n2', text: 'جدید'));
      expect(ledger.dailyNotes.length, 1);
      expect(ledger.dailyNotes.single.id, 'n2');
      expect(ledger.dailyNotes.single.text, 'جدید');
    });

    test('keeps notes of different days', () {
      final FinancialLedger ledger = const FinancialLedger()
          .setDailyNote(note: _note(dateKey: '1404-05-28'))
          .setDailyNote(note: _note(id: 'n2', dateKey: '1404-05-29'));
      expect(ledger.dailyNotes.length, 2);
    });
  });

  group('deleteDailyNote', () {
    test('removes the note for the day', () {
      final FinancialLedger ledger = const FinancialLedger()
          .setDailyNote(note: _note())
          .deleteDailyNote('1404-05-28');
      expect(ledger.dailyNotes, isEmpty);
    });

    test('missing day is a no-op', () {
      final FinancialLedger ledger = const FinancialLedger()
          .setDailyNote(note: _note())
          .deleteDailyNote('1404-01-01');
      expect(ledger.dailyNotes.length, 1);
    });
  });

  group('json round-trip', () {
    test('preserves daily notes', () {
      final FinancialLedger ledger = const FinancialLedger()
          .setDailyNote(note: _note(updatedAt: DateTime(2026, 8, 19, 12)));
      final FinancialLedger restored = FinancialLedger.fromJson(ledger.toJson());
      expect(restored.dailyNotes.length, 1);
      expect(restored.dailyNotes.single.dateKey, '1404-05-28');
      expect(restored.dailyNotes.single.updatedAt, DateTime(2026, 8, 19, 12));
    });

    test('tolerates missing dailyNotes (old files)', () {
      final Map<String, Object?> json = <String, Object?>{
        'schemaVersion': 1,
        'accounts': <Object?>[],
        'transactions': <Object?>[],
        'loans': <Object?>[],
        'budgets': <Object?>[],
        'goals': <Object?>[],
        'recurrings': <Object?>[],
        'customCategories': <Object?>[],
      };
      final FinancialLedger restored = FinancialLedger.fromJson(json);
      expect(restored.dailyNotes, isEmpty);
    });
  });
}
