import 'package:flutter/material.dart';
import '../models/incident_model.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';

enum IncidentStatus {
  initial,
  loading,
  loaded,
  error,
}

class IncidentProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  IncidentStatus _status = IncidentStatus.initial;
  List<IncidentModel> _incidents = [];
  List<IncidentModel> _nearbyIncidents = [];
  Map<String, dynamic>? _statistics;
  String? _errorMessage;
  String? _deviceId;
  
  // Keep track of locally reported incidents (persist even if API fails)
  final List<IncidentModel> _localIncidents = [];

  IncidentStatus get status => _status;
  List<IncidentModel> get incidents => [..._localIncidents, ..._incidents];
  List<IncidentModel> get nearbyIncidents => _nearbyIncidents;
  Map<String, dynamic>? get statistics => _statistics;
  String? get errorMessage => _errorMessage;

  // Filter getters (include local incidents)
  List<IncidentModel> get verifiedIncidents =>
      incidents.where((i) => i.isVerified).toList();
  List<IncidentModel> get unverifiedIncidents =>
      incidents.where((i) => i.isUnverified).toList();
  List<IncidentModel> get resolvedIncidents =>
      incidents.where((i) => i.isResolved).toList();
  List<IncidentModel> get criticalIncidents =>
      incidents.where((i) => i.severity >= 4).toList();

  IncidentProvider() {
    _initDeviceId();
  }

  Future<void> _initDeviceId() async {
    _deviceId = await DeviceService.getDeviceId();
  }

  // Load all incidents from API
  Future<void> loadIncidents({
    String? status,
    String? type,
    int? severityMin,
  }) async {
    try {
      _status = IncidentStatus.loading;
      notifyListeners();

      final apiIncidents = await _apiService.getIncidents(
        status: status,
        incidentType: type,
        severityMin: severityMin,
      );
      
      // Merge with local incidents (remove duplicates by ID)
      final localIds = _localIncidents.map((i) => i.id).toSet();
      _incidents = apiIncidents.where((i) => !localIds.contains(i.id)).toList();

      _status = IncidentStatus.loaded;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      // Keep local incidents even if API fails
      _status = IncidentStatus.loaded;
      _incidents = [];
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Load nearby incidents
  Future<void> loadNearbyIncidents({
    required double latitude,
    required double longitude,
    int radiusMeters = 1000,
  }) async {
    try {
      _status = IncidentStatus.loading;
      notifyListeners();

      _nearbyIncidents = await _apiService.getNearbyIncidents(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );

      _status = IncidentStatus.loaded;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      // Use local incidents as nearby if API fails
      _status = IncidentStatus.loaded;
      _nearbyIncidents = [..._localIncidents];
      notifyListeners();
    }
  }

  // Report a new incident
  Future<IncidentModel?> reportIncident({
    required String type,
    required String description,
    required double latitude,
    required double longitude,
    required int severity,
    required String reporterId,
  }) async {
    try {
      _status = IncidentStatus.loading;
      notifyListeners();

      if (_deviceId == null) {
        _deviceId = await DeviceService.getDeviceId();
      }

      final incident = await _apiService.reportIncident(
        type: type,
        description: description,
        latitude: latitude,
        longitude: longitude,
        severity: severity,
        reporterId: reporterId,
        deviceId: _deviceId!,
      );

      // Add to LOCAL list so it persists
      _localIncidents.insert(0, incident);
      
      _status = IncidentStatus.loaded;
      _errorMessage = null;
      notifyListeners();
      
      // Update statistics locally
      _updateLocalStatistics();
      
      return incident;
    } catch (e) {
      _status = IncidentStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // Update incident status (Admin)
  Future<bool> updateIncidentStatus({
    required String incidentId,
    required String newStatus,
    required String adminId,
  }) async {
    try {
      await _apiService.updateIncidentStatus(
        incidentId: incidentId,
        newStatus: newStatus,
        adminId: adminId,
      );

      // Update in local list
      final localIndex = _localIncidents.indexWhere((i) => i.id == incidentId);
      if (localIndex != -1) {
        final old = _localIncidents[localIndex];
        _localIncidents[localIndex] = IncidentModel(
          id: old.id,
          type: old.type,
          description: old.description,
          latitude: old.latitude,
          longitude: old.longitude,
          severity: old.severity,
          status: newStatus,
          reporterId: old.reporterId,
          timestamp: old.timestamp,
        );
      }

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      // Still update locally even if API fails
      final localIndex = _localIncidents.indexWhere((i) => i.id == incidentId);
      if (localIndex != -1) {
        final old = _localIncidents[localIndex];
        _localIncidents[localIndex] = IncidentModel(
          id: old.id,
          type: old.type,
          description: old.description,
          latitude: old.latitude,
          longitude: old.longitude,
          severity: old.severity,
          status: newStatus,
          reporterId: old.reporterId,
          timestamp: old.timestamp,
        );
        notifyListeners();
        return true;
      }
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      _statistics = await _apiService.getStatistics();
      notifyListeners();
    } catch (e) {
      // Calculate from local data
      _updateLocalStatistics();
    }
  }
  
  // Update statistics from local data
  void _updateLocalStatistics() {
    final allIncidents = incidents;
    final typeCount = <String, int>{};
    for (var incident in allIncidents) {
      typeCount[incident.type] = (typeCount[incident.type] ?? 0) + 1;
    }
    
    _statistics = {
      'total_incidents': allIncidents.length,
      'last_24_hours': allIncidents.where((i) => 
        DateTime.now().difference(i.timestamp).inHours < 24
      ).length,
      'by_status': {
        'verified': verifiedIncidents.length,
        'unverified': unverifiedIncidents.length,
        'resolved': resolvedIncidents.length,
      },
      'by_type': typeCount,
    };
    notifyListeners();
  }

  // Get audit trail
  Future<List<Map<String, dynamic>>> getAuditTrail(String incidentId) async {
    try {
      return await _apiService.getAuditTrail(incidentId);
    } catch (e) {
      return [];
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh all data
  Future<void> refresh() async {
    await loadIncidents();
    await loadStatistics();
  }
  
  // Clear all local data
  void clearLocalData() {
    _localIncidents.clear();
    _incidents.clear();
    _statistics = null;
    notifyListeners();
  }
}
