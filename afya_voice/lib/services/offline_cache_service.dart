import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/triage_result.dart';

class OfflineCacheService {
  static const String keyUserConsent = 'afya_voice_user_consent_v1';
  static const String keyPreferredLanguage = 'afya_voice_language';
  static const String keyTriageHistory = 'afya_voice_triage_history';

  static Future<bool> hasUserConsented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyUserConsent) ?? false;
  }

  static Future<void> setUserConsent(bool consented) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyUserConsent, consented);
  }

  static Future<String> getPreferredLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyPreferredLanguage) ?? 'en';
  }

  static Future<void> setPreferredLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyPreferredLanguage, langCode);
  }

  static Future<void> saveTriageResult(TriageResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJson = prefs.getStringList(keyTriageHistory) ?? [];
      final newItem = jsonEncode(result.toJson());
      existingJson.insert(0, newItem);
      // Keep last 20 offline records
      if (existingJson.length > 20) {
        existingJson.removeRange(20, existingJson.length);
      }
      await prefs.setStringList(keyTriageHistory, existingJson);
    } catch (_) {}
  }

  static Future<List<TriageResult>> getCachedTriageHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJson = prefs.getStringList(keyTriageHistory) ?? [];
      return existingJson
          .map((item) => TriageResult.fromJson(jsonDecode(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Seeded WHO Maternal Obstetric Danger Signs cached locally
  static List<Map<String, String>> getCachedDangerChecklist() {
    return [
      {
        'title': 'Severe Vaginal Bleeding',
        'luganda': 'Kuvaamu omusaayi omunji',
        'swahili': 'Kutokwa na damu nyingi',
        'action': 'Immediate referral to hospital (Placenta Praevia / Abruption)',
        'urgency': 'CRITICAL',
      },
      {
        'title': 'Convulsions & Fits (Eclampsia)',
        'luganda': 'Okugwa ekifafa / Okwesika',
        'swahili': 'Kifafa cha mimba / Dege dege',
        'action': 'Emergency transport, keep airway clear on left side, do not give liquids',
        'urgency': 'CRITICAL',
      },
      {
        'title': 'Severe Persistent Headache & Blurred Vision',
        'luganda': 'Omutwe oguluma ennyo n’amaaso okuziba',
        'swahili': 'Kichwa kuuma sana na macho kutoona vizuri',
        'action': 'Immediate BP check & magnesium sulfate referral at HC IV',
        'urgency': 'HIGH',
      },
      {
        'title': 'High Fever with Chills / Shivering',
        'luganda': 'Omusujja ogw\'amaanyi n\'okukankana',
        'swahili': 'Homa kali sana na kutetemeka',
        'action': 'Suspect malaria or chorioamnionitis; immediate IV therapy',
        'urgency': 'HIGH',
      },
      {
        'title': 'Severe Continuous Abdominal Pain',
        'luganda': 'Ekinyena / Olubuto oluluma ennyo',
        'swahili': 'Tumbo kuuma sana bila kupumzika',
        'action': 'Emergency evaluation for uterine rupture or concealed abruption',
        'urgency': 'HIGH',
      },
      {
        'title': 'Premature Water Breaking (Fluid Leak)',
        'luganda': 'Okuvaamu amazzi nga tolumwa',
        'swahili': 'Maji kuvunjika kabla ya uchungu',
        'action': 'Risk of cord prolapse and neonatal sepsis; visit HC IV within 2 hours',
        'urgency': 'HIGH',
      },
      {
        'title': 'No Fetal Movement / Baby Not Kicking',
        'luganda': 'Omwana takyanyeera mu lubuto',
        'swahili': 'Mtoto hasogei tumboni',
        'action': 'Immediate fetal heart rate check and ultrasound evaluation',
        'urgency': 'HIGH',
      },
    ];
  }
}
