import 'package:flutter/material.dart';
import 'constants/theme.dart';
import 'models/triage_result.dart';
import 'screens/clinic_map_screen.dart';
import 'screens/consent_screen.dart';
import 'screens/offline_checklist_screen.dart';
import 'screens/triage_home_screen.dart';
import 'screens/triage_result_screen.dart';
import 'services/offline_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check persistent user consent state before choosing entry route
  final bool hasConsented = await OfflineCacheService.hasUserConsented();

  runApp(AfyaVoiceApp(initialRoute: hasConsented ? '/triage' : '/consent'));
}

class AfyaVoiceApp extends StatelessWidget {
  final String initialRoute;

  const AfyaVoiceApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AfyaVoice',
      debugShowCheckedModeBanner: false,
      theme: AfyaTheme.darkTheme,
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/consent':
            return MaterialPageRoute(builder: (_) => const ConsentScreen());
          case '/triage':
            return MaterialPageRoute(builder: (_) => const TriageHomeScreen());
          case '/result':
            final result = settings.arguments as TriageResult;
            return MaterialPageRoute(builder: (_) => TriageResultScreen(result: result));
          case '/clinics':
            final triageLevel = settings.arguments as String? ?? 'HIGH';
            return MaterialPageRoute(builder: (_) => ClinicMapScreen(triageLevel: triageLevel));
          case '/offline_checklist':
            return MaterialPageRoute(builder: (_) => const OfflineChecklistScreen());
          default:
            return MaterialPageRoute(builder: (_) => const ConsentScreen());
        }
      },
    );
  }
}
