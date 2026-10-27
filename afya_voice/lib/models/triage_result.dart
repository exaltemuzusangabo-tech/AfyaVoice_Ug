class TriageResult {
  final String triageLevel; // CRITICAL | HIGH | MEDIUM | LOW
  final bool overrideTriggered;
  final List<String> detectedSymptoms;
  final String primaryConcern;
  final String patientAdvice;
  final String recommendedAction; // REFERRAL_HOSPITAL | HEALTH_CENTER_IV | COMMUNITY_CLINIC | HOME_CARE
  final String urgencyTimeframe; // IMMEDIATE | WITHIN_24_HOURS | NEXT_ROUTINE_VISIT
  final DateTime timestamp;
  final String rawInput;

  TriageResult({
    required this.triageLevel,
    required this.overrideTriggered,
    required this.detectedSymptoms,
    required this.primaryConcern,
    required this.patientAdvice,
    required this.recommendedAction,
    required this.urgencyTimeframe,
    DateTime? timestamp,
    this.rawInput = '',
  }) : timestamp = timestamp ?? DateTime.now();

  factory TriageResult.fromJson(Map<String, dynamic> json, {String rawInput = ''}) {
    return TriageResult(
      triageLevel: (json['triage_level'] as String? ?? 'HIGH').toUpperCase(),
      overrideTriggered: json['override_triggered'] as bool? ?? false,
      detectedSymptoms: (json['detected_symptoms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      primaryConcern: json['primary_concern'] as String? ?? 'Obstetric triage assessment pending',
      patientAdvice: json['patient_advice'] as String? ?? 'Please consult a registered midwife or medical officer.',
      recommendedAction: (json['recommended_action'] as String? ?? 'HEALTH_CENTER_IV').toUpperCase(),
      urgencyTimeframe: (json['urgency_timeframe'] as String? ?? 'IMMEDIATE').toUpperCase(),
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      rawInput: rawInput.isNotEmpty ? rawInput : (json['raw_input'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'triage_level': triageLevel,
      'override_triggered': overrideTriggered,
      'detected_symptoms': detectedSymptoms,
      'primary_concern': primaryConcern,
      'patient_advice': patientAdvice,
      'recommended_action': recommendedAction,
      'urgency_timeframe': urgencyTimeframe,
      'timestamp': timestamp.toIso8601String(),
      'raw_input': rawInput,
    };
  }

  bool get isImmediateEmergency =>
      triageLevel == 'CRITICAL' || urgencyTimeframe == 'IMMEDIATE';
}
