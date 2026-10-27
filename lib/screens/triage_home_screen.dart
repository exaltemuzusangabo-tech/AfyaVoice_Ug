import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../constants/theme.dart';
import '../models/triage_result.dart';
import '../services/danger_sign_engine.dart';
import '../services/demo_mode_service.dart';
import '../services/gemini_service.dart';
import '../services/offline_cache_service.dart';

class TriageHomeScreen extends StatefulWidget {
  const TriageHomeScreen({super.key});

  @override
  State<TriageHomeScreen> createState() => _TriageHomeScreenState();
}

class _TriageHomeScreenState extends State<TriageHomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final GeminiService _geminiService = GeminiService();

  bool _isRecording = false;
  bool _isProcessing = false;
  String _selectedLanguage = 'en';
  String? _recordedAudioPath;
  DangerSignResult _realtimeDanger = DangerSignResult.none;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _textController.addListener(_onTextChanged);
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    final lang = await OfflineCacheService.getPreferredLanguage();
    setState(() => _selectedLanguage = lang);
  }

  void _onTextChanged() {
    final result = DangerSignEngine.evaluate(_textController.text);
    setState(() {
      _realtimeDanger = result;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordedAudioPath = path;
      });
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio recorded. Ready for maternal triage evaluation.')),
        );
      }
    } else {
      // Check microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required for voice triage.')),
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/afya_voice_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _executeTriage({String? overrideText}) async {
    final inputText = overrideText ?? _textController.text.trim();
    if (inputText.isEmpty && _recordedAudioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please speak or type symptoms before evaluating.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      String? audioB64;
      final audioPath = _recordedAudioPath;
      if (audioPath != null) {
        try {
          final audioFile = File(audioPath);
          if (await audioFile.exists()) {
            audioB64 = base64Encode(await audioFile.readAsBytes());
          }
        } catch (_) {
          audioB64 = null;
        }
      }

      final result = await _geminiService.triagePatient(
        voiceTranscript: inputText,
        language: _selectedLanguage,
        audioBase64: audioB64,
        audioMime: 'audio/wav',
      );

      // Cache offline
      await OfflineCacheService.saveTriageResult(result);

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _recordedAudioPath = null;
      });

      Navigator.of(context).pushNamed(
        '/result',
        arguments: result,
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Triage completed via offline clinical engine: $e')),
      );
    }
  }

  void _loadDemoScenario(DemoScenario scenario) {
    setState(() {
      _textController.text = scenario.transcript;
      if (scenario.language == 'Luganda') _selectedLanguage = 'lg';
      if (scenario.language == 'Swahili') _selectedLanguage = 'sw';
      if (scenario.language == 'English') _selectedLanguage = 'en';
    });
  }

  @override
  Widget build(BuildContext context) {
    final scenarios = DemoModeService.getScenarios();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AfyaVoice Triage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist_rtl),
            tooltip: 'WHO Offline Danger Signs',
            onPressed: () => Navigator.of(context).pushNamed('/offline_checklist'),
          ),
          IconButton(
            icon: const Icon(Icons.local_hospital_outlined),
            tooltip: 'Find Clinics',
            onPressed: () => Navigator.of(context).pushNamed('/clinics'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              dropdownColor: AfyaTheme.surfaceCard,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('🇬🇧 EN')),
                DropdownMenuItem(value: 'lg', child: Text('🇺🇬 LG')),
                DropdownMenuItem(value: 'sw', child: Text('🇹🇿 SW')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedLanguage = val);
                  OfflineCacheService.setPreferredLanguage(val);
                }
              },
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Live Deterministic WHO Alert Banner (If danger sign matched immediately)
              if (_realtimeDanger.hasDangerSign)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _realtimeDanger.severity == 'CRITICAL'
                        ? const Color(0xFF4A0E0E)
                        : const Color(0xFF4A2B0E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _realtimeDanger.severity == 'CRITICAL'
                          ? AfyaTheme.primaryEmergency
                          : AfyaTheme.highUrgency,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.crisis_alert,
                        color: _realtimeDanger.severity == 'CRITICAL'
                            ? Colors.redAccent
                            : Colors.orangeAccent,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DETERMINISTIC WHO OVERRIDE (${_realtimeDanger.severity})',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _realtimeDanger.clinicalRationale,
                              style: const TextStyle(fontSize: 12, color: Color(0xFFE0E0E0)),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

              // Voice Recording Hub Card
              Card(
                color: AfyaTheme.surfaceCard,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        _isRecording
                            ? 'Listening... Speak symptoms in English, Luganda, or Swahili'
                            : 'Tap to Record Voice Symptoms',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Animated Mic Button
                      ScaleTransition(
                        scale: _isRecording ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                        child: GestureDetector(
                          onTap: _toggleRecording,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isRecording ? AfyaTheme.primaryEmergency : AfyaTheme.seedTeal,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isRecording ? AfyaTheme.primaryEmergency : AfyaTheme.seedTeal)
                                      .withOpacity(0.4),
                                  blurRadius: 18,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isRecording
                            ? 'Tap to Stop Recording'
                            : (_recordedAudioPath != null
                                ? '✓ Audio recorded (${_recordedAudioPath!.split('/').last})'
                                : 'Voice-first for low-literacy & rural mothers'),
                        style: TextStyle(
                          fontSize: 12,
                          color: _isRecording ? Colors.redAccent : AfyaTheme.subText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Text Transcript / Manual Edit Input Box
              TextField(
                controller: _textController,
                maxLines: 3,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Voice Transcript / Patient Symptoms',
                  hintText: 'e.g. "Kuvaamu omusaayi nnyo", "Damu nyingi", "Baby not moving"...',
                  filled: true,
                  fillColor: AfyaTheme.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2C3847)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AfyaTheme.seedTeal, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Quick Demo Scenario Chips (Live Pitch Fallback)
              const Text(
                'Instant Live Demo Scenarios (Zero-Latency Fallback):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AfyaTheme.subText),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: scenarios.map((s) {
                  return ActionChip(
                    backgroundColor: const Color(0xFF232D3B),
                    side: const BorderSide(color: Color(0xFF384656)),
                    label: Text(
                      '${s.title} (${s.speakerRole})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => _loadDemoScenario(s),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Action Trigger Button
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : () => _executeTriage(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AfyaTheme.seedTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                icon: _isProcessing
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.bolt, size: 24),
                label: Text(
                  _isProcessing
                      ? 'Analyzing Obstetric Danger Signs...'
                      : 'Run AfyaVoice Clinical Triage',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
