import 'package:flutter/material.dart';

import '../../domain/contracts/repositories.dart';
import '../../domain/models/entities.dart';

class AppController extends ChangeNotifier {
  final EmployeeRepository _employeeRepository;
  AppController(this._employeeRepository);

  Employee? employee;
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    employee = await _employeeRepository.getCurrentEmployee();
    loading = false;
    notifyListeners();
  }

  void clear() {
    employee = null;
    loading = false;
    notifyListeners();
  }
}
