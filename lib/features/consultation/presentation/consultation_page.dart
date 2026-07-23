import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/public_page_scaffold.dart';
import '../data/consultation_models.dart';
import '../data/consultation_service.dart';

class ConsultationPage extends StatefulWidget {
  const ConsultationPage({super.key});

  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _service = ConsultationService();

  List<ArrivalSession> _sessions = const [];
  String? _selectedType;
  int? _selectedSessionId;
  ArrivalInformation? _result;
  bool _loading = true;
  bool _searching = false;
  String? _error;

  static const _categories = <_ConsultationCategory>[
    _ConsultationCategory(
      type: 'examen',
      label: 'Examens',
      description: 'BAC ou BEPC',
      icon: Icons.school_outlined,
    ),
    _ConsultationCategory(
      type: 'concours',
      label: 'Concours',
      description: 'Candidats admis aux concours',
      icon: Icons.work_outline_rounded,
    ),
    _ConsultationCategory(
      type: 'selectionne',
      label: 'Personnes sélectionnées',
      description: 'Sélections officielles',
      icon: Icons.person_search_outlined,
    ),
    _ConsultationCategory(
      type: 'volontaire',
      label: 'Volontaires',
      description: 'Demandes de volontariat acceptées',
      icon: Icons.groups_2_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _birthDateController.dispose();
    _service.close();
    super.dispose();
  }

  List<_ConsultationCategory> get _availableCategories => _categories
      .where(
        (category) =>
            _sessions.any((session) => session.sessionType == category.type),
      )
      .toList(growable: false);

  List<ArrivalSession> get _typeSessions => _sessions
      .where((session) => session.sessionType == _selectedType)
      .toList(growable: false);

  ArrivalSession? get _selectedSession {
    for (final session in _sessions) {
      if (session.id == _selectedSessionId) return session;
    }
    if (_typeSessions.length == 1) return _typeSessions.first;
    return null;
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sessions = await _service.fetchSessions();
      if (!mounted) return;

      final types = sessions.map((session) => session.sessionType).toSet();
      setState(() {
        _sessions = sessions;
        if (types.length == 1) _selectedType = types.first;
        if (sessions.length == 1) _selectedSessionId = sessions.first.id;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _chooseType(String type) {
    final rows = _sessions
        .where((session) => session.sessionType == type)
        .toList(growable: false);
    setState(() {
      _selectedType = type;
      _selectedSessionId = rows.length == 1 ? rows.first.id : null;
      _identifierController.clear();
      _birthDateController.clear();
      _result = null;
      _error = null;
    });
  }

  void _changeCategory() {
    setState(() {
      _selectedType = null;
      _selectedSessionId = null;
      _identifierController.clear();
      _birthDateController.clear();
      _result = null;
      _error = null;
    });
  }

  void _resetSearch() {
    setState(() {
      _identifierController.clear();
      _birthDateController.clear();
      _result = null;
      _error = null;
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(1940),
      lastDate: now,
      initialDate: DateTime(now.year - 18),
      helpText: 'Sélectionner la date de naissance',
    );
    if (selected == null) return;

    final month = selected.month.toString().padLeft(2, '0');
    final day = selected.day.toString().padLeft(2, '0');
    _birthDateController.text = '${selected.year}-$month-$day';
  }

  Future<void> _submit() async {
    final session = _selectedSession;
    if (session == null || !_formKey.currentState!.validate()) return;

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final result = await _service.search(
        session: session,
        identifier: _identifierController.text,
        birthDate: _birthDateController.text,
      );
      if (!mounted) return;
      setState(() => _result = result);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicPageScaffold(
      title: 'Consulter mon immersion',
      subtitle:
          'Retrouvez rapidement votre centre, votre organisation et les consignes d’arrivée.',
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_sessions.isEmpty) {
      return const InfoCard(
        child: Column(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 42,
              color: AppColors.primary,
            ),
            SizedBox(height: 14),
            Text(
              'Aucune consultation ouverte',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Les informations d’arrivée ne sont pas encore disponibles.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_availableCategories.length > 1 && _selectedType == null)
          _buildCategories(),
        if (_selectedType != null &&
            _typeSessions.length > 1 &&
            _selectedSession == null)
          _buildExamChoice(),
        if (_selectedSession != null && _result == null) _buildSearchForm(),
        if (_error != null) ...[
          const SizedBox(height: 16),
          _MessageCard(
            icon: Icons.error_outline_rounded,
            message: _error!,
            isError: true,
          ),
        ],
        if (_result != null)
          _ArrivalResultCard(result: _result!, onAnotherSearch: _resetSearch),
      ],
    );
  }

  Widget _buildCategories() {
    return Column(
      children: _availableCategories
          .map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _chooseType(category.type),
                child: InfoCard(
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(category.icon, color: AppColors.primary),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.label,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category.description,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildExamChoice() {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quel examen avez-vous passé ?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choisissez BAC ou BEPC.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          for (final session in _typeSessions) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    setState(() => _selectedSessionId = session.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(session.targetAudienceLabel),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchForm() {
    final session = _selectedSession!;

    return InfoCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Retrouver mes informations d’arrivée',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${session.name} · ${session.targetAudienceLabel}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            _Label(session.identifierLabel),
            const SizedBox(height: 9),
            TextFormField(
              controller: _identifierController,
              decoration: InputDecoration(
                hintText: session.identifierHint,
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ce champ est obligatoire.'
                  : null,
            ),
            const SizedBox(height: 16),
            const _Label('Date de naissance'),
            const SizedBox(height: 9),
            TextFormField(
              controller: _birthDateController,
              readOnly: true,
              onTap: _pickBirthDate,
              decoration: const InputDecoration(
                hintText: 'AAAA-MM-JJ',
                prefixIcon: Icon(Icons.cake_outlined),
                suffixIcon: Icon(Icons.calendar_month_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'La date de naissance est obligatoire.'
                  : null,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _searching ? null : _submit,
                icon: _searching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search_rounded),
                label: Text(
                  _searching
                      ? 'Consultation en cours…'
                      : 'Consulter mes informations',
                ),
              ),
            ),
            if (_availableCategories.length > 1) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _changeCategory,
                  child: const Text('Changer de catégorie'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArrivalResultCard extends StatelessWidget {
  const _ArrivalResultCard({
    required this.result,
    required this.onAnotherSearch,
  });

  final ArrivalInformation result;
  final VoidCallback onAnotherSearch;

  @override
  Widget build(BuildContext context) {
    final assignment = result.assignment;
    final session = result.session;
    final accommodation = result.accommodation;
    final centerInstructions = result.centerInstructions.entries
        .where((entry) => entry.value.toString().trim().isNotEmpty)
        .toList(growable: false);

    return Column(
      children: [
        const SizedBox(height: 16),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations d’arrivée',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.text(result.immerge, 'nom_complet'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result.text(session, 'nom'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        if (_hasAny([
          result.text(assignment, 'region'),
          result.text(assignment, 'centre'),
          result.text(assignment, 'province'),
          result.text(assignment, 'ville'),
          result.text(assignment, 'adresse'),
        ])) ...[
          const SizedBox(height: 16),
          _ResultSection(
            icon: Icons.apartment_rounded,
            title: 'Votre affectation',
            children: [
              _DataRow('Région', result.text(assignment, 'region')),
              _DataRow('Centre d’accueil', result.text(assignment, 'centre')),
              _DataRow(
                'Localisation',
                [
                  result.text(assignment, 'province'),
                  result.text(assignment, 'ville'),
                  result.text(assignment, 'adresse'),
                ].where((value) => value.isNotEmpty).join(' · '),
              ),
            ],
          ),
        ],
        if (_hasAny([
          result.text(assignment, 'section'),
          result.text(assignment, 'groupe'),
          result.text(accommodation, 'dortoir'),
          result.text(accommodation, 'lit'),
        ])) ...[
          const SizedBox(height: 16),
          _ResultSection(
            icon: Icons.groups_rounded,
            title: 'Votre organisation',
            children: [
              _DataRow('Section', result.text(assignment, 'section')),
              _DataRow('Groupe', result.text(assignment, 'groupe')),
              _DataRow('Dortoir', result.text(accommodation, 'dortoir')),
              _DataRow('Lit', result.text(accommodation, 'lit')),
            ],
          ),
        ],
        if (_hasAny([
          result.text(assignment, 'lieu_accueil'),
          result.text(assignment, 'heure_accueil'),
          result.text(assignment, 'horaires_generaux'),
          result.text(session, 'date_debut'),
          result.text(session, 'date_fin'),
        ])) ...[
          const SizedBox(height: 16),
          _ResultSection(
            icon: Icons.location_on_outlined,
            title: 'Votre arrivée',
            children: [
              _DataRow(
                'Lieu d’accueil',
                result.text(assignment, 'lieu_accueil'),
              ),
              _DataRow(
                'Heure d’accueil',
                result.text(assignment, 'heure_accueil'),
              ),
              _DataRow(
                'Horaires généraux',
                result.text(assignment, 'horaires_generaux'),
              ),
              _DataRow('Période', _period(result)),
            ],
          ),
        ],
        if (_hasAny([
          result.text(session, 'directives_generales'),
          result.text(session, 'consignes_generales'),
        ])) ...[
          const SizedBox(height: 16),
          _ResultSection(
            icon: Icons.shield_outlined,
            title: 'Consignes générales',
            children: [
              _TextBlock(
                label: 'Directives',
                value: result.text(session, 'directives_generales'),
              ),
              _TextBlock(
                label: 'Consignes',
                value: result.text(session, 'consignes_generales'),
              ),
            ],
          ),
        ],
        if (result.documentsRequired.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ResultSection(
            icon: Icons.description_outlined,
            title: 'Documents à présenter',
            children: [
              for (final document in result.documentsRequired)
                _BulletLine(document),
            ],
          ),
        ],
        if (centerInstructions.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ResultSection(
            icon: Icons.assignment_outlined,
            title: 'Consignes de votre centre',
            children: [
              for (final entry in centerInstructions)
                _TextBlock(
                  label: _instructionLabel(entry.key),
                  value: entry.value.toString().trim(),
                ),
            ],
          ),
        ],
        if (result.kits.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ResultSection(
            icon: Icons.inventory_2_outlined,
            title: 'Articles à apporter',
            children: [
              for (final kit in result.kits) _BulletLine(_kitLabel(kit)),
            ],
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onAnotherSearch,
            child: const Text('Faire une autre recherche'),
          ),
        ),
      ],
    );
  }

  static bool _hasAny(List<String> values) =>
      values.any((value) => value.trim().isNotEmpty);

  static String _period(ArrivalInformation result) {
    final start = result.text(result.session, 'date_debut');
    final end = result.text(result.session, 'date_fin');
    if (start.isEmpty && end.isEmpty) return '';
    if (end.isEmpty) return start;
    return '$start au $end';
  }

  static String _instructionLabel(String key) {
    const labels = <String, String>{
      'accueil': 'Accueil',
      'consignes_accueil': 'Accueil',
      'hebergement': 'Hébergement',
      'consignes_hebergement': 'Hébergement',
      'kits': 'Kits',
      'consignes_kits': 'Kits',
      'repas': 'Repas',
      'consignes_repas': 'Repas',
      'discipline': 'Discipline',
      'regles_discipline': 'Discipline',
      'directives_locales': 'Directives du centre',
      'horaires_generaux': 'Horaires généraux',
    };
    final label = labels[key];
    if (label != null) return label;
    final normalized = key.replaceAll('_', ' ');
    return normalized.isEmpty
        ? normalized
        : '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }

  static String _kitLabel(Map<String, dynamic> kit) {
    final designation = kit['designation']?.toString().trim() ?? '';
    final description = kit['description']?.toString().trim() ?? '';
    final quantity = kit['quantite']?.toString().trim() ?? '';
    final unit = kit['unite']?.toString().trim() ?? '';
    final required = kit['obligatoire'] == true ? ' · Obligatoire' : '';
    final quantityText = [
      quantity,
      unit,
    ].where((value) => value.isNotEmpty).join(' ');
    final details = quantityText.isEmpty
        ? ''
        : '\nQuantité : $quantityText$required';
    return description.isEmpty
        ? '$designation$details'
        : '$designation\n$description$details';
  }
}

class _ConsultationCategory {
  const _ConsultationCategory({
    required this.type,
    required this.label,
    required this.description,
    required this.icon,
  });

  final String type;
  final String label;
  final String description;
  final IconData icon;
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: icon, title: title),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.message,
    this.isError = false,
  });

  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red.shade700 : AppColors.primary;
    return InfoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: color, height: 1.4)),
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
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
