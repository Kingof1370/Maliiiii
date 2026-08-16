import 'dart:convert';
import 'dart:io';

import '../../src/profile.dart';

/// مرز ذخیره‌سازی پروفایل؛ پیاده‌سازی فایل برای اجرای آفلاین و تست‌پذیری.
abstract interface class ProfileStore {
  Future<UserProfile?> load();

  Future<void> save(UserProfile profile);
}

/// ذخیره‌سازی JSON روی فایل محلی با نوشتن اتمیک (فایل موقت + rename).
final class FileProfileStore implements ProfileStore {
  FileProfileStore(this.file);

  final File file;

  @override
  Future<UserProfile?> load() async {
    if (!await file.exists()) return null;
    try {
      final String raw = await file.readAsString();
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return null;
      final UserProfile profile = UserProfile.fromJson(decoded);
      if (profile.firstName.isEmpty || profile.lastName.isEmpty) return null;
      return profile;
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<void> save(UserProfile profile) async {
    await file.parent.create(recursive: true);
    final File temp = File('${file.path}.tmp');
    await temp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(profile.toJson()),
      flush: true,
    );
    await temp.rename(file.path);
  }
}
