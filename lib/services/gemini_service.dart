import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/triage_result.dart';
import 'danger_sign_engine.dart';

/// Build-time configuration (pass with --dart-define):
///   GEMINI_API_KEY  Gemini key for direct calls (demo/hackathon builds only;
///                   a key inside an APK can be extracted - use a proxy for production)
///   GEMINI_MODEL    Gemini model id (default gemini-2.5-flash)
///   AFYA_API_URL    Optional backend proxy URL (used when no direct key is set)
/// With neither key nor proxy the app runs fully offline on the local
/// deterministic WHO danger-sign engine.
class GeminiService {
  static const String _envApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _envModel =
      String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-2.5-flash');
  static const String _envProxyUrl = String.fromEnvironment('AFYA_API_URL');

  final String baseUrl;
  final String? directApiKey;
  final String model;

  GeminiService({String? baseUrl, String? directApiKey, String? model})
      : baseUrl = baseUrl ?? _envProxyUrl,
        directApiKey = directApiKey ?? (_envApiKey.isEmpty ? null : _envApiKey),
        model = model ?? _envModel;

  static const String _systemInstruction = r"""You are the core clinical triage engine for "AfyaVoice", a voice-first maternal health decision-support app used in low-resource settings in East Africa (Uganda, Kenya, Tanzania). You receive text or voice audio from pregnant women, mothers or community health workers in English, Swahili or Luganda, and return ONE structured JSON object.

RULES:
1. DANGER SIGNS (highest priority). If ANY WHO/MoH maternal danger sign is present, set triage_level to CRITICAL or HIGH and override_triggered to true: severe vaginal bleeding (kuvaamu omusaayi, damu nyingi); convulsions, fits or loss of consciousness (kifafa, okugwa ekifafa); severe persistent headache with blurred vision or swollen face/hands; high fever with chills (omusujja gw'amaanyi, homa kali); severe abdominal pain (tumbo kuuma sana); leaking fluid / ruptured membranes (okuvaamu amazzi, maji kutoka); absent or reduced fetal movement (omwana takyanyeera, mtoto hasogei).
2. If audio is provided, transcribe it faithfully into the "transcript" field in the original language, then triage it.
3. Levels: CRITICAL = life-threatening emergency, immediate transport. HIGH = serious complication risk, facility within hours. MEDIUM = visit a health facility today. LOW = normal pregnancy discomfort, routine care.
4. Never diagnose definitively; use descriptive language. If the input is ambiguous or conflicting, choose HIGH.
5. Write patient_advice in simple language, in the language the speaker used when possible.
6. Respond ONLY with the JSON object.""";

  static const Map<String, dynamic> _responseSchema = {
    'type': 'OBJECT',
    'properties': {
      'transcript': {'type': 'STRING'},
      'triage_level': {'type': 'STRING'},
      'override_triggered': {'type': 'BOOLEAN'},
      'detected_symptoms': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
      'primary_concern': {'type': 'STRING'},
      'patient_advice': {'type': 'STRING'},
      'recommended_action': {'type': 'STRING'},
      'urgency_timeframe': {'type': 'STRING'},
    },
    'required': [
      'triage_level',
      'override_triggered',
      'detected_symptoms',
      'primary_concern',
      'patient_advice',
      'recommended_action',
      'urgency_timeframe',
    ],
  };

  /// Evaluates patient input with Gemini (direct key or proxy) and ALWAYS
  /// enforces the deterministic WHO danger-sign override afterwards.
  /// Falls back to the local engine when offline or on any error.
  Future<TriageResult> triagePatient({
    required String voiceTranscript,
    String language = 'en',
    String? audioBase64,
    String audioMime = 'audio/wav',
  }) async {
    final cleanInput = voiceTranscript.trim();
    final hasAudio = audioBase64 != null && audioBase64.isNotEmpty;

    // STEP 1: deterministic pre-evaluation of typed text
    final typedCheck = DangerSignEngine.evaluate(cleanInput);

    try {
      Map<String, dynamic>? data;
      final key = directApiKey;
      if (key != null && key.isNotEmpty) {
        data = await _callGeminiDirect(
          apiKey: key,
          text: cleanInput,
          language: language,
          audioBase64: audioBase64,
          audioMime: audioMime,
        );
      } else if (baseUrl.isNotEmpty) {
        data = await _callProxy(
          text: cleanInput,
          language: language,
          audioBase64: audioBase64,
          audioMime: audioMime,
        );
      }

      if (data == null) {
        return _buildDeterministicFallback(cleanInput, typedCheck, hasAudio: hasAudio);
      }

      // STEP 2: re-run the rule engine on typed text + model transcript
      final transcript = (data['transcript'] as String?) ?? '';
      final combined = '$cleanInput $transcript'.trim();
      final dangerCheck = DangerSignEngine.evaluate(combined);
      final result = TriageResult.fromJson(data, rawInput: combined);

      if (dangerCheck.hasDangerSign) {
        return _applyDangerOverride(result, dangerCheck, combined);
      }
      return result;
    } catch (e) {
      return _buildDeterministicFallback(cleanInput, typedCheck, hasAudio: hasAudio);
    }
  }

