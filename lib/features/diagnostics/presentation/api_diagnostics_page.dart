import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_diagnostics_service.dart';
import '../../../core/theme/app_colors.dart';

class ApiDiagnosticsPage extends StatefulWidget {
  const ApiDiagnosticsPage({super.key});

  @override
  State<ApiDiagnosticsPage> createState() => _ApiDiagnosticsPageState();
}

class _ApiDiagnosticsPageState extends State<ApiDiagnosticsPage> {
  late final ApiDiagnosticsService _service;
  List<ApiProbeResult> _results = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _service = ApiDiagnosticsService();
    _runDiagnostics();
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  Future<void> _runDiagnostics() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _results = const [];
    });
    final results = await _service.runAll();
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final usable = _results.where((item) => item.isUsable).length;
    final errors = _results.where((item) =>
        item.state == ApiProbeState.missing ||
        item.state == ApiProbeState.serverError ||
        item.state == ApiProbeState.networkError).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic du backend'),
        actions: [
          IconButton(
            tooltip: 'Relancer les tests',
            onPressed: _loading ? null : _runDiagnostics,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _runDiagnostics,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _ServerCard(isLoading: _loading),
            const SizedBox(height: 16),
            if (_results.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Utilisables',
                      value: '$usable',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'À corriger',
                      value: '$errors',
                      icon: Icons.warning_amber_rounded,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            if (_results.isNotEmpty) const SizedBox(height: 20),
            Text(
              'État des services publics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Les tests POST utilisent un corps vide. Une réponse 400 signifie que la route existe et que sa validation fonctionne, sans créer de donnée.',
              style: TextStyle(height: 1.45, color: Color(0xFF667085)),
            ),
            const SizedBox(height: 14),
            if (_loading)
              ...ApiDiagnosticsService.probes.map(
                (probe) => _LoadingProbeCard(name: probe.name),
              )
            else if (_results.isEmpty)
              const _EmptyDiagnostics()
            else
              ..._results.map(_ProbeCard.new),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _runDiagnostics,
        icon: _loading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow_rounded),
        label: Text(_loading ? 'Test en cours' : 'Tester à nouveau'),
      ),
    );
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.dns_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Backend du binôme',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  ApiConfig.baseUrl,
                  style: const TextStyle(
                    color: Color(0xFFD9F7E5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isLoading ? 'Connexion et routes en cours de vérification…' : 'Tirez vers le bas ou utilisez le bouton pour relancer.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.35,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
              Text(label, style: const TextStyle(color: Color(0xFF667085))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProbeCard extends StatelessWidget {
  const _ProbeCard(this.result);

  final ApiProbeResult result;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(result.state);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: visual.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(visual.icon, color: visual.color),
        ),
        title: Text(result.definition.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            result.message,
            style: TextStyle(color: visual.color, fontWeight: FontWeight.w700),
          ),
        ),
        trailing: result.statusCode == null
            ? Icon(visual.icon, color: visual.color)
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${result.statusCode}',
                  style: TextStyle(color: visual.color, fontWeight: FontWeight.w900),
                ),
              ),
        children: [
          _DetailLine(label: 'Méthode', value: result.definition.method),
          _DetailLine(label: 'Route', value: result.definition.path),
          _DetailLine(label: 'Durée', value: '${result.duration.inMilliseconds} ms'),
          if (result.definition.description.isNotEmpty)
            _DetailLine(label: 'Rôle', value: result.definition.description),
          if (result.responsePreview.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Réponse', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                result.responsePreview,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _ProbeVisual _visualFor(ApiProbeState state) {
    return switch (state) {
      ApiProbeState.operational => const _ProbeVisual(Icons.check_circle_rounded, Color(0xFF07883D)),
      ApiProbeState.reachableValidation => const _ProbeVisual(Icons.fact_check_outlined, Color(0xFF1570EF)),
      ApiProbeState.protected => const _ProbeVisual(Icons.lock_outline_rounded, Color(0xFF7A5AF8)),
      ApiProbeState.missing => const _ProbeVisual(Icons.link_off_rounded, Color(0xFFB54708)),
      ApiProbeState.serverError => const _ProbeVisual(Icons.error_outline_rounded, Color(0xFFD92D20)),
      ApiProbeState.networkError => const _ProbeVisual(Icons.wifi_off_rounded, Color(0xFFD92D20)),
    };
  }
}

class _ProbeVisual {
  const _ProbeVisual(this.icon, this.color);
  final IconData icon;
  final Color color;
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(color: Color(0xFF667085), fontWeight: FontWeight.w700)),
          ),
          Expanded(child: SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _LoadingProbeCard extends StatelessWidget {
  const _LoadingProbeCard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: const Text('Test en cours…'),
      ),
    );
  }
}

class _EmptyDiagnostics extends StatelessWidget {
  const _EmptyDiagnostics();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.monitor_heart_outlined, size: 54, color: Color(0xFF98A2B3)),
          SizedBox(height: 12),
          Text('Aucun test exécuté.'),
        ],
      ),
    );
  }
}
