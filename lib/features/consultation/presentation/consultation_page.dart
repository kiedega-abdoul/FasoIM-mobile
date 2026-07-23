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

const _categories = <_ConsultationCategory>[
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
    icon: Icons.groups_outlined,
  ),
];

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

    final rows = _typeSessions;
    return rows.length == 1 ? rows.first : null;
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sessions = await _service.fetchSessions();
      if (!mounted) return;

      final activeTypes = sessions
          .map((session) => session.sessionType)
          .where((type) => type.isNotEmpty)
          .toSet()
          .toList(growable: false);

      setState(() {
        _sessions = sessions;
        _selectedType = activeTypes.length == 1 ? activeTypes.first : null;
        _selectedSessionId = sessions.length == 1 ? sessions.first.id : null;
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

  void _chooseSession(ArrivalSession session) {
    setState(() {
      _selectedSessionId = session.id;
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

  void _changeSession() {
    setState(() {
      _selectedSessionId = null;
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
      _result = null;
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
      body: Column(
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: CircularProgressIndicator(),
            )
          else if (_sessions.isEmpty)
            InfoCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 38,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Aucune consultation ouverte',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Les informations d’arrivée ne sont pas encore disponibles.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _loadSessions,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Actualiser'),
                  ),
                ],
              ),
            )
          else ...[
            if (_availableCategories.length > 1 && _selectedType == null)
              _buildCategoryChoices(),
            if (_selectedType != null &&
                _typeSessions.length > 1 &&
                _selectedSession == null)
              _buildSessionChoices(),
            if (_selectedSession != null && _result == null)
              _buildForm(_selectedSession!),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            _MessageCard(
              icon: Icons.error_outline_rounded,
              message: _error!,
              isError: true,
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 18),
            _ArrivalResultCard(result: _result!),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisissez votre catégorie',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _availableCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.02,
          ),
          itemBuilder: (context, index) {
            final category = _availableCategories[index];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _chooseType(category.type),
              child: Ink(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(category.icon, color: AppColors.primary),
                    ),
                    const Spacer(),
                    Text(
                      category.label,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      category.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSessionChoices() {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quel examen avez-vous passé ?',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choisissez BAC ou BEPC.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          for (final session in _typeSessions) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _chooseSession(session),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 17),
                ),
                child: Text(
                  session.targetAudienceLabel.isEmpty
                      ? session.targetAudience
                      : session.targetAudienceLabel,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_availableCategories.length > 1)
            TextButton.icon(
              onPressed: _changeCategory,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Changer de catégorie'),
            ),
        ],
      ),
    );
  }

  Widget _buildForm(ArrivalSession session) {
    return InfoCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Retrouver mes informations d’arrivée',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${session.name} · ${session.targetAudienceLabel}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            _Label(session.identifierLabel),
            const SizedBox(height: 10),
            TextFormField(
              controller: _identifierController,
              textCapitalization: TextCapitalization.characters,
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
            const SizedBox(height: 10),
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
                      ? 'Recherche en cours…'
                      : 'Consulter mes informations',
                ),
              ),
            ),
            if (_typeSessions.length > 1)
              TextButton.icon(
                onPressed: _changeSession,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Changer d’examen'),
              ),
            if (_availableCategories.length > 1)
              TextButton.icon(
                onPressed: _changeCategory,
                icon: const Icon(Icons.grid_view_rounded),
                label: const Text('Changer de catégorie'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArrivalResultCard extends StatelessWidget {
  const _ArrivalResultCard({required this.result});

  final ArrivalInformation result;

  @override
  Widget build(BuildContext context) {
    final identity = result.immerge;
    final session = result.session;
    final assignment = result.assignment;
    final accommodation = result.accommodation;

    final centerInstructions = result.centerInstructions.entries
        .where((entry) => entry.value.toString().trim().isNotEmpty)
        .toList(growable: false);

    return Column(
      children: [
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_rounded, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dossier retrouvé',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DataRow('Nom complet', result.text(identity, 'nom_complet')),
              _DataRow('Code FasoIM', result.text(identity, 'code_fasoim')),
              _DataRow('Type', result.text(identity, 'type_immerge')),
              _DataRow('Session', result.text(session, 'nom')),
              _DataRow('Période', _period(session)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                icon: Icons.location_on_outlined,
                title: 'Affectation et arrivée',
              ),
              const SizedBox(height: 14),
              _DataRow('Région', result.text(assignment, 'region')),
              _DataRow('Centre', result.text(assignment, 'centre')),
              _DataRow(
                'Code du centre',
                result.text(assignment, 'code_centre'),
              ),
              _DataRow('Province', result.text(assignment, 'province')),
              _DataRow('Ville', result.text(assignment, 'ville')),
              _DataRow('Adresse', result.text(assignment, 'adresse')),
              _DataRow(
                'Lieu d’accueil',
                result.text(assignment, 'lieu_accueil'),
              ),
              _DataRow(
                'Heure d’accueil',
                result.text(assignment, 'heure_accueil'),
              ),
              _DataRow('Section', result.text(assignment, 'section')),
              _DataRow('Groupe', result.text(assignment, 'groupe')),
              if (accommodation != null) ...[
                _DataRow('Dortoir', result.text(accommodation, 'dortoir')),
                _DataRow('Lit', result.text(accommodation, 'lit')),
              ],
            ],
          ),
        ),
        if (_hasText(result.text(session, 'directives_generales')) ||
            _hasText(result.text(session, 'consignes_generales')) ||
            centerInstructions.isNotEmpty) ...[
          const SizedBox(height: 16),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(
                  icon: Icons.assignment_outlined,
                  title: 'Consignes officielles',
                ),
                const SizedBox(height: 14),
                _TextBlock(
                  label: 'Directives générales',
                  value: result.text(session, 'directives_generales'),
                ),
                _TextBlock(
                  label: 'Consignes générales',
                  value: result.text(session, 'consignes_generales'),
                ),
                for (final entry in centerInstructions)
                  _TextBlock(
                    label: _instructionLabel(entry.key),
                    value: entry.value.toString(),
                  ),
              ],
            ),
          ),
        ],
        if (result.kits.isNotEmpty) ...[
          const SizedBox(height: 16),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(
                  icon: Icons.inventory_2_outlined,
                  title: 'Articles à apporter',
                ),
                const SizedBox(height: 14),
                for (final kit in result.kits)
                  Padding(
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
                            _kitLabel(kit),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              height: 1.35,
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
      ],
    );
  }

  static bool _hasText(String value) => value.trim().isNotEmpty;

  static String _period(Map<String, dynamic> session) {
    final start = session['date_debut']?.toString().trim() ?? '';
    final end = session['date_fin']?.toString().trim() ?? '';
    if (start.isEmpty && end.isEmpty) return '';
    if (end.isEmpty) return start;
    return '$start au $end';
  }

  static String _instructionLabel(String key) {
    const labels = <String, String>{
      'accueil': 'Accueil',
      'hebergement': 'Hébergement',
      'kits_a_apporter': 'Kits à apporter',
      'repas': 'Repas',
      'discipline': 'Discipline',
      'directives_locales': 'Directives du centre',
    };
    return labels[key] ?? key.replaceAll('_', ' ');
  }

  static String _kitLabel(Map<String, dynamic> kit) {
    final designation = kit['designation']?.toString().trim() ?? '';
    final quantity = kit['quantite']?.toString().trim() ?? '';
    final unit = kit['unite']?.toString().trim() ?? '';
    final required = kit['obligatoire'] == true ? ' — obligatoire' : '';
    final description = kit['description']?.toString().trim() ?? '';
    final quantityLabel = [
      quantity,
      unit,
    ].where((value) => value.isNotEmpty).join(' ');
    final base = quantityLabel.isEmpty
        ? designation
        : '$designation ($quantityLabel)';
    return description.isEmpty
        ? '$base$required'
        : '$base$required\n$description';
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
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
    final color = isError ? Colors.red.shade700 : AppColors.primaryDark;
    final background = isError ? Colors.red.shade50 : AppColors.primaryLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: color, height: 1.35)),
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