  Future<Map<String, dynamic>?> _callGeminiDirect({
    required String apiKey,
    required String text,
    required String language,
    required String audioMime,
    String? audioBase64,
  }) async {
    final hasAudio = audioBase64 != null && audioBase64.isNotEmpty;
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent');

    final parts = <Map<String, dynamic>>[];
    if (hasAudio) {
      parts.add({
        'inlineData': {'mimeType': audioMime, 'data': audioBase64},
      });
      parts.add({
        'text': 'Transcribe this patient voice audio (English, Luganda or Swahili) '
            'into the transcript field, then triage it. '
            'Typed note from user: "${text.isEmpty ? 'none' : text}"',
      });
    } else {
      parts.add({
        'text': 'Patient or CHW report (language hint: $language): "$text"',
      });
    }

    final body = {
      'systemInstruction': {
        'parts': [
          {'text': _systemInstruction},
        ],
      },
      'contents': [
        {'role': 'user', 'parts': parts},
      ],
      'generationConfig': {
        'temperature': 0.1,
        'responseMimeType': 'application/json',
        'responseSchema': _responseSchema,
      },
    };

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode(body),
        )
        .timeout(Duration(seconds: hasAudio ? 40 : 20));

    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final content = (candidates[0] as Map)['content'];
    if (content is! Map) return null;
    final respParts = content['parts'];
    if (respParts is! List || respParts.isEmpty) return null;

    final buffer = StringBuffer();
    for (final p in respParts) {
      if (p is Map && p['text'] is String) buffer.write(p['text'] as String);
    }
    var raw = buffer.toString().trim();
    if (raw.startsWith('```')) {
      raw = raw.replaceAll(RegExp(r'^```(?:json)?'), '').replaceAll('```', '').trim();
    }
    final parsed = jsonDecode(raw);
    return parsed is Map<String, dynamic> ? parsed : null;
  }

  Future<Map<String, dynamic>?> _callProxy({
    required String text,
    required String language,
    required String audioMime,
    String? audioBase64,
  }) async {
    final response = await http
        .post(
          Uri.parse(baseUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'text': text,
            'language': language,
            'audioBase64': audioBase64,
            'audioMime': audioMime,
          }),
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    final inner = decoded['data'] ?? decoded;
    return inner is Map<String, dynamic> ? inner : null;
  }

  /// Safety rule: Never allow model to downgrade a WHO Danger Sign
  TriageResult _applyDangerOverride(
    TriageResult original,
    DangerSignResult danger,
    String rawInput,
  ) {
    final isCritical = danger.severity == 'CRITICAL';
    final targetLevel = isCritical ? 'CRITICAL' : (original.triageLevel == 'CRITICAL' ? 'CRITICAL' : 'HIGH');
    
    final updatedSymptoms = List<String>.from(original.detectedSymptoms);
    for (final sign in danger.matchedSigns) {
      if (!updatedSymptoms.contains(sign)) {
        updatedSymptoms.insert(0, sign);
      }
    }

    return TriageResult(
      triageLevel: targetLevel,
      overrideTriggered: true,
      detectedSymptoms: updatedSymptoms,
      primaryConcern: 'Immediate WHO Danger Sign Triggered: ${danger.matchedSigns.join("; ")}',
      patientAdvice: isCritical
          ? 'Emergency: Do not walk. Lie on your left side. Immediately call for transport to the nearest Referral Hospital.'
          : 'High Urgency: Travel to Health Center IV or Hospital within hours. Do not wait.',
      recommendedAction: isCritical ? 'REFERRAL_HOSPITAL' : 'HEALTH_CENTER_IV',
      urgencyTimeframe: isCritical ? 'IMMEDIATE' : 'WITHIN_24_HOURS',
      rawInput: rawInput,
    );
  }

  /// Complete local fallback when offline
  TriageResult _buildDeterministicFallback(String rawInput, DangerSignResult danger,
      {bool hasAudio = false}) {
    if (danger.hasDangerSign) {
      final isCritical = danger.severity == 'CRITICAL';
      return TriageResult(
        triageLevel: isCritical ? 'CRITICAL' : 'HIGH',
        overrideTriggered: true,
        detectedSymptoms: danger.matchedSigns,
        primaryConcern: 'WHO Obstetric Danger Sign Detected (Offline Clinical Engine)',
        patientAdvice: isCritical
            ? 'CRITICAL EMERGENCY: Immediate motorized transfer to Referral Hospital needed. Keep patient calm, airway clear, on left side.'
            : 'HIGH PRIORITY: Transfer to Health Center IV or General Hospital today.',
        recommendedAction: isCritical ? 'REFERRAL_HOSPITAL' : 'HEALTH_CENTER_IV',
        urgencyTimeframe: isCritical ? 'IMMEDIATE' : 'WITHIN_24_HOURS',
        rawInput: rawInput,
      );
    }

    // Voice-only report that could not be analysed (offline / service error):
    // never answer "all fine" for something we could not hear. Fail safe.
    if (rawInput.isEmpty && hasAudio) {
      return TriageResult(
        triageLevel: 'HIGH',
        overrideTriggered: false,
        detectedSymptoms: ['Voice report could not be analysed (offline)'],
        primaryConcern: 'Voice recording could not be analysed without a network connection.',
        patientAdvice:
            'We could not analyse your voice note. If there is heavy bleeding, fits, severe headache with blurred vision, leaking fluid, severe belly pain, fever, or the baby is not moving, go to the nearest health facility NOW. Otherwise visit a health center within 24 hours, or type your symptoms and try again.',
        recommendedAction: 'HEALTH_CENTER_IV',
        urgencyTimeframe: 'WITHIN_24_HOURS',
        rawInput: rawInput,
      );
    }

    // Default safe clinical guidance
    return TriageResult(
      triageLevel: 'MEDIUM',
      overrideTriggered: false,
      detectedSymptoms: ['Uncharacterized maternal symptoms (offline mode)'],
      primaryConcern: 'Maternal health report evaluated offline; requires clinical review.',
      patientAdvice: 'No acute danger sign triggered. Please visit your nearest Health Center (HC III/IV) for blood pressure and urine checks.',
      recommendedAction: 'COMMUNITY_CLINIC',
      urgencyTimeframe: 'WITHIN_24_HOURS',
      rawInput: rawInput,
    );
  }
}
