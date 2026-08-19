import 'package:flutter/foundation.dart';

import '../../src/engine.dart';
import '../../src/models.dart';
import 'ledger_controller.dart';

/// کنترل‌کنندهٔ یادداشت‌های روزانه؛ همهٔ تغییرات از طریق
/// [LedgerController.commit] اتمیک پایدار می‌شوند.
final class NoteController extends ChangeNotifier {
  NoteController(this._ledger);

  final LedgerController _ledger;

  List<DailyNote> get notes => _ledger.ledger.dailyNotes;

  DailyNote? noteFor(String dateKey) {
    for (final DailyNote note in notes) {
      if (note.dateKey == dateKey) return note;
    }
    return null;
  }

  Future<void> save({required String dateKey, required String text}) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final DateTime now = DateTime.now();
    final DailyNote? existing = noteFor(dateKey);
    await _ledger.commit(
      (FinancialLedger current) => current.setDailyNote(
        note: DailyNote(
          id: existing?.id ?? 'note-${now.microsecondsSinceEpoch}',
          dateKey: dateKey,
          text: trimmed,
          createdAt: existing?.createdAt ?? now,
          updatedAt: existing == null ? null : now,
        ),
      ),
    );
    notifyListeners();
  }

  Future<void> delete(String dateKey) async {
    await _ledger.commit(
      (FinancialLedger current) => current.deleteDailyNote(dateKey),
    );
    notifyListeners();
  }
}
