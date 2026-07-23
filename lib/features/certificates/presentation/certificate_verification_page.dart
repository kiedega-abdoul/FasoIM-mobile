import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/public_page_scaffold.dart';
import '../data/certificate_models.dart';
import '../data/certificate_service.dart';

class CertificateVerificationPage extends StatefulWidget {
  const CertificateVerificationPage({super.key});

  @override
  State<CertificateVerificationPage> createState() =>
      _CertificateVerificationPageState();
}

class _CertificateVerificationPageState
    extends State<CertificateVerificationPage> {
  final _codeController = TextEditingController();
  final _service = CertificateService();

  CertificateVerification? _result;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _service.close();
    super.dispose();
  }

  Future<void> _scanQrCode() async {
    final raw = await Navigator.pushNamed<String>(context, '/certificate/scan');
    if (!mounted || raw == null || raw.trim().isEmpty) return;

    final value = _extractVerificationValue(raw);
    setState(() => _codeController.text = value);
    await _verify();
  }

  String _extractVerificationValue(String raw) {
    final value = raw.trim();
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      final queryValue =
          uri.queryParameters['code'] ??
          uri.queryParameters['verification'] ??
          uri.queryParameters['numero'];
      if (queryValue != null && queryValue.trim().isNotEmpty) {
        return queryValue.trim();
      }
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last.trim();
      }
    }
    return value;
  }

  Future<void> _verify() async {
    final value = _codeController.text.trim();
    if (value.isEmpty) {
      setState(
        () => _error = 'Saisissez le code de vérification de l’attestation.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _service.verify(value);
      if (!mounted) return;
      setState(() => _result = result);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                  'Code de vérification',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Saisissez le code présent sur l’attestation ou scannez directement son QR code.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _scanQrCode,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scanner le QR code'),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Code de l’attestation',
                    hintText: 'Ex. ATT-2026-XXXXXXXX',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                  onSubmitted: (_) => _verify(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _verify,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search_rounded),
                    label: Text(
                      _loading ? 'Vérification…' : 'Vérifier l’attestation',
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            _ErrorCard(message: _error!),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            _VerificationResultCard(result: _result!),
          ],
          const SizedBox(height: 16),
          const InfoCard(
            child: Row(
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
    );
  }
}

class _VerificationResultCard extends StatelessWidget {
  const _VerificationResultCard({required this.result});

  final CertificateVerification result;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Attestation authentique',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  result.valid ? 'Valide' : 'Invalide',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Detail('Numéro de l’attestation', result.documentNumber ?? '—'),
          _Detail('Code FasoIM', result.codeFasoim ?? '—'),
          _Detail('Immergé', result.fullName ?? '—'),
          _Detail('Session', result.session ?? '—'),
          _Detail('Date de délivrance', result.deliveryDate ?? '—'),
          _Detail(
            'Intégrité du fichier',
            result.integrity ? 'Conforme' : 'Non conforme',
          ),
          if ((result.signatory ?? '').isNotEmpty)
            _Detail('Signataire', result.signatory!),
          if ((result.signatoryFunction ?? '').isNotEmpty)
            _Detail('Fonction du signataire', result.signatoryFunction!),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
