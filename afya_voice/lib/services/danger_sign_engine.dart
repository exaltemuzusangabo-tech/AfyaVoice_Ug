/// Deterministic WHO/MoH Maternal Obstetric Danger Sign Engine
/// Highest priority clinical rule: If any danger sign is matched,
/// triage urgency is immediately escalated to CRITICAL or HIGH,
/// overriding any potential model downgrade.
class DangerSignResult {
  final bool hasDangerSign;
  final String severity; // CRITICAL | HIGH | NONE
  final List<String> matchedSigns;
  final String recommendedAction;
  final String clinicalRationale;

  const DangerSignResult({
    required this.hasDangerSign,
    required this.severity,
    required this.matchedSigns,
    required this.recommendedAction,
    required this.clinicalRationale,
  });

  static const DangerSignResult none = DangerSignResult(
    hasDangerSign: false,
    severity: 'NONE',
    matchedSigns: [],
    recommendedAction: 'HOME_CARE',
    clinicalRationale: 'No immediate WHO obstetric danger signs identified.',
  );
}

class DangerSignEngine {
  static DangerSignResult evaluate(String input) {
    if (input.trim().isEmpty) return DangerSignResult.none;

    final lower = input.toLowerCase();
    final List<String> matched = [];
    String severity = 'NONE';

    // 1. Severe Vaginal Bleeding (Antepartum Hemorrhage / Placenta Praevia / Abruption)
    const bleedingTerms = [
      'kuvaamu omusaayi', 'omusaayi', 'damu nyingi', 'kutokwa damu',
      'heavy bleeding', 'vaginal bleeding', 'soaking pads', 'blood clots', 'hemorrhage'
    ];
    if (bleedingTerms.any((term) => lower.contains(term))) {
      matched.add('Severe Vaginal Bleeding (Kuvaamu omusaayi / Damu nyingi)');
      severity = 'CRITICAL';
    }

    // 2. Convulsions / Seizures / Fits (Eclampsia)
    const convulsionTerms = [
      'kifafa', 'okugwa ekifafa', 'okwesika', 'dege dege', 'kifafa cha mimba',
      'seizure', 'convulsion', 'fits', 'unconscious', 'fainted', 'blackout'
    ];
    if (convulsionTerms.any((term) => lower.contains(term))) {
      matched.add('Convulsions / Seizures (Eclampsia risk)');
      severity = 'CRITICAL';
    }

    // 3. Severe Persistent Headache with Blurred Vision & Facial Edema (Pre-Eclampsia)
    const headacheTerms = [
      'mutwe ogulumwa nnyo', 'omutwe ogwamaanyi', 'kichwa kuuma sana', 'kichwa kizito',
      'severe headache', 'blurred vision', 'swollen face', 'swollen hands', 'ebizimba mu maaso'
    ];
    if (headacheTerms.any((term) => lower.contains(term))) {
      matched.add('Severe Headache & Visual Disturbance (Severe Pre-eclampsia warning)');
      if (severity != 'CRITICAL') severity = 'HIGH';
    }

    // 4. High Fever with Chills / Shivering (Severe Sepsis / Chorioamnionitis / Severe Malaria)
    const feverTerms = [
      'omusujja gw\'amaanyi', 'omusujja ogukankanya', 'homa kali', 'kutetemeka',
      'high fever', 'chills', 'rigors', 'shivering violently', 'burning fever'
    ];
    if (feverTerms.any((term) => lower.contains(term))) {
      matched.add('High Fever with Chills (Maternal Sepsis / Severe Malaria)');
      if (severity != 'CRITICAL') severity = 'HIGH';
    }

    // 5. Severe Abdominal Pain (Uterine Rupture / Abruption)
    const painTerms = [
      'ekinyena', 'olubuto oluluma ennyo', 'tumbo kuuma sana', 'uchungu mkali',
      'severe abdominal pain', 'constant acute pain', 'rigid belly', 'sharp stabbing stomach pain'
    ];
    if (painTerms.any((term) => lower.contains(term))) {
      matched.add('Severe Acute Abdominal Pain (Ekinyena / Tumbo kuuma sana)');
      if (severity != 'CRITICAL') severity = 'HIGH';
    }

    // 6. Fluid Leaking / Premature Rupture of Membranes
    const fluidTerms = [
      'okuvaamu amazzi', 'amazzi gamenyese', 'maji kutoka', 'kupatwa na maji',
      'fluid leaking', 'water broke', 'gush of water', 'ruptured membranes'
    ];
    if (fluidTerms.any((term) => lower.contains(term))) {
      matched.add('Premature Rupture of Membranes / Fluid Leaking (Okuvaamu amazzi)');
      if (severity != 'CRITICAL') severity = 'HIGH';
    }

    // 7. Absence of Fetal Movement in Late Pregnancy
    const movementTerms = [
      'omwana takyanyeera', 'omwana taseyeeya', 'mtoto hasogei', 'mtoto hatikisiki',
      'baby not moving', 'no fetal movement', 'stopped kicking', 'no baby kicks'
    ];
    if (movementTerms.any((term) => lower.contains(term))) {
      matched.add('Marked Reduction or Cessation of Fetal Movement (Mtoto hasogei)');
      if (severity != 'CRITICAL') severity = 'HIGH';
    }

    if (matched.isEmpty) {
      return DangerSignResult.none;
    }

    final isCritical = severity == 'CRITICAL';
    return DangerSignResult(
      hasDangerSign: true,
      severity: severity,
      matchedSigns: matched,
      recommendedAction: isCritical ? 'REFERRAL_HOSPITAL' : 'HEALTH_CENTER_IV',
      clinicalRationale: 'Mandatory WHO/MoH Obstetric Danger Sign matched: ${matched.join("; ")}',
    );
  }
}
