import 'calendar.dart';
import 'engine.dart';
import 'models.dart';
import 'money.dart';
import 'number_format.dart';
import 'profile.dart';

/// سطح اهمیت اعلان؛ [rank] برای مرتب‌سازی استفاده می‌شود.
enum NotificationPriority { low, normal, high, urgent }

extension NotificationPriorityX on NotificationPriority {
  int get rank => switch (this) {
        NotificationPriority.low => 0,
        NotificationPriority.normal => 1,
        NotificationPriority.high => 2,
        NotificationPriority.urgent => 3,
      };
}

/// نوع اعلان هوشمند؛ در هر چرخه از هر نوع فقط قوی‌ترین نمونه ساخته می‌شود
/// تا خروجی تمیز و بدون تکرار باشد (dedup).
enum NotificationKind {
  overdueInstallment,
  dueInstallment,
  upcomingInstallment,
  budgetOverrun,
  budgetNearLimit,
  goalMilestone,
  lowBalance,
  noRecentActivity,
}

/// یک اعلان آمادهٔ نمایش. [id] کلید حذف تکراری بر پایهٔ نوع است.
final class AppNotification {
  const AppNotification({
    required this.kind,
    required this.priority,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final NotificationKind kind;
  final NotificationPriority priority;
  final String title;
  final String body;
  final DateTime createdAt;

  String get id => kind.name;
}

/// در حالت «ترکیبی» برای هر نوع، مناسب‌ترین لحن انتخاب می‌شود؛
/// اعلان‌های هشداردهنده جدی و پیشرفت‌ها دوستانه می‌شوند.
NotificationTone resolveTone(
  NotificationKind kind,
  NotificationTone preference,
) {
  if (preference != NotificationTone.mixed) return preference;
  return switch (kind) {
    NotificationKind.overdueInstallment ||
    NotificationKind.budgetOverrun ||
    NotificationKind.lowBalance => NotificationTone.serious,
    NotificationKind.goalMilestone ||
    NotificationKind.noRecentActivity => NotificationTone.friendly,
    NotificationKind.dueInstallment ||
    NotificationKind.upcomingInstallment ||
    NotificationKind.budgetNearLimit => NotificationTone.formal,
  };
}

/// ساعات سکوت: ۲۳ تا ۶ صبح؛ در این بازه فقط اعلان‌های پراهمیت می‌مانند.
bool isQuietHour(DateTime asOf) => asOf.hour >= 23 || asOf.hour < 6;

typedef _Texts = ({String title, String body});

_Texts _texts({
  required NotificationKind kind,
  required NotificationTone tone,
  required String name,
  required String amount,
  required String date,
  required String percent,
  bool complete = false,
}) {
  final NotificationTone t = resolveTone(kind, tone);
  switch (kind) {
    case NotificationKind.overdueInstallment:
      return switch (t) {
        NotificationTone.formal => (
            title: 'قسط معوق دارید',
            body:
                'قسط «$name» (سررسید $date، مبلغ $amount) هنوز پرداخت نشده است. لطفاً در نخستین فرصت اقدام کنید.',
          ),
        NotificationTone.friendly => (
            title: 'یک قسط عقب افتاده است ⏰',
            body:
                '«$name» با مبلغ $amount که سررسیدش $date بود هنوز پرداخت نشده. با هم نگاهی بیندازیم؟',
          ),
        NotificationTone.serious => (
            title: 'پرداخت معوق: $name',
            body:
                'مبلغ $amount از قسط «$name» (سررسید $date) پرداخت نشده است. تأخیر می‌تواند هزینهٔ اضافه ایجاد کند.',
          ),
        NotificationTone.humorous => (
            title: 'قسط هنوز در راه است 😅',
            body:
                '«$name» مبلغ $amount را از $date تا امروز همراهی می‌کند. شاید منتظر لحظهٔ مناسب است!',
          ),
        NotificationTone.mixed => (
            title: 'پرداخت معوق: $name',
            body: 'مبلغ $amount از قسط «$name» (سررسید $date) پرداخت نشده است.',
          ),
      };
    case NotificationKind.dueInstallment:
      return switch (t) {
        NotificationTone.formal => (
            title: 'قسط امروز: $name',
            body: 'قسط «$name» به مبلغ $amount امروز ($date) سررسید است.',
          ),
        NotificationTone.friendly => (
            title: 'امروز قسط داری 📅',
            body: 'قسط «$name» به مبلغ $amount امروز است؛ یادت نرود.',
          ),
        NotificationTone.serious => (
            title: 'سررسید امروز',
            body: 'قسط «$name» به مبلغ $amount امروز باید پرداخت شود.',
          ),
        NotificationTone.humorous => (
            title: 'امروز روز قسط است! 😬',
            body: '«$name» مبلغ $amount امروز منتظر توست. جیب‌ها آماده؟',
          ),
        NotificationTone.mixed => (
            title: 'قسط امروز: $name',
            body: 'قسط «$name» به مبلغ $amount امروز سررسید است.',
          ),
      };
    case NotificationKind.upcomingInstallment:
      return switch (t) {
        NotificationTone.formal => (
            title: 'قسط نزدیک: $name',
            body: 'قسط «$name» به مبلغ $amount در $date سررسید می‌شود.',
          ),
        NotificationTone.friendly => (
            title: 'یک قسط در راه است',
            body: 'تا $date قسط «$name» ($amount) را باید بپردازی.',
          ),
        NotificationTone.serious => (
            title: 'سررسید پیش رو',
            body: 'قسط «$name» به مبلغ $amount در $date پرداخت‌نی است.',
          ),
        NotificationTone.humorous => (
            title: 'قسط بعدی نزدیک است 🚶',
            body: '«$name» با $amount در $date به سراغت می‌آید.',
          ),
        NotificationTone.mixed => (
            title: 'قسط نزدیک: $name',
            body: 'قسط «$name» به مبلغ $amount در $date سررسید می‌شود.',
          ),
      };
    case NotificationKind.budgetOverrun:
      return switch (t) {
        NotificationTone.formal => (
            title: 'بودجهٔ «$name» تکمیل شد',
            body: 'مخارج این ماه از بودجهٔ «$name» ($amount) عبور کرده است.',
          ),
        NotificationTone.friendly => (
            title: 'بودجه تمام شد! 💸',
            body: 'مخارج «$name» از سقف $amount رد شد. کمی مراقب باشیم.',
          ),
        NotificationTone.serious => (
            title: 'عبور از بودجه: $name',
            body: 'مخارج دستهٔ «$name» از بودجهٔ $amount فراتر رفته است.',
          ),
        NotificationTone.humorous => (
            title: 'بودجه فرار کرد 🏃',
            body: '«$name» با سقف $amount دیگر تاب نمی‌آورد؛ پول‌ها جای دیگری رفتند.',
          ),
        NotificationTone.mixed => (
            title: 'عبور از بودجه: $name',
            body: 'مخارج دستهٔ «$name» از بودجهٔ $amount فراتر رفته است.',
          ),
      };
    case NotificationKind.budgetNearLimit:
      return switch (t) {
        NotificationTone.formal => (
            title: 'نزدیک به سقف بودجه: $name',
            body: 'مخارج این ماه به $percent از بودجهٔ «$name» ($amount) رسیده است.',
          ),
        NotificationTone.friendly => (
            title: 'بودجه نزدیک است! ⚠️',
            body: 'مخارج «$name» به $amount نزدیک می‌شود؛ کمی صرفه‌جویی بد نیست.',
          ),
        NotificationTone.serious => (
            title: 'هشدار بودجه',
            body: 'مصرف بودجهٔ «$name» به حد هشدار ($amount) رسیده است.',
          ),
        NotificationTone.humorous => (
            title: 'بودجه نفس‌ش تنگ شده 😮‍💨',
            body: '«$name» نزدیک سقف $amount است. درهای کیف پول را محکم بگیر.',
          ),
        NotificationTone.mixed => (
            title: 'نزدیک به سقف بودجه: $name',
            body: 'مخارج این ماه به $percent از بودجهٔ «$name» ($amount) رسیده است.',
          ),
      };
    case NotificationKind.goalMilestone:
      if (complete) {
        return switch (t) {
          NotificationTone.formal => (
              title: 'هدف «$name» محقق شد',
              body:
                  'هدف «$name» به‌طور کامل تأمین شد ($amount). این پیشرفت ثبت شد. تبریک!',
            ),
          NotificationTone.friendly => (
              title: 'هدف محقق شد! 🎉',
              body: '«$name» کامل شد؛ $amount جمع شد. آفرین به تو!',
            ),
          NotificationTone.serious => (
              title: 'تحقق هدف: $name',
              body: 'هدف «$name» با مبلغ $amount به‌طور کامل تأمین شد.',
            ),
          NotificationTone.humorous => (
              title: 'هدف تسلیم شد 😏',
              body: '«$name» با $amount کامل شد. پول‌ها جمع شدند و تسلیم شدند!',
            ),
          NotificationTone.mixed => (
              title: 'هدف «$name» محقق شد',
              body: 'هدف «$name» به‌طور کامل تأمین شد ($amount).',
            ),
        };
      }
      return switch (t) {
        NotificationTone.formal => (
            title: 'پیشرفت هدف: $name',
            body:
                'پیشرفت هدف «$name» به $percent از مسیر ($amount) رسیده است. ادامه دهید.',
          ),
        NotificationTone.friendly => (
            title: 'به هدفت نزدیکی 🎯',
            body: '«$name» به $percent رسید؛ ادامه بده!',
          ),
        NotificationTone.serious => (
            title: 'پیشرفت هدف',
            body: 'هدف «$name» به $percent از مسیر ($amount) رسیده است.',
          ),
        NotificationTone.humorous => (
            title: 'هدف داره کم می‌آورد 😎',
            body: '«$name» در $percent است؛ فقط کمی مانده تا پر شود!',
          ),
        NotificationTone.mixed => (
            title: 'پیشرفت هدف: $name',
            body: 'پیشرفت هدف «$name» به $percent از مسیر ($amount) رسیده است.',
          ),
      };
    case NotificationKind.lowBalance:
      return switch (t) {
        NotificationTone.formal => (
            title: 'موجودی آزاد ناکافی',
            body:
                'پول آزاد شما پس از کسر اقساط، بودجه‌ها و ذخیرهٔ اهداف به $amount رسیده است.',
          ),
        NotificationTone.friendly => (
            title: 'کیف پول خالی شده 😟',
            body: 'پول آزادت $amount است؛ مراقب هزینه‌های پیش رو باش.',
          ),
        NotificationTone.serious => (
            title: 'هشدار موجودی',
            body:
                'موجودی آزاد $amount است. خطر کسری در هزینه‌های آتی وجود دارد.',
          ),
        NotificationTone.humorous => (
            title: 'جیب‌ها سوت می‌کشند 🪁',
            body: 'پول آزاد $amount مانده. شاید وقت یک قهوهٔ خانگی است!',
          ),
        NotificationTone.mixed => (
            title: 'هشدار موجودی',
            body: 'موجودی آزاد $amount است. خطر کسری در هزینه‌های آتی وجود دارد.',
          ),
      };
    case NotificationKind.noRecentActivity:
      return switch (t) {
        NotificationTone.formal => (
            title: 'یادآوری ثبت تراکنش',
            body:
                'در ۷ روز گذشته تراکنشی ثبت نشده است. برای داشبورد دقیق، مخارج را ثبت کنید.',
          ),
        NotificationTone.friendly => (
            title: 'مدتی است خبری نیست 👋',
            body: 'یک هفته است تراکنشی ثبت نکرده‌ای. بیا وضعیت را به‌روز کنیم.',
          ),
        NotificationTone.serious => (
            title: 'عدم ثبت تراکنش',
            body: '۷ روز بدون ثبت تراکنش؛ گزارش‌های مالی ممکن است ناقص باشند.',
          ),
        NotificationTone.humorous => (
            title: 'کاشف به خیر! 🕵️',
            body: 'یک هفته هیچ پولی جابه‌جا نشده. آیا واقعاً همه‌چیز مرتب است؟',
          ),
        NotificationTone.mixed => (
            title: 'مدتی است خبری نیست 👋',
            body: 'یک هفته است تراکنشی ثبت نکرده‌ای. بیا وضعیت را به‌روز کنیم.',
          ),
      };
  }
}

/// موتور اعلان‌های هوشمند؛ خالص و بدون وابستگی به UI.
///
/// از دفترکل واقعی و لحن پروفایل کاربر، مجموعه‌ای مرتب‌شده از اعلان‌ها می‌سازد:
/// - اقساط معوق / امروز / سه روز آینده (با عنوان وام)
/// - عبور از بودجه یا نزدیک‌شدن به سقف
/// - تکمیل یا نزدیک‌شدن هدف مالی
/// - موجودی آزاد منفی (پس از رزرو اقساط، بودجه و اهداف)
/// - بی‌فعالیتی یک‌هفته‌ای
/// هر نوع حداکثر یک بار ظاهر می‌شود (dedup) و خروجی بر اساس اهمیت مرتب است.
List<AppNotification> buildNotifications({
  required FinancialLedger ledger,
  required UserProfile profile,
  required DateTime asOf,
  bool quietHours = false,
}) {
  String fmt(int units) => formatMinorUnits(units, suffix: profile.currency.label);

  DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  final DateTime today = dayOnly(asOf);

  String pDate(DateTime d) {
    final JalaliDate j = JalaliDate.fromDateTime(d);
    return '${j.day} ${j.monthName}';
  }

  String loanTitle(String loanId) {
    for (final Loan loan in ledger.loans) {
      if (loan.id == loanId) return loan.title;
    }
    return 'وام';
  }

  final List<AppNotification> out = <AppNotification>[];

  // --- اقساط وام‌های فعال ---
  final List<Installment> overdue = <Installment>[];
  final List<Installment> dueToday = <Installment>[];
  final List<Installment> upcoming = <Installment>[];
  for (final Loan loan in ledger.loans) {
    if (loan.status != LoanStatus.active) continue;
    for (final Installment inst in loan.installments) {
      if (inst.cancelled) continue;
      if (inst.paidAmount.minorUnits >= inst.totalAmount.minorUnits) continue;
      final InstallmentStatus status = inst.statusAt(asOf);
      if (status == InstallmentStatus.overdue) {
        overdue.add(inst);
      } else if (status == InstallmentStatus.dueToday) {
        dueToday.add(inst);
      } else if (!inst.dueDate.isAfter(today.add(const Duration(days: 3)))) {
        upcoming.add(inst);
      }
    }
  }

  if (overdue.isNotEmpty) {
    overdue.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final Installment inst = overdue.first;
    final _Texts texts = _texts(
      kind: NotificationKind.overdueInstallment,
      tone: profile.tone,
      name: loanTitle(inst.loanId),
      amount: fmt(inst.totalAmount.minorUnits),
      date: pDate(inst.dueDate),
      percent: '',
    );
    out.add(AppNotification(
      kind: NotificationKind.overdueInstallment,
      priority: NotificationPriority.urgent,
      title: texts.title,
      body: texts.body,
      createdAt: asOf,
    ));
  }

  if (dueToday.isNotEmpty) {
    dueToday.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final Installment inst = dueToday.first;
    final _Texts texts = _texts(
      kind: NotificationKind.dueInstallment,
      tone: profile.tone,
      name: loanTitle(inst.loanId),
      amount: fmt(inst.totalAmount.minorUnits),
      date: pDate(inst.dueDate),
      percent: '',
    );
    out.add(AppNotification(
      kind: NotificationKind.dueInstallment,
      priority: NotificationPriority.high,
      title: texts.title,
      body: texts.body,
      createdAt: asOf,
    ));
  }

  if (upcoming.isNotEmpty) {
    upcoming.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final Installment inst = upcoming.first;
    final _Texts texts = _texts(
      kind: NotificationKind.upcomingInstallment,
      tone: profile.tone,
      name: loanTitle(inst.loanId),
      amount: fmt(inst.totalAmount.minorUnits),
      date: pDate(inst.dueDate),
      percent: '',
    );
    out.add(AppNotification(
      kind: NotificationKind.upcomingInstallment,
      priority: NotificationPriority.normal,
      title: texts.title,
      body: texts.body,
      createdAt: asOf,
    ));
  }

  // --- بودجه‌های فعال ماه ---
  Budget? worstOverrun;
  int worstOverrunGap = 0;
  Budget? worstNear;
  int worstNearPercent = 0;
  for (final Budget budget in ledger.budgets) {
    if (budget.startDate.isAfter(today) || budget.endDate.isBefore(today)) {
      continue;
    }
    int spent = 0;
    for (final LedgerTransaction tx in ledger.transactions) {
      if (tx.kind != TransactionKind.expense) continue;
      if (budget.category != null && tx.category != budget.category) continue;
      final DateTime d = dayOnly(tx.date);
      if (d.isBefore(dayOnly(budget.startDate)) ||
          d.isAfter(dayOnly(budget.endDate))) {
        continue;
      }
      spent += tx.amount.minorUnits;
    }
    final int limit = budget.amount.minorUnits;
    if (limit <= 0) continue;
    if (spent >= limit) {
      if (spent - limit > worstOverrunGap) {
        worstOverrun = budget;
        worstOverrunGap = spent - limit;
      }
    } else if (spent >= (limit * 0.8).round()) {
      final int pct = (spent * 100 / limit).round();
      if (pct > worstNearPercent) {
        worstNear = budget;
        worstNearPercent = pct;
      }
    }
  }

  if (worstOverrun != null) {
    final _Texts texts = _texts(
      kind: NotificationKind.budgetOverrun,
      tone: profile.tone,
      name: worstOverrun.name,
      amount: fmt(worstOverrun.amount.minorUnits),
      date: '',
      percent: '',
    );
    out.add(AppNotification(
      kind: NotificationKind.budgetOverrun,
      priority: NotificationPriority.high,
      title: texts.title,
      body: texts.body,
      createdAt: asOf,
    ));
  } else if (worstNear != null) {
    final _Texts texts = _texts(
      kind: NotificationKind.budgetNearLimit,
      tone: profile.tone,
      name: worstNear.name,
      amount: fmt(worstNear.amount.minorUnits),
      date: '',
      percent: '${toPersianDigits(worstNearPercent)}٪',
    );
    out.add(AppNotification(
      kind: NotificationKind.budgetNearLimit,
      priority: NotificationPriority.normal,
      title: texts.title,
      body: texts.body,
      createdAt: asOf,
    ));
  }

  // --- اهداف مالی ---
  Goal? completedGoal;
  Goal? nearGoal;
  for (final Goal goal in ledger.goals) {
    if (goal.progress >= 1.0) {
      if (completedGoal == null) completedGoal = goal;
    } else if (goal.progress >= 0.75) {
      if (nearGoal == null) nearGoal = goal;
    }
  }
  final Goal? milestoneGoal = completedGoal ?? nearGoal;
  if (milestoneGoal != null) {
    final bool done = completedGoal != null;
    final int pct = (milestoneGoal.progress * 100).round();
    final _Texts texts = _texts(
      kind: NotificationKind.goalMilestone,
      tone: profile.tone,
      name: milestoneGoal.name,
      amount: fmt(milestoneGoal.target.minorUnits),
      date: '',
      percent: '${toPersianDigits(pct)}٪',
      complete: done,
    );
    out.add(AppNotification(
      kind: NotificationKind.goalMilestone,
      priority: NotificationPriority.normal,
      title: texts.title,
      body: texts.body,
      createdAt: asOf,
    ));
  }

  // --- موجودی آزاد ---
  final Money available = ledger.availableMoney(asOf: asOf);
  if (available.minorUnits < 0) {
    final _Texts texts = _texts(
      kind: NotificationKind.lowBalance,
      tone: profile.tone,
      name: '',
      amount: fmt(available.minorUnits),
      date: '',
      percent: '',
    );
    out.add(AppNotification(
      kind: NotificationKind.lowBalance,
      priority: NotificationPriority.high,
      title: texts.title,
      body: texts.body,
      createdAt: asOf,
    ));
  }

  // --- بی‌فعالیتی ---
  bool anyRecent = false;
  final DateTime cutoff = today.subtract(const Duration(days: 7));
  for (final LedgerTransaction tx in ledger.transactions) {
    if (!dayOnly(tx.date).isBefore(cutoff)) {
      anyRecent = true;
      break;
    }
  }
  if (!anyRecent) {
    final _Texts texts = _texts(
      kind: NotificationKind.noRecentActivity,
      tone: profile.tone,
      name: '',
      amount: '',
      date: '',
      percent: '',
    );
    out.add(AppNotification(
      kind: NotificationKind.noRecentActivity,
      priority: NotificationPriority.low,
      title: texts.title,
      body: texts.body,
      createdAt: asOf,
    ));
  }

  // --- سکوت شبانه: فقط پراهمیت‌ها ---
  if (quietHours && isQuietHour(asOf)) {
    out.removeWhere(
      (n) =>
          n.priority == NotificationPriority.low ||
          n.priority == NotificationPriority.normal,
    );
  }

  out.sort((a, b) {
    final int byRank = b.priority.rank.compareTo(a.priority.rank);
    if (byRank != 0) return byRank;
    return a.kind.index.compareTo(b.kind.index);
  });
  return out;
}
