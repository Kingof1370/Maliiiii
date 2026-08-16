import 'package:flutter/material.dart';

import '../design/app_dimensions.dart';
import '../state/profile_scope.dart';
import '../widgets/profile_form.dart';

/// ویرایش پروفایل؛ فیلدها از پروفایل فعلی پرشده‌اند.
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ویرایش پروفایل')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: <Widget>[
          ProfileForm(
            initial: ProfileScope.of(context).profile,
            submitLabel: 'ذخیره',
            onDone: (profile) async {
              await ProfileScope.of(context).updateProfile(profile);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: AppDimensions.spaceMd),
        ],
      ),
    );
  }
}
