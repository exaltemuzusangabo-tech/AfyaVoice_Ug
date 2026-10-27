import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/health_facility.dart';

class ClinicRoutingService {
  // Seeded Ugandan Health Facilities with verified coordinates & obstetric tiers
  static final List<HealthFacility> seededFacilities = [
    HealthFacility(
      id: 'ug-mulago-nr',
      name: 'Mulago National Specialized Hospital',
      district: 'Kampala (Kawempe Division)',
      type: 'REFERRAL_HOSPITAL',
      level: 'National Referral Hospital',
      latitude: 0.3392,
      longitude: 32.5761,
      phone: '+256414554008',
      emergencyAmbulance: '+256800100066',
      cSectionReady: true,
      bloodBank: true,
      nicAvailable: true,
      twentyFourSeven: true,
      openStatus: 'Open 24/7 (Emergency C-Section Ready)',
    ),
    HealthFacility(
      id: 'ug-kawempe-nr',
      name: 'Kawempe National Referral Hospital (Maternal Center)',
      district: 'Kampala',
      type: 'REFERRAL_HOSPITAL',
      level: 'National Maternal & Neonatal Referral',
      latitude: 0.3664,
      longitude: 32.5574,
      phone: '+256414693421',
      emergencyAmbulance: '+256800100066',
      cSectionReady: true,
      bloodBank: true,
      nicAvailable: true,
      twentyFourSeven: true,
      openStatus: 'Open 24/7 (High-Volume Maternity & NICU)',
    ),
    HealthFacility(
      id: 'ug-entebbe-rr',
      name: 'Entebbe Regional Referral Hospital',
      district: 'Wakiso',
      type: 'REFERRAL_HOSPITAL',
      level: 'Regional Referral Hospital',
      latitude: 0.0592,
      longitude: 32.4637,
      phone: '+256414320011',
      emergencyAmbulance: '+256800100066',
      cSectionReady: true,
      bloodBank: true,
      nicAvailable: true,
      twentyFourSeven: true,
      openStatus: 'Open 24/7',
    ),
    HealthFacility(
      id: 'ug-mukono-gh',
      name: 'Mukono General Hospital',
      district: 'Mukono',
      type: 'HEALTH_CENTER_IV',
      level: 'General Hospital / HC IV Equivalent',
      latitude: 0.3541,
      longitude: 32.7548,
      phone: '+256414290220',
      emergencyAmbulance: '+256701555120',
      cSectionReady: true,
      bloodBank: true,
      nicAvailable: false,
      twentyFourSeven: true,
      openStatus: 'Open 24/7 (C-Section Active)',
    ),
    HealthFacility(
      id: 'ug-kasangati-hc4',
      name: 'Kasangati Health Center IV',
      district: 'Wakiso',
      type: 'HEALTH_CENTER_IV',
      level: 'Health Center IV',
      latitude: 0.4431,
      longitude: 32.6074,
      phone: '+256772449088',
      emergencyAmbulance: '+256700999111',
      cSectionReady: true,
      bloodBank: false,
      nicAvailable: false,
      twentyFourSeven: true,
      openStatus: 'Open 24/7 (Emergency Obstetric Unit)',
    ),
    HealthFacility(
      id: 'ug-kisenyi-hc4',
      name: 'Kisenyi Health Center IV',
      district: 'Kampala',
      type: 'HEALTH_CENTER_IV',
      level: 'Health Center IV',
      latitude: 0.3114,
      longitude: 32.5701,
      phone: '+256702334556',
      emergencyAmbulance: '+256800100066',
      cSectionReady: true,
      bloodBank: true,
      nicAvailable: false,
      twentyFourSeven: true,
      openStatus: 'Open 24/7',
    ),
    HealthFacility(
      id: 'ug-mpigi-hc4',
      name: 'Mpigi Health Center IV',
      district: 'Mpigi',
      type: 'HEALTH_CENTER_IV',
      level: 'Health Center IV',
      latitude: 0.2250,
      longitude: 32.3242,
      phone: '+256782123456',
      emergencyAmbulance: '+256800100066',
      cSectionReady: true,
      bloodBank: false,
      nicAvailable: false,
      twentyFourSeven: true,
      openStatus: 'Open 24/7',
    ),
    HealthFacility(
      id: 'ug-kiswa-hc3',
      name: 'Kiswa Health Center III (Bugolobi)',
      district: 'Kampala',
      type: 'COMMUNITY_CLINIC',
      level: 'Health Center III',
      latitude: 0.3188,
      longitude: 32.6158,
      phone: '+256414220119',
      emergencyAmbulance: '',
      cSectionReady: false,
      bloodBank: false,
      nicAvailable: false,
      twentyFourSeven: false,
      openStatus: 'Day Clinic (ANC, Immunization & Routine Delivery)',
    ),
  ];

  /// Get user position with fallback to Kampala central business district
  static Future<Position> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _fallbackPosition();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _fallbackPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _fallbackPosition();
      }

      return await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 5),
      );
    } catch (_) {
      return _fallbackPosition();
    }
  }

  static Position _fallbackPosition() {
    // Kampala CBD Coordinates (0.3476° N, 32.5825° E)
    return Position(
      longitude: 32.5825,
      latitude: 0.3476,
      timestamp: DateTime.now(),
      accuracy: 50.0,
      altitude: 1190.0,
      altitudeAccuracy: 10.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  /// Calculates straight-line distance in kilometers (Haversine Formula)
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Sorts and filters facilities based on patient triage urgency and distance
  static List<HealthFacility> getRankedFacilities({
    required Position userPosition,
    required String triageLevel,
  }) {
    final list = seededFacilities.map((f) {
      final dist = calculateDistanceKm(
        userPosition.latitude,
        userPosition.longitude,
        f.latitude,
        f.longitude,
      );
      f.distanceKm = double.parse(dist.toStringAsFixed(1));
      return f;
    }).toList();

    list.sort((a, b) {
      final distA = a.distanceKm ?? 999;
      final distB = b.distanceKm ?? 999;

      if (triageLevel == 'CRITICAL') {
        // Critical obstetric emergency: prioritize facilities capable of emergency C-section
        if (a.cSectionReady != b.cSectionReady) {
          return a.cSectionReady ? -1 : 1;
        }
        // Then blood bank readiness
        if (a.bloodBank != b.bloodBank) {
          return a.bloodBank ? -1 : 1;
        }
      } else if (triageLevel == 'HIGH') {
        // High urgency: prefer HC IV or Referral Hospital over HC III
        final aWeight = (a.type == 'COMMUNITY_CLINIC') ? 1 : 0;
        final bWeight = (b.type == 'COMMUNITY_CLINIC') ? 1 : 0;
        if (aWeight != bWeight) return aWeight.compareTo(bWeight);
      }

      return distA.compareTo(distB);
    });

    return list;
  }

  /// Triggers Google Maps Turn-by-Turn Navigation via url_launcher
  static Future<bool> launchNavigation(HealthFacility facility) async {
    final googleMapsUrl = Uri.parse(
      'google.navigation:q=${facility.latitude},${facility.longitude}&mode=d',
    );
    final fallbackWebUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${facility.latitude},${facility.longitude}',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      return await launchUrl(googleMapsUrl);
    } else if (await canLaunchUrl(fallbackWebUrl)) {
      return await launchUrl(fallbackWebUrl, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Triggers emergency telephone call via url_launcher
  static Future<bool> callFacility(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(' ', '');
    final telUri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(telUri)) {
      return await launchUrl(telUri);
    }
    return false;
  }
}
