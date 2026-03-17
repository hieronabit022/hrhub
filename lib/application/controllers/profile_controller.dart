import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/contracts/repositories.dart';
import '../../domain/models/entities.dart';

class ProfileController extends ChangeNotifier {
  final ProfileRepository _profileRepository;
  final NotificationRepository _notificationRepository;
  final Uuid _uuid = const Uuid();

  ProfileController(this._profileRepository, this._notificationRepository);

  Profile? profile;
  String employeeId = 'emp-1';

  Future<void> load([String? employee]) async {
    if (employee != null) employeeId = employee;
    profile = await _profileRepository.get(employeeId);
    notifyListeners();
  }

  Future<void> updatePersonal({
    required String email,
    required String address,
  }) async {
    if (profile == null) return;
    profile = await _profileRepository.update(
      profile!.copyWith(personalEmail: email, address: address),
    );
    await _notificationRepository.add(
      AppNotification(
        id: _uuid.v4(),
        employeeId: employeeId,
        title: 'Profile Updated',
        body: 'Your personal profile has been updated.',
        deepLink: '/profile',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> updateContact({
    required String phone,
    required String emergencyContact,
  }) async {
    if (profile == null) return;
    profile = await _profileRepository.update(
      profile!.copyWith(phone: phone, emergencyContact: emergencyContact),
    );
    notifyListeners();
  }
}
