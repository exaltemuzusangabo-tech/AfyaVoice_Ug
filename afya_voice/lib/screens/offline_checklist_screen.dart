import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/clinic_routing_service.dart';
import '../services/offline_cache_service.dart';

class OfflineChecklistScreen extends StatelessWidget {
  const OfflineChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dangerSigns = OfflineCacheService.getCachedDangerChecklist();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Maternal Safety Checklist'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Network outage status banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2833),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF37474F)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offline Clinical Protocol (WHO / MoH Uganda)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'These 7 danger signs require immediate clinic transfer even without mobile internet or cellular AI connection.',
                          style: TextStyle(fontSize: 12, color: AfyaTheme.subText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Emergency Contacts Quick Dial Box
            Card(
              color: const Color(0xFF2A1515),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AfyaTheme.primaryEmergency),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.emergency, color: Colors.redAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Emergency Toll-Free Lines (Uganda)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => ClinicRoutingService.callFacility('0800100066'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.phone, size: 16),
                            label: const Text('MoH Line (0800 100 066)', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => ClinicRoutingService.callFacility('112'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.local_police, size: 16),
                            label: const Text('National 112', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              '7 Core Obstetric Danger Signs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ...dangerSigns.map((item) {
              final isCritical = item['urgency'] == 'CRITICAL';
              final color = isCritical ? AfyaTheme.primaryEmergency : AfyaTheme.highUrgency;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: AfyaTheme.surfaceCard,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['title']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: color),
                            ),
                            child: Text(
                              item['urgency']!,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '🇺🇬 Luganda: ${item['luganda']}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF80CBC4), fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '🇹🇿 Swahili: ${item['swahili']}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFFFFCC80), fontStyle: FontStyle.italic),
                      ),
                      const Divider(height: 16, color: Color(0xFF2C3847)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_right, color: Color(0xFF26A69A), size: 20),
                          Expanded(
                            child: Text(
                              'Action: ${item['action']}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
