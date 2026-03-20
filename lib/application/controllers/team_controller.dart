import 'package:flutter/material.dart';

import '../../domain/contracts/repositories.dart';
import '../../domain/models/entities.dart';

class TeamController extends ChangeNotifier {
  final EmployeeRepository _employeeRepository;

  TeamController(this._employeeRepository);

  List<Employee> members = [];
  bool loading = false;

  Future<void> load(Employee? employee) async {
    if (employee == null) {
      members = [];
      loading = false;
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();
    members = await _employeeRepository.listTeamMembers(employee);
    loading = false;
    notifyListeners();
  }
}
