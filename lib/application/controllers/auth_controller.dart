import 'package:flutter/material.dart';

import '../../domain/contracts/repositories.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _repo;

  AuthController(this._repo);

  bool _loading = false;
  bool get loading => _loading;

  bool _authenticated = false;
  bool get authenticated => _authenticated;

  String phone = '';
  String otp = '';

  Future<void> init() async {
    _authenticated = await _repo.isLoggedIn();
    notifyListeners();
  }

  Future<void> requestOtp(String value) async {
    _loading = true;
    notifyListeners();
    phone = value;
    await _repo.requestOtp(value);
    _loading = false;
    notifyListeners();
  }

  Future<bool> verifyOtp(String value) async {
    _loading = true;
    notifyListeners();
    otp = value;
    final ok = await _repo.verifyOtp(phone, value);
    _authenticated = ok;
    _loading = false;
    notifyListeners();
    return ok;
  }

  Future<void> logout() async {
    await _repo.clearSession();
    _authenticated = false;
    notifyListeners();
  }
}
