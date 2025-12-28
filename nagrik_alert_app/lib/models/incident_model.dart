class IncidentModel {
  final String id;
  final String type;
  final String description;
  final double latitude;
  final double longitude;
  final int severity;
  final String status;
  final String? reporterId;
  final DateTime timestamp;
  final double? distanceMeters;

  IncidentModel({
    required this.id,
    required this.type,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.status,
    this.reporterId,
    required this.timestamp,
    this.distanceMeters,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'Other',
      description: json['description'] ?? '',
      latitude: (json['latitude'] ?? json['lat'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? 0.0).toDouble(),
      severity: json['severity'] ?? 1,
      status: json['status'] ?? 'Unverified',
      reporterId: json['reporter_id'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      distanceMeters: json['distance_meters']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'severity': severity,
      'reporter_id': reporterId ?? 'anon',
    };
  }

  // Helper getters
  bool get isVerified => status == 'Verified';
  bool get isResolved => status == 'Resolved';
  bool get isUnverified => status == 'Unverified';
  
  String get severityLabel {
    switch (severity) {
      case 1: return 'Low';
      case 2: return 'Minor';
      case 3: return 'Moderate';
      case 4: return 'High';
      case 5: return 'Critical';
      default: return 'Unknown';
    }
  }
  
  int get severityColor {
    switch (severity) {
      case 1: return 0xFF4CAF50;
      case 2: return 0xFF8BC34A;
      case 3: return 0xFFFFC107;
      case 4: return 0xFFFF9800;
      case 5: return 0xFFF44336;
      default: return 0xFF9E9E9E;
    }
  }
  
  int get statusColor {
    switch (status) {
      case 'Verified': return 0xFF4CAF50;
      case 'Resolved': return 0xFF2196F3;
      case 'Rejected': return 0xFF9E9E9E;
      default: return 0xFFFFC107;
    }
  }
  
  String get typeEmoji {
    switch (type) {
      case 'Fire': return '🔥';
      case 'Accident': return '🚗';
      case 'Medical': return '🏥';
      case 'Infrastructure': return '🏗️';
      case 'Theft': return '🔒';
      case 'Natural Disaster': return '🌊';
      default: return '⚠️';
    }
  }
}
