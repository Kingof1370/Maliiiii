import 'package:maliiiii/app/data/profile_store.dart';
import 'package:maliiiii/maliiiii.dart';

/// ذخیره‌سازی حافظه‌ای برای تست‌های ویجت (بدون I/O واقعی فایل).
class MemoryProfileStore implements ProfileStore {
  MemoryProfileStore([this._profile]);

  UserProfile? _profile;

  @override
  Future<UserProfile?> load() async => _profile;

  @override
  Future<void> save(UserProfile profile) async {
    _profile = profile;
  }
}
