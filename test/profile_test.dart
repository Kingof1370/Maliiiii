import 'package:maliiiii/maliiiii.dart';
import 'package:test/test.dart';

void main() {
  test('profile requires first and last name', () {
    expect(
      () => UserProfile.create(firstName: '  ', lastName: 'بهمنی'),
      throwsA(isA<ProfileValidationException>()),
    );
    expect(
      () => UserProfile.create(firstName: 'علی', lastName: ''),
      throwsA(isA<ProfileValidationException>()),
    );
  });

  test('profile trims names and exposes display name', () {
    final UserProfile profile = UserProfile.create(
      firstName: '  علی ',
      lastName: ' بهمنی ',
      nickname: 'kingof',
    );
    expect(profile.firstName, 'علی');
    expect(profile.lastName, 'بهمنی');
    expect(profile.fullName, 'علی بهمنی');
    expect(profile.displayName, 'kingof');
    expect(profile.currency, ProfileCurrency.irt);
    expect(profile.tone, NotificationTone.friendly);
  });

  test('profile json round-trip preserves all fields', () {
    final UserProfile original = UserProfile.create(
      firstName: 'علی',
      lastName: 'بهمنی',
      nickname: 'kingof',
      currency: ProfileCurrency.irl,
      tone: NotificationTone.serious,
      displayMode: DisplayMode.dark,
      aiEnabled: true,
    );
    final UserProfile restored = UserProfile.fromJson(original.toJson());
    expect(restored.firstName, original.firstName);
    expect(restored.lastName, original.lastName);
    expect(restored.nickname, original.nickname);
    expect(restored.currency, ProfileCurrency.irl);
    expect(restored.tone, NotificationTone.serious);
    expect(restored.displayMode, DisplayMode.dark);
    expect(restored.aiEnabled, isTrue);
    expect(restored.createdAt, original.createdAt);
  });

  test('fromJson tolerates missing fields with defaults', () {
    final UserProfile restored = UserProfile.fromJson(
      <String, Object?>{'firstName': 'علی', 'lastName': 'بهمنی'},
    );
    expect(restored.currency, ProfileCurrency.irt);
    expect(restored.tone, NotificationTone.friendly);
    expect(restored.aiEnabled, isFalse);
  });

  test('pin hashing is deterministic with salt and never stores raw pin', () {
    final String salt = PinHasher.newSalt();
    final String hashA = PinHasher.hash('1234', salt);
    final String hashB = PinHasher.hash('1234', salt);
    expect(hashA, hashB);
    expect(hashA, isNot(contains('1234')));
    expect(PinHasher.verify('1234', salt, hashA), isTrue);
    expect(PinHasher.verify('9999', salt, hashA), isFalse);
    expect(salt, isNot(hashA));
  });

  test('different salts produce different hashes for same pin', () {
    final String first = PinHasher.hash('1234', PinHasher.newSalt());
    final String second = PinHasher.hash('1234', PinHasher.newSalt());
    expect(first, isNot(second));
  });
}
