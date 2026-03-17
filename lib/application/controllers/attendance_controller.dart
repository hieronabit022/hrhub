import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/contracts/repositories.dart';
import '../../domain/models/entities.dart';

class AttendanceController extends ChangeNotifier {
  final AttendanceRepository _attendanceRepository;
  final BranchRepository _branchRepository;

  AttendanceController(this._attendanceRepository, this._branchRepository);

  String employeeId = 'emp-1';
  String branchId = 'br-jkt';
  List<AttendanceRecord> history = [];
  List<AttendanceCorrection> corrections = [];
  bool checkedIn = false;

  double currentLat = -6.200000;
  double currentLng = 106.816666;

  Future<void> load({
    String? employee,
    String? branch,
  }) async {
    if (employee != null) employeeId = employee;
    if (branch != null) branchId = branch;
    history = await _attendanceRepository.getHistory(employeeId);
    corrections = await _attendanceRepository.getCorrections(employeeId);
    checkedIn = history.isNotEmpty && history.first.type == AttendanceType.checkIn;
    notifyListeners();
  }

  Future<void> swipeCheck() async {
    final type = checkedIn ? AttendanceType.checkOut : AttendanceType.checkIn;
    await _attendanceRepository.addRecord(employeeId, type, DateTime.now());
    await load();
  }

  Future<void> clockIn() async {
    if (checkedIn) return;
    await _attendanceRepository.addRecord(employeeId, AttendanceType.checkIn, DateTime.now());
    await load();
  }

  Future<void> clockOut() async {
    if (!checkedIn) return;
    await _attendanceRepository.addRecord(employeeId, AttendanceType.checkOut, DateTime.now());
    await load();
  }

  Future<void> createCorrection(
    DateTime date,
    AttendanceCorrectionType correctionType,
    String reason,
  ) async {
    await _attendanceRepository.createCorrection(
      employeeId,
      date,
      correctionType,
      reason,
    );
    await load();
  }

  Future<String> wfoWfaLabel() async {
    final inOffice = await isWithinOfficeRadius();
    return inOffice ? 'WFO' : 'WFA';
  }

  Future<bool> isWithinOfficeRadius() async {
    final branches = await _branchRepository.getBranches();
    Branch? branch;
    for (final item in branches) {
      if (item.id == branchId) {
        branch = item;
        break;
      }
    }
    if (branch == null) return false;
    final dist = _distanceMeters(
      currentLat,
      currentLng,
      branch.latitude,
      branch.longitude,
    );
    return dist <= branch.radiusMeters;
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = pow(sin(dLat / 2), 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * pow(sin(dLon / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRad(double v) => v * pi / 180;
}
