import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/certificates/presentation/certificate_verification_page.dart';
import '../features/certificates/presentation/qr_scanner_page.dart';
import '../features/consultation/presentation/consultation_page.dart';
import '../features/diagnostics/presentation/api_diagnostics_page.dart';
import '../features/public_home/presentation/public_home_page.dart';
import '../features/shared/presentation/placeholder_page.dart';
import '../features/splash/presentation/splash_page.dart';
import '../features/volunteer/presentation/volunteer_home_page.dart';

class FasoImApp extends StatelessWidget {
  const FasoImApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FasoIM',
      theme: AppTheme.light,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        return switch (settings.name) {
          '/' => MaterialPageRoute<void>(builder: (_) => const SplashPage()),
          '/home' => MaterialPageRoute<void>(builder: (_) => const PublicHomePage()),
          '/consultation' => MaterialPageRoute<void>(builder: (_) => const ConsultationPage()),
          '/certificate' =>
            MaterialPageRoute<void>(builder: (_) => const CertificateVerificationPage()),
          '/certificate/scan' =>
            MaterialPageRoute<String>(builder: (_) => const QrScannerPage()),
          '/volunteer' => MaterialPageRoute<void>(builder: (_) => const VolunteerHomePage()),
          '/volunteer/track' => MaterialPageRoute<void>(builder: (_) => const VolunteerTrackPage()),
          '/volunteer/form' =>
            MaterialPageRoute<void>(builder: (_) => const VolunteerRequestFormPage()),
          '/diagnostics' => MaterialPageRoute<void>(builder: (_) => const ApiDiagnosticsPage()),
          '/placeholder' => MaterialPageRoute<void>(
              builder: (_) => PlaceholderPage(
                    title: (settings.arguments as String?) ?? 'Fonctionnalité',
                  ),
            ),
          _ => MaterialPageRoute<void>(
              builder: (_) => const PlaceholderPage(title: 'Page introuvable'),
            ),
        };
      },
    );
  }
}
