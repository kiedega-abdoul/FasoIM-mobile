import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/public_page_scaffold.dart';

class ConsultationPage extends StatelessWidget {
  const ConsultationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PublicPageScaffold(
      title: 'Consulter mes informations',
      subtitle:
          'Retrouvez vos informations d’arrivée, votre affectation et les indications utiles liées à votre immersion.',
      body: Column(
        children: [
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rechercher mon dossier',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Saisissez le code FasoIM ou l’identifiant qui vous a été communiqué.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 18),
                const _Label('Code FasoIM, numéro PV, récépissé, matricule ou référence'),
                const SizedBox(height: 10),
                const TextField(
                  decoration: InputDecoration(
                    hintText: 'Ex. IP2026BAC010001 ou ATT-2026-XXXX',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('La connexion réelle au backend sera branchée à cette recherche.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Rechercher mon dossier'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations possibles après la recherche',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 12),
                _ResultRow(icon: Icons.qr_code_2_rounded, text: 'Code FasoIM et QR code'),
                _ResultRow(icon: Icons.location_on_outlined, text: 'Région et centre d’affectation'),
                _ResultRow(icon: Icons.event_note_rounded, text: 'Date et informations d’arrivée'),
                _ResultRow(icon: Icons.group_work_outlined, text: 'Section, groupe, dortoir et lit si publiés'),
                _ResultRow(icon: Icons.inventory_2_outlined, text: 'Consignes, directives et articles à apporter'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
