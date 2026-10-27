class HealthFacility {
  final String id;
  final String name;
  final String district;
  final String type; // REFERRAL_HOSPITAL | HEALTH_CENTER_IV | COMMUNITY_CLINIC
  final String level;
  final double latitude;
  final double longitude;
  final String phone;
  final String emergencyAmbulance;
  final bool cSectionReady;
  final bool bloodBank;
  final bool nicAvailable;
  final bool twentyFourSeven;
  final String openStatus;
  double? distanceKm;

  HealthFacility({
    required this.id,
    required this.name,
    required this.district,
    required this.type,
    required this.level,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.emergencyAmbulance,
    required this.cSectionReady,
    required this.bloodBank,
    required this.nicAvailable,
    required this.twentyFourSeven,
    required this.openStatus,
    this.distanceKm,
  });

  factory HealthFacility.fromJson(Map<String, dynamic> json) {
    return HealthFacility(
      id: json['id'] as String,
      name: json['name'] as String,
      district: json['district'] as String,
      type: json['type'] as String,
      level: json['level'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'] as String? ?? '',
      emergencyAmbulance: json['emergencyAmbulance'] as String? ?? '',
      cSectionReady: json['cSectionReady'] as bool? ?? false,
      bloodBank: json['bloodBank'] as bool? ?? false,
      nicAvailable: json['nicAvailable'] as bool? ?? false,
      twentyFourSeven: json['twentyFourSeven'] as bool? ?? true,
      openStatus: json['openStatus'] as String? ?? 'Open 24/7',
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'district': district,
      'type': type,
      'level': level,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'emergencyAmbulance': emergencyAmbulance,
      'cSectionReady': cSectionReady,
      'bloodBank': bloodBank,
      'nicAvailable': nicAvailable,
      'twentyFourSeven': twentyFourSeven,
      'openStatus': openStatus,
      'distanceKm': distanceKm,
    };
  }
}
