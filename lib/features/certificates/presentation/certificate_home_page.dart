import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/public_page_scaffold.dart';

class CertificateHomePage extends StatelessWidget {
  const CertificateHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PublicPageScaffold(
      title: 'Attestation',
      subtitle: 'Choisissez l’action que vous souhaitez effectuer.',
      body: Column(
        children: [
          _ActionCard(
            icon: Icons.verified_outlined,
            title: 'Vérifier une attestation',
            description:
                'Contrôlez l’authenticité d’une attestation à partir de son code de vérification ou de son QR code.',
            buttonLabel: 'Vérifier une attestation',
            onPressed: () =>
                Navigator.pushNamed(context, '/certificate/verify'),
          ),
          const SizedBox(height: 16),
          _ActionCard(
            icon: Icons.download_outlined,
            title: 'Télécharger mon attestation',
            description:
                'Saisissez uniquement votre Code FasoIM pour consulter vos informations et télécharger votre attestation publiée.',
            buttonLabel: 'Télécharger mon attestation',
            onPressed: () =>
                Navigator.pushNamed(context, '/certificate/download'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
