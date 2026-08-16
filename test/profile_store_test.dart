import 'dart:io';

import 'package:maliiiii/app/data/profile_store.dart';
import 'package:maliiiii/maliiiii.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('profile_store_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('store returns null when no file exists', () async {
    final FileProfileStore store =
        FileProfileStore(File('${tempDir.path}/missing.json'));
    expect(await store.load(), isNull);
  });

  test('save then load round-trips the profile', () async {
    final File file = File('${tempDir.path}/user_profile.json');
    final FileProfileStore store = FileProfileStore(file);
    final UserProfile profile = UserProfile.create(
      firstName: 'علی',
      lastName: 'بهمنی',
      nickname: 'kingof',
      displayMode: DisplayMode.dark,
    );

    await store.save(profile);
    expect(await file.exists(), isTrue);

    final UserProfile? restored = await store.load();
    expect(restored, isNotNull);
    expect(restored!.fullName, 'علی بهمنی');
    expect(restored.displayMode, DisplayMode.dark);
    expect(restored.nickname, 'kingof');
  });

  test('corrupted file is treated as missing profile', () async {
    final File file = File('${tempDir.path}/user_profile.json');
    await file.writeAsString('{not valid json');
    final FileProfileStore store = FileProfileStore(file);
    expect(await store.load(), isNull);
  });
}
