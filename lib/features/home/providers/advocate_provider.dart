import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/advocate_profile.dart';

final advocateBoxProvider = FutureProvider<Box<AdvocateProfile>>((ref) async {
  return Hive.openBox<AdvocateProfile>('advocate_profile');
});

final advocateProfileProvider = FutureProvider<AdvocateProfile?>((ref) async {
  final box = await ref.watch(advocateBoxProvider.future);
  final profiles = box.values.toList();
  if (profiles.isEmpty) return null;
  return profiles.first;
});

class AdvocateActions {
  final Ref ref;

  AdvocateActions(this.ref);

  Future<void> saveProfile(AdvocateProfile profile) async {
    final box = await ref.read(advocateBoxProvider.future);
    await box.put(profile.id, profile);
    ref.invalidate(advocateProfileProvider);
  }

  Future<void> deleteProfile() async {
    final box = await ref.read(advocateBoxProvider.future);
    await box.clear();
    ref.invalidate(advocateProfileProvider);
  }
}

final advocateActionsProvider = Provider<AdvocateActions>((ref) {
  return AdvocateActions(ref);
});

final defaultAdvocateProvider = Provider<AdvocateProfile>((ref) {
  return const AdvocateProfile(
    id: 'default',
    name: 'Adv. Rujan Khiuju',
    barNumber: 'NBC 12345',
    specialization: 'Constitutional & Criminal Law',
    firmName: 'Khiuju Law Chambers',
    address: 'Kathmandu, Nepal',
    phone: '+977-98XXXXXXXX',
    email: 'rujan@khiujulaw.com',
    bio:
        'Practicing advocate at the Supreme Court of Nepal with over a decade of experience in constitutional, criminal, and civil litigation. Committed to accessible legal aid and justice reform through technology.',
  );
});
