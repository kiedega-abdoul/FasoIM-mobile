import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/public_page_scaffold.dart';
import '../data/certificate_models.dart';
import '../data/certificate_service.dart';

class CertificateDownloadPage extends StatefulWidget {
  const CertificateDownloadPage({super.key});

  @override
  State<CertificateDownloadPage> createState() =>
      _CertificateDownloadPageState();
}

class _CertificateDownloadPageState extends State<CertificateDownloadPage> {
  final _codeController = TextEditingController();
  final _service = CertificateService();

  CertificateConsultation? _result;
  String? _error;
  bool _loading = false;
  bool _downloading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _service.close();
    super.dispose();
  }

  Future<void> _search() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Saisissez votre Code FasoIM.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _service.consultByFasoImCode(code);
      if (!mounted) return;
      setState(() => _result = result);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download() async {
    final path = _result?.downloadUrl;
    if (path == null || path.isEmpty) return;

    setState(() {
      _downloading = true;
      _error = null;
    });

    try {
      final uri = path.startsWith('http://') || path.startsWith('https://')
          ? Uri.parse(path)
          : ApiConfig.uri(path);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw const ApiException(
          'Impossible d’ouvrir le téléchargement de l’attestation.',
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = 'Impossible de télécharger l’attestation : $error',
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicPageScaffold(
      title: 'Télécharger mon attestation',
      subtitle:
          'Saisissez uniquement votre Code FasoIM. Vos informations et votre attestation publiée seront affichées.',
      body: Column(
        children: [
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Code FasoIM',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Utilisez le code personnel reçu dans le cadre de votre immersion.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Mon Code FasoIM',
                    hintText: 'Ex. IP2026BAC0100001',
                    prefixIcon: Icon(Icons.person_search_outlined),
                  ),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _search,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search_rounded),
                    label: Text(
                      _loading ? 'Recherche…' : 'Afficher mon attestation',
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            _DownloadErrorCard(message: _error!),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            _ConsultationResultCard(
              result: _result!,
              downloading: _downloading,
              onDownload: _download,
            ),
          ],
          const SizedBox(height: 16),
          const InfoCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_outlined, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Le fichier téléchargé est l’attestation officielle signée et publiée par la Direction régionale.',
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

class _ConsultationResultCard extends StatelessWidget {
  const _ConsultationResultCard({
    required this.result,
    required this.downloading,
    required this.onDownload,
  });

  final CertificateConsultation result;
  final bool downloading;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.person_outline, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Immergé',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      result.fullName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DownloadDetail('Code FasoIM', result.codeFasoim),
          _DownloadDetail('Type d’immergé', result.typeImmerge),
          _DownloadDetail(
            'Session',
            '${result.sessionName} (${result.sessionCode})',
          ),
          _DownloadDetail('Région', result.region),
          _DownloadDetail('Centre', result.centre),
          _DownloadDetail('Décision', result.decisionLabel),
          _DownloadDetail(
            'Numéro de l’attestation',
            result.documentNumber ?? 'Non disponible',
          ),
          _DownloadDetail(
            'Date de publication',
            result.publicationDate ?? 'Non publiée',
          ),
          const SizedBox(height: 6),
          if (result.available && result.downloadUrl != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: downloading ? null : onDownload,
                icon: downloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  downloading
                      ? 'Téléchargement…'
                      : 'Télécharger mon attestation',
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.description_outlined, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Aucune attestation téléchargeable n’est disponible pour ce Code FasoIM. La personne peut être non éligible ou la publication peut ne pas être terminée.',
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

class _DownloadDetail extends StatelessWidget {
  const _DownloadDetail(this.label, this.value);

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

class _DownloadErrorCard extends StatelessWidget {
  const _DownloadErrorCard({required this.message});

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
