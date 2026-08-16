import '../../src/profile.dart';
import 'profile_store.dart';

/// مخزن پروفایل با کش حافظه‌ای؛ UI هرگز مستقیم با فایل کار نمی‌کند.
final class ProfileRepository {
  ProfileRepository(this._store);

  final ProfileStore _store;
  UserProfile? _cached;

  Future<UserProfile?> load() async {
    _cached ??= await _store.load();
    return _cached;
  }

  Future<UserProfile> update(UserProfile profile) async {
    await _store.save(profile);
    _cached = profile;
    return profile;
  }
}
