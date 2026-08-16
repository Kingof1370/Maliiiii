import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// واحد پول نمایشی کاربر. منطق مالی همچنان با واحد صحیح کوچک کار می‌کند
/// و این enum فقط «تومان» یا «ریال» بودن نمایش را تعیین می‌کند.
enum ProfileCurrency { irt, irl }

extension ProfileCurrencyX on ProfileCurrency {
  String get label => switch (this) {
        ProfileCurrency.irt => 'تومان',
        ProfileCurrency.irl => 'ریال',
      };

  String get code => switch (this) {
        ProfileCurrency.irt => 'IRT',
        ProfileCurrency.irl => 'IRR',
      };

  static ProfileCurrency fromCode(String? code) =>
      code == ProfileCurrency.irl.code ? ProfileCurrency.irl : ProfileCurrency.irt;
}

/// لحن اعلان‌ها؛ در فاز «هوش اعلان» به موتور اعلان متصل می‌شود.
enum NotificationTone { formal, friendly, serious, humorous, mixed }

extension NotificationToneX on NotificationTone {
  String get label => switch (this) {
        NotificationTone.formal => 'رسمی',
        NotificationTone.friendly => 'دوستانه',
        NotificationTone.serious => 'جدی',
        NotificationTone.humorous => 'طنز',
        NotificationTone.mixed => 'ترکیبی',
      };

  static NotificationTone fromName(String? name) => NotificationTone.values
      .firstWhere(
        (tone) => tone.name == name,
        orElse: () => NotificationTone.friendly,
      );
}

/// حالت نمایش برنامه.
enum DisplayMode { system, light, dark }

extension DisplayModeX on DisplayMode {
  String get label => switch (this) {
        DisplayMode.system => 'سیستم',
        DisplayMode.light => 'روشن',
        DisplayMode.dark => 'تاریک',
      };

  static DisplayMode fromName(String? name) => DisplayMode.values.firstWhere(
        (mode) => mode.name == name,
        orElse: () => DisplayMode.system,
      );
}

final class ProfileValidationException implements Exception {
  ProfileValidationException(this.message);

  final String message;

  @override
  String toString() => 'ProfileValidationException: $message';
}

/// پروفایل محلی کاربر. نام و نام خانوادگی ضروری‌اند.
final class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.lastName,
    this.nickname,
    this.currency = ProfileCurrency.irt,
    this.tone = NotificationTone.friendly,
    this.displayMode = DisplayMode.system,
    this.aiEnabled = false,
    this.pinHash,
    this.pinSalt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.create({
    required String firstName,
    required String lastName,
    String? nickname,
    ProfileCurrency currency = ProfileCurrency.irt,
    NotificationTone tone = NotificationTone.friendly,
    DisplayMode displayMode = DisplayMode.system,
    bool aiEnabled = false,
  }) {
    validate(firstName: firstName, lastName: lastName);
    final String now = DateTime.now().toUtc().toIso8601String();
    return UserProfile(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      nickname: nickname?.trim(),
      currency: currency,
      tone: tone,
      displayMode: displayMode,
      aiEnabled: aiEnabled,
      createdAt: now,
      updatedAt: now,
    );
  }

  final String firstName;
  final String lastName;
  final String? nickname;
  final ProfileCurrency currency;
  final NotificationTone tone;
  final DisplayMode displayMode;
  final bool aiEnabled;

  /// هش SHA-256 رمز PIN با salt؛ رمز خام هرگز ذخیره نمی‌شود.
  final String? pinHash;
  final String? pinSalt;
  final String createdAt;
  final String updatedAt;

  static void validate({required String firstName, required String lastName}) {
    if (firstName.trim().isEmpty) {
      throw ProfileValidationException('نام نمی‌تواند خالی باشد.');
    }
    if (lastName.trim().isEmpty) {
      throw ProfileValidationException('نام خانوادگی نمی‌تواند خالی باشد.');
    }
  }

  String get fullName => '$firstName $lastName';

  String get displayName => nickname == null || nickname!.isEmpty
      ? firstName
      : nickname!;

  bool get hasPin => pinHash != null && pinSalt != null;

  static const Object _unset = Object();

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? nickname,
    bool clearNickname = false,
    ProfileCurrency? currency,
    NotificationTone? tone,
    DisplayMode? displayMode,
    bool? aiEnabled,
    Object? pinHash = _unset,
    Object? pinSalt = _unset,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nickname: clearNickname ? null : (nickname ?? this.nickname),
      currency: currency ?? this.currency,
      tone: tone ?? this.tone,
      displayMode: displayMode ?? this.displayMode,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      pinHash: identical(pinHash, _unset) ? this.pinHash : pinHash as String?,
      pinSalt: identical(pinSalt, _unset) ? this.pinSalt : pinSalt as String?,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'firstName': firstName,
        'lastName': lastName,
        'nickname': nickname,
        'currency': currency.code,
        'tone': tone.name,
        'displayMode': displayMode.name,
        'aiEnabled': aiEnabled,
        'pinHash': pinHash,
        'pinSalt': pinSalt,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory UserProfile.fromJson(Map<String, Object?> json) {
    return UserProfile(
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      nickname: json['nickname'] as String?,
      currency: ProfileCurrencyX.fromCode(json['currency'] as String?),
      tone: NotificationToneX.fromName(json['tone'] as String?),
      displayMode: DisplayModeX.fromName(json['displayMode'] as String?),
      aiEnabled: json['aiEnabled'] as bool? ?? false,
      pinHash: json['pinHash'] as String?,
      pinSalt: json['pinSalt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

/// هش‌کنندهٔ رمز PIN با salt تصادفی؛ تعیین‌پذیر و قابل تست.
abstract final class PinHasher {
  static String newSalt() {
    final Random random = Random.secure();
    return List<String>.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  static String hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  static bool verify(String pin, String salt, String expectedHash) =>
      hash(pin, salt) == expectedHash;
}
