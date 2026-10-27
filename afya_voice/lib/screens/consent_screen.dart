import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/offline_cache_service.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _understandsEmergency = false;
  bool _agreesDataUse = false;
  String _selectedLanguage = 'en';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialLanguage();
  }

  Future<void> _loadInitialLanguage() async {
    final lang = await OfflineCacheService.getPreferredLanguage();
    setState(() {
      _selectedLanguage = lang;
    });
  }

  Future<void> _onAcceptConsent() async {
    if (!_understandsEmergency || !_agreesDataUse) return;

    setState(() => _isLoading = true);
    await OfflineCacheService.setUserConsent(true);
    await OfflineCacheService.setPreferredLanguage(_selectedLanguage);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/triage');
  }

  @override
  Widget build(BuildContext context) {
    final isCanProceed = _understandsEmergency && _agreesDataUse;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AfyaTheme.seedTeal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.record_voice_over, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('AfyaVoice | Okutegeera'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              dropdownColor: AfyaTheme.surfaceCard,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('🇬🇧 English')),
                DropdownMenuItem(value: 'lg', child: Text('🇺🇬 Luganda')),
                DropdownMenuItem(value: 'sw', child: Text('🇹🇿 Swahili')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedLanguage = val);
                }
              },
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SDG & Ministry Alignment Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.emerald.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.Border.all(color: Colors.emerald.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.health_and_safety, color: Color(0xFF26A69A), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Targeting SDGs 3, 5, 10 | East Africa Maternal Health Protocol',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF26A69A)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                _selectedLanguage == 'lg'
                    ? 'Okukkiriza n\'Obukuumi bw\'Obulamu'
                    : _selectedLanguage == 'sw'
                        ? 'Idhini na Usalama wa Afya'
                        : 'Clinical Consent & Safety Notice',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _selectedLanguage == 'lg'
                    ? 'Pulogulaamu eno eyitibwa AfyaVoice eyamba abakyala abali embuto, abazaalisa, n\'abakozi b\'ebyobulamu ku byalo (CHWs) okutaputa obubonero bw\'obulabe mu bwangu.'
                    : _selectedLanguage == 'sw'
                        ? 'AfyaVoice inasaidia akina mama wajawazito, wakunga, na wahudumu wa afya ya jamii kutambua ishara hatari za uzazi kwa sauti bila kuchelewa.'
                        : 'AfyaVoice is a voice-first clinical triage decision support tool for mothers, midwives, and community health workers (CHWs) in low-bandwidth East African environments.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              // Critical Safety Disclaimer Box
              Card(
                color: const Color(0xFF2A1515),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AfyaTheme.primaryEmergency, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedLanguage == 'lg'
                                  ? 'Kikulu Nnyo: Eno Ssi Ddagala lya Dokita'
                                  : _selectedLanguage == 'sw'
                                      ? 'Taarifa Muhimu ya Dharura'
                                      : 'Critical Medical Boundary',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _selectedLanguage == 'lg'
                                  ? 'AfyaVoice ekuyamba okutegeera obulabe naye tesiinga ddwaliro. Bwoba olina omusaayi oguvaamu, ekifafa, oba obulumi obungi, genda mu ddwaliro mu bwangu!'
                                  : _selectedLanguage == 'sw'
                                      ? 'AfyaVoice haitoi utambuzi wa mwisho wa daktari. Ikitokea damu nyingi, kifafa, au maumivu makali, nenda hospitali ya rufaa mara moja!'
                                      : 'AfyaVoice does not replace an in-person physical clinical examination. In cases of acute vaginal bleeding, eclampsia fits, or acute pain, proceed directly to the nearest emergency referral hospital.',
                              style: const TextStyle(fontSize: 13, color: Color(0xFFE0E0E0), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Checkbox 1
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AfyaTheme.seedTeal,
                value: _understandsEmergency,
                onChanged: (val) => setState(() => _understandsEmergency = val ?? false),
                title: Text(
                  _selectedLanguage == 'lg'
                    ? 'Ntegeera nti ssinga wabaawo obulabe obw\'amangu (omusaayi, ekifafa), nteekwa okusitukiramu okugenda mu ddwaliro.'
                    : _selectedLanguage == 'sw'
                        ? 'Ninaelewa kuwa dharura ya uzazi inahitaji usafiri wa haraka kuelekea hospitali.'
                        : 'I understand this tool performs triage prioritization and I must seek emergency hospital care for severe danger signs.',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),

              // Checkbox 2
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AfyaTheme.seedTeal,
                value: _agreesDataUse,
                onChanged: (val) => setState(() => _agreesDataUse = val ?? false),
                title: Text(
                  _selectedLanguage == 'lg'
                    ? 'Nzikiriza eddoboozi lyange oba ebigambo byange okukozesebwa okumpa obuyambi obw\'obulamu.'
                    : _selectedLanguage == 'sw'
                        ? 'Ninakubali sauti yangu na maelezo kutumiwa kupima hatua za haraka za matibabu.'
                        : 'I consent to voice audio transcription and maternal symptom risk analysis to identify clinical danger signs.',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 32),

              // Proceed Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isCanProceed && !_isLoading ? _onAcceptConsent : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCanProceed ? AfyaTheme.seedTeal : Colors.grey.shade800,
                    foregroundColor: Colors.white,
                  ),
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.arrow_forward),
                  label: Text(
                    _selectedLanguage == 'lg'
                        ? 'Tandika Okukebera (Start Triage)'
                        : _selectedLanguage == 'sw'
                            ? 'Anza Uchunguzi (Start Triage)'
                            : 'Continue to Maternal Triage',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
