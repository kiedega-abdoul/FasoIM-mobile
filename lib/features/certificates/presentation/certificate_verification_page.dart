import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/public_page_scaffold.dart';

class CertificateVerificationPage extends StatefulWidget {
  const CertificateVerificationPage({super.key});

  @override
  State<CertificateVerificationPage> createState() => _CertificateVerificationPageState();
}

class _CertificateVerificationPageState extends State<CertificateVerificationPage> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _scanQrCode() async {
    final result = await Navigator.pushNamed<String>(context, '/certificate/scan');
    if (!mounted || result == null || result.isEmpty) return;
    setState(() => _codeController.text = result);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR code lu avec succès. Vérifiez maintenant l’attestation.')),
    );
  }

  void _verify() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saisissez un code ou scannez le QR code de l’attestation.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Vérification de l’attestation : $code')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PublicPageScaffold(
      title: 'Vérifier une attestation',
      subtitle:
          'Contrôlez facilement l’authenticité d’une attestation publiée par FasoIM.',
      body: Column(
        children: [
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choisissez une méthode de vérification',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vous pouvez saisir le code de l’attestation ou scanner directement son QR code.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _scanQrCode,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scanner le QR code'),
                ),
                const SizedBox(height: 22),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OU',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Code de l’attestation',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Ex. ATT-2026-XXXXXXXX',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _verify,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Vérifier l’attestation'),
                  ),
                ),
                const SizedBox(height: 16),
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
                      Icon(Icons.shield_outlined, color: AppColors.primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'La vérification permet de confirmer qu’une attestation a bien été publiée par FasoIM.',
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
          ),
        ],
      ),
    );
  }
}
