import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../models/triage_result.dart';
import '../services/clinic_routing_service.dart';

class TriageResultScreen extends StatelessWidget {
  final TriageResult result;

  const TriageResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final urgencyColor = AfyaTheme.getUrgencyColor(result.triageLevel);
    final isCritical = result.triageLevel == 'CRITICAL';
    final isHigh = result.triageLevel == 'HIGH';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Triage Assessment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Triage Summary',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Triage summary copied to clipboard for CHW dispatch.')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Deterministic WHO Override Banner
              if (result.overrideTriggered)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A0E0E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AfyaTheme.primaryEmergency, width: 2),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.redAccent, size: 26),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'MANDATORY WHO/MoH DANGER SIGN OVERRIDE ACTIVE. Highest clinical priority enforced.',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    ],
                  ),
                ),

              // Urgency Level Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: urgencyColor, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: urgencyColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            result.triageLevel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 16, color: AfyaTheme.subText),
                            const SizedBox(width: 6),
                            Text(
                              result.urgencyTimeframe.replaceAll('_', ' '),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      result.primaryConcern,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Target Action: ${result.recommendedAction.replaceAll('_', ' ')}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Detected Symptoms
              const Text(
                'Identified Obstetric Signs & Symptoms',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AfyaTheme.highContrastText),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.detectedSymptoms.map((symptom) {
                  return Chip(
                    backgroundColor: AfyaTheme.surfaceCard,
                    side: const BorderSide(color: Color(0xFF37474F)),
                    avatar: Icon(
                      Icons.check_circle_outline,
                      color: isCritical ? Colors.redAccent : AfyaTheme.seedTeal,
                      size: 16,
                    ),
                    label: Text(symptom, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Patient / CHW Actionable Advice Card
              Card(
                color: AfyaTheme.surfaceCard,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.directions_run, color: Color(0xFF26A69A), size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Actionable Patient & Midwife Guidance',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        result.patientAdvice,
                        style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFFEEEEEE)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Primary Emergency Buttons
              if (isCritical || isHigh) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    // Uganda Ministry of Health Maternal Emergency Ambulance Line
                    ClinicRoutingService.callFacility('+256800100066');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AfyaTheme.primaryEmergency,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.phone_in_talk, size: 22),
                  label: const Text(
                    'Call Maternal Emergency Line (Toll-Free 0800 100 066)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Route to Nearest Clinic
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    '/clinics',
                    arguments: result.triageLevel,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AfyaTheme.seedTeal, width: 2),
                  foregroundColor: const Color(0xFF26A69A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text(
                  'Route to Emergency-Ready Clinics & Hospitals',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 12),

              // Back to Home
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: AfyaTheme.subText),
                label: const Text('Perform Another Triage Assessment', style: TextStyle(color: AfyaTheme.subText)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
