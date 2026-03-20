import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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

  double? currentLat;
  double? currentLng;
  bool locationServiceEnabled = false;
  bool locationPermissionGranted = false;
  bool mockLocationDetected = false;
  bool isLoadingLocation = false;
  Branch? detectedBranch;
  Branch? nearestBranch;
  double? nearestBranchDistanceMeters;

  Future<void> load({
    String? employee,
    String? branch,
  }) async {
    if (employee != null) employeeId = employee;
    if (branch != null) branchId = branch;
    history = await _attendanceRepository.getHistory(employeeId);
    corrections = await _attendanceRepository.getCorrections(employeeId);
    checkedIn = history.isNotEmpty && history.first.type == AttendanceType.checkIn;
    await refreshLocation(notify: false);
    notifyListeners();
  }

  Future<void> swipeCheck() async {
    if (checkedIn) {
      await clockOut();
      return;
    }
    await clockIn();
  }

  Future<void> clockIn([AttendanceWorkMode? overrideMode]) async {
    if (checkedIn) return;
    final snapshot = await refreshLocation();
    _throwIfLocationBlocked(snapshot);
    final mode = _resolveWorkMode(snapshot, overrideMode);
    await _attendanceRepository.addRecord(
      employeeId,
      AttendanceType.checkIn,
      DateTime.now(),
      mode,
    );
    await load();
  }

  Future<void> clockOut() async {
    if (!checkedIn) return;
    final snapshot = await refreshLocation();
    _throwIfLocationBlocked(snapshot);
    final mode = history.firstOrNull?.workMode ?? _resolveClockOutMode(snapshot);
    await _attendanceRepository.addRecord(
      employeeId,
      AttendanceType.checkOut,
      DateTime.now(),
      mode,
    );
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
    final snapshot = await refreshLocation();
    if (snapshot.mockLocationDetected) return 'Blocked';
    return snapshot.detectedBranch != null ? 'WFO' : 'WFA';
  }

  Future<bool> isWithinOfficeRadius() async {
    final snapshot = await refreshLocation();
    return snapshot.detectedBranch != null && !snapshot.mockLocationDetected;
  }

  Future<AttendanceLocationSnapshot> refreshLocation({bool notify = true}) async {
    isLoadingLocation = true;
    if (notify) notifyListeners();
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      locationServiceEnabled = serviceEnabled;
      if (!serviceEnabled) {
        locationPermissionGranted = false;
        mockLocationDetected = false;
        detectedBranch = null;
        nearestBranch = null;
        nearestBranchDistanceMeters = null;
        return _snapshot();
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      locationPermissionGranted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (!locationPermissionGranted) {
        mockLocationDetected = false;
        detectedBranch = null;
        nearestBranch = null;
        nearestBranchDistanceMeters = null;
        return _snapshot();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      currentLat = position.latitude;
      currentLng = position.longitude;
      mockLocationDetected = position.isMocked;

      final branches = await _branchRepository.getBranches();
      Branch? matchedBranch;
      Branch? closestBranch;
      double? closestDistance;

      for (final branch in branches) {
        final distance = _distanceMeters(
          position.latitude,
          position.longitude,
          branch.latitude,
          branch.longitude,
        );

        if (closestDistance == null || distance < closestDistance) {
          closestDistance = distance;
          closestBranch = branch;
        }

        if (distance <= branch.radiusMeters) {
          matchedBranch = branch;
          break;
        }
      }

      detectedBranch = matchedBranch;
      nearestBranch = closestBranch;
      nearestBranchDistanceMeters = closestDistance;
      return _snapshot();
    } finally {
      isLoadingLocation = false;
      if (notify) notifyListeners();
    }
  }

  String get locationStatusLabel {
    if (isLoadingLocation) return 'Checking location...';
    if (!locationServiceEnabled) return 'Location service is off';
    if (!locationPermissionGranted) return 'Location permission required';
    if (mockLocationDetected) return 'Mock location detected';
    if (detectedBranch != null) return 'Office area detected';
    if (nearestBranch != null) return 'Outside all branch areas';
    return 'Location unavailable';
  }

  String? get locationStatusDetail {
    if (detectedBranch != null) {
      return 'Detected in ${detectedBranch!.name}';
    }
    if (nearestBranch != null && nearestBranchDistanceMeters != null) {
      final distance = nearestBranchDistanceMeters!.round();
      return 'Nearest branch: ${nearestBranch!.name} ($distance m)';
    }
    return null;
  }

  AttendanceLocationSnapshot _snapshot() {
    return AttendanceLocationSnapshot(
      locationServiceEnabled: locationServiceEnabled,
      locationPermissionGranted: locationPermissionGranted,
      mockLocationDetected: mockLocationDetected,
      detectedBranch: detectedBranch,
      nearestBranch: nearestBranch,
      nearestBranchDistanceMeters: nearestBranchDistanceMeters,
      latitude: currentLat,
      longitude: currentLng,
    );
  }

  void _throwIfLocationBlocked(AttendanceLocationSnapshot snapshot) {
    if (!snapshot.locationServiceEnabled) {
      throw StateError('Please turn on location services before recording attendance.');
    }
    if (!snapshot.locationPermissionGranted) {
      throw StateError('Location permission is required to record attendance.');
    }
    if (snapshot.mockLocationDetected) {
      throw StateError('Mock location was detected. Please disable fake GPS before recording attendance.');
    }
  }

  AttendanceWorkMode _resolveWorkMode(
    AttendanceLocationSnapshot snapshot,
    AttendanceWorkMode? overrideMode,
  ) {
    if (snapshot.detectedBranch != null) return AttendanceWorkMode.office;
    if (overrideMode != null) return overrideMode;
    throw StateError('You are outside all registered branch areas. Choose WFA or Business Trip first.');
  }

  AttendanceWorkMode _resolveClockOutMode(AttendanceLocationSnapshot snapshot) {
    if (snapshot.detectedBranch != null) return AttendanceWorkMode.office;
    return AttendanceWorkMode.wfa;
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

class AttendanceLocationSnapshot {
  final bool locationServiceEnabled;
  final bool locationPermissionGranted;
  final bool mockLocationDetected;
  final Branch? detectedBranch;
  final Branch? nearestBranch;
  final double? nearestBranchDistanceMeters;
  final double? latitude;
  final double? longitude;

  const AttendanceLocationSnapshot({
    required this.locationServiceEnabled,
    required this.locationPermissionGranted,
    required this.mockLocationDetected,
    required this.detectedBranch,
    required this.nearestBranch,
    required this.nearestBranchDistanceMeters,
    required this.latitude,
    required this.longitude,
  });
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
