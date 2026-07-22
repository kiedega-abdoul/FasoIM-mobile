import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/public_page_scaffold.dart';

class VolunteerHomePage extends StatelessWidget {
  const VolunteerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PublicPageScaffold(
      title: 'Demande volontaire',
      subtitle: 'Choisissez l’action que vous souhaitez effectuer.',
      body: Column(
        children: [
          _ActionCard(
            icon: Icons.find_in_page_outlined,
            title: 'Consulter ma demande d’immersion',
            description:
                'Consultez l’état de votre demande avec le code reçu après votre inscription.',
            buttonText: 'Suivre ma demande',
            onPressed: () => Navigator.pushNamed(context, '/volunteer/track'),
          ),
          const SizedBox(height: 16),
          _ActionCard(
            icon: Icons.note_add_outlined,
            title: 'Effectuer une demande d’immersion',
            description:
                'Inscrivez-vous à une session d’immersion volontaire actuellement ouverte.',
            buttonText: 'Faire une demande',
            onPressed: () => Navigator.pushNamed(context, '/volunteer/form'),
          ),
        ],
      ),
    );
  }
}

class VolunteerTrackPage extends StatelessWidget {
  const VolunteerTrackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PublicPageScaffold(
      title: 'Suivre ma demande',
      subtitle:
          'Saisissez votre code de suivi pour consulter l’état de traitement de votre demande volontaire.',
      body: InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Code de suivi',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ce code vous a été communiqué après l’enregistrement de votre demande.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Ex. VOL-2026-000123',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le suivi réel sera branché avec le backend.'),
                    ),
                  );
                },
                icon: const Icon(Icons.search_rounded),
                label: const Text('Rechercher ma demande'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VolunteerRequestFormPage extends StatelessWidget {
  const VolunteerRequestFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PublicPageScaffold(
      title: 'Demande volontaire',
      subtitle: 'Complétez les informations nécessaires pour déposer votre demande d’immersion.',
      body: Column(
        children: [
          const _VolunteerFormCard(),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Le dépôt réel de la demande sera connecté au backend.'),
                ),
              );
            },
            icon: const Icon(Icons.send_rounded),
            label: const Text('Soumettre ma demande'),
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
    required this.buttonText,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w900,
              fontSize: 26,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 16),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPressed,
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}

class _VolunteerFormCard extends StatelessWidget {
  const _VolunteerFormCard();

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations du volontaire',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les champs marqués d’un astérisque sont obligatoires.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _ResponsiveField(label: 'Nom *'),
              _ResponsiveField(label: 'Prénom(s) *'),
              _ResponsiveField(label: 'Sexe *', hint: 'Choisir'),
              _ResponsiveField(label: 'Date de naissance *', hint: 'jj/mm/aaaa'),
              _ResponsiveField(label: 'Lieu de naissance'),
              _ResponsiveField(label: 'Nationalité'),
              _ResponsiveField(label: 'Numéro CNIB'),
              _ResponsiveField(label: 'Téléphone *', hint: '+226 XX XX XX XX'),
              _ResponsiveField(label: 'Adresse e-mail'),
              _ResponsiveField(label: 'Région de résidence'),
              _ResponsiveField(label: 'Province de résidence'),
              _ResponsiveField(label: 'Commune de résidence'),
              _ResponsiveField(label: 'Adresse de résidence'),
              _ResponsiveField(label: 'Niveau d’étude'),
              _ResponsiveField(label: 'Profession'),
              _ResponsiveField(label: 'Nom du contact d’urgence'),
              _ResponsiveField(label: 'Téléphone d’urgence'),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Motivation *',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const TextField(
            minLines: 4,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Expliquez brièvement votre motivation pour participer à la session.',
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Après l’envoi, un code de suivi permettra de consulter le traitement de la demande.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveField extends StatelessWidget {
  const _ResponsiveField({required this.label, this.hint});

  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardInnerWidth = width - 40 - 36; // screen - outer padding - card padding
    final fieldWidth = cardInnerWidth > 680 ? (cardInnerWidth - 12) / 2 : cardInnerWidth;
    return SizedBox(
      width: fieldWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          TextField(decoration: InputDecoration(hintText: hint)),
        ],
      ),
    );
  }
}
