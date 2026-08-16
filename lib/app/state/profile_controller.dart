import 'package:flutter/foundation.dart';

import '../../src/profile.dart';
import '../data/profile_repository.dart';

/// وضعیت کلی چرخهٔ عمر پروفایل در سطح اپلیکیشن.
enum ProfileStatus { loading, needsOnboarding, locked, ready }

/// کنترل‌کنندهٔ پروفایل؛ تنها مسیر ارتباط UI با لایهٔ داده.
final class ProfileController extends ChangeNotifier {
  ProfileController(this._repository);

  final ProfileRepository _repository;

  ProfileStatus _status = ProfileStatus.loading;
  UserProfile? _profile;
  bool _unlocked = false;

  ProfileStatus get status => _status;
  UserProfile? get profile => _profile;
  bool get unlocked => _unlocked;

  Future<void> init() async {
    final UserProfile? loaded = await _repository.load();
    if (loaded == null) {
      _status = ProfileStatus.needsOnboarding;
    } else {
      _profile = loaded;
      _unlocked = !loaded.hasPin;
      _status = loaded.hasPin ? ProfileStatus.locked : ProfileStatus.ready;
    }
    notifyListeners();
  }

  Future<void> createProfile(UserProfile profile) async {
    _profile = await _repository.update(profile);
    _unlocked = true;
    _status = ProfileStatus.ready;
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) async {
    _profile = await _repository.update(profile);
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    final String salt = PinHasher.newSalt();
    _profile = await _repository.update(
      _profile!.copyWith(
        pinHash: PinHasher.hash(pin, salt),
        pinSalt: salt,
      ),
    );
    notifyListeners();
  }

  Future<void> removePin() async {
    _profile = await _repository.update(
      _profile!.copyWith(pinHash: null, pinSalt: null),
    );
    notifyListeners();
  }

  bool verifyPin(String pin) {
    final UserProfile profile = _profile!;
    final String? salt = profile.pinSalt;
    final String? hash = profile.pinHash;
    return salt != null &&
        hash != null &&
        PinHasher.verify(pin, salt, hash);
  }

  void unlock() {
    if (_profile?.hasPin ?? false) {
      _unlocked = true;
      _status = ProfileStatus.ready;
      notifyListeners();
    }
  }
}
