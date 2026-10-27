import '../models/triage_result.dart';

class DemoScenario {
  final String id;
  final String title;
  final String language;
  final String speakerRole;
  final String transcript;
  final TriageResult expectedResult;

  const DemoScenario({
    required this.id,
    required this.title,
    required this.language,
    required this.speakerRole,
    required this.transcript,
    required this.expectedResult,
  });
}

class DemoModeService {
  static List<DemoScenario> getScenarios() {
    return [
      DemoScenario(
        id: 'scenario-eclampsia-lg',
        title: 'Eclampsia / Seizures (Luganda)',
        language: 'Luganda',
        speakerRole: 'Husband / CHW',
        transcript:
            'Nze mukyala wange ali olubuto lwa myezi munaana. Omutwe gubadde gumuluma nnyo n’ebizimba mu maaso, kyokka kati agudde ekifafa atandise okwesika!',
        expectedResult: TriageResult(
          triageLevel: 'CRITICAL',
          overrideTriggered: true,
          detectedSymptoms: [
            'Convulsions / Eclampsia (Okugwa ekifafa)',
            'Severe persistent headache',
            'Facial edema / Pre-eclampsia triad',
          ],
          primaryConcern: 'Eclamptic convulsions in third trimester pregnancy',
          patientAdvice:
              'TEWALI KULINDA! Musse ku luuyi lwa kkono, komawo ku ddwaliro lya Mulago oba HC IV mu bwangu. Temumuwa mazzi mu kamwa!',
          recommendedAction: 'REFERRAL_HOSPITAL',
          urgencyTimeframe: 'IMMEDIATE',
        ),
      ),
      DemoScenario(
        id: 'scenario-bleeding-sw',
        title: 'Antepartum Hemorrhage (Swahili)',
        language: 'Swahili',
        speakerRole: 'Mother / CHW',
        transcript:
            'Mimi nina mimba ya miezi saba na nusu. Ghafla nimetokwa na damu nyingi sana nyekundu na kitambaa kote kimelowa, na tumbo linauma sana.',
        expectedResult: TriageResult(
          triageLevel: 'CRITICAL',
          overrideTriggered: true,
          detectedSymptoms: [
            'Severe vaginal bleeding (Damu nyingi)',
            'Acute abdominal pain',
            'Suspected placental abruption / placenta praevia',
          ],
          primaryConcern: 'Severe Antepartum Hemorrhage with acute pain',
          patientAdvice:
              'HATARI KUBWA: Usitembee kwa miguu. Lala upande wa kushoto na upate usafiri wa haraka (ambulance/boda) kuelekea hospitali ya rufaa mara moja.',
          recommendedAction: 'REFERRAL_HOSPITAL',
          urgencyTimeframe: 'IMMEDIATE',
        ),
      ),
      DemoScenario(
        id: 'scenario-fetal-movement-en',
        title: 'Reduced Fetal Movement (English)',
        language: 'English',
        speakerRole: 'Pregnant Mother',
        transcript:
            'I am 36 weeks pregnant. Since yesterday afternoon I noticed the baby has stopped moving and kicking completely. I have mild stomach tightening.',
        expectedResult: TriageResult(
          triageLevel: 'HIGH',
          overrideTriggered: true,
          detectedSymptoms: [
            'Cessation of fetal movement > 12 hours',
            'Possible fetal distress / placental insufficiency',
            'Mild uterine contractions',
          ],
          primaryConcern: 'Marked reduction in fetal movement at 36 weeks',
          patientAdvice:
              'Immediate clinical fetal heart rate check and ultrasound needed today. Proceed to Health Center IV or Hospital within 2 hours.',
          recommendedAction: 'HEALTH_CENTER_IV',
          urgencyTimeframe: 'WITHIN_24_HOURS',
        ),
      ),
      DemoScenario(
        id: 'scenario-braxton-hicks-en',
        title: 'Routine Discomfort / Braxton-Hicks (English)',
        language: 'English',
        speakerRole: 'First-time Mother',
        transcript:
            'I feel mild lower back ache after walking to the market, and occasional painless tummy tightening. No bleeding, no water broke, and baby is kicking active.',
        expectedResult: TriageResult(
          triageLevel: 'LOW',
          overrideTriggered: false,
          detectedSymptoms: [
            'Physiological lower backache',
            'Benign Braxton-Hicks contractions',
            'Active fetal movement confirmed',
          ],
          primaryConcern: 'Normal third-trimester physiological changes',
          patientAdvice:
              'Rest with feet elevated, drink plenty of clean water, take iron/folate supplements, and attend your next scheduled antenatal clinic visit.',
          recommendedAction: 'HOME_CARE',
          urgencyTimeframe: 'NEXT_ROUTINE_VISIT',
        ),
      ),
    ];
  }
}
