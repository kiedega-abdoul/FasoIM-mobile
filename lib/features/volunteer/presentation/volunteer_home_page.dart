import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/public_page_scaffold.dart';
import '../data/volunteer_models.dart';
import '../data/volunteer_service.dart';

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

class VolunteerTrackPage extends StatefulWidget {
  const VolunteerTrackPage({super.key});

  @override
  State<VolunteerTrackPage> createState() => _VolunteerTrackPageState();
}

class _VolunteerTrackPageState extends State<VolunteerTrackPage> {
  final _service = VolunteerService();
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;
  VolunteerFollowUp? _result;

  @override
  void dispose() {
    _codeController.dispose();
    _service.close();
    super.dispose();
  }

  Future<void> _search() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _loading) {
      setState(() => _error = 'Le code de suivi est obligatoire.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _service.followApplication(code);
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
      title: 'Suivre ma demande',
      subtitle:
          'Saisissez votre code de suivi pour consulter l’état de traitement de votre demande volontaire.',
      body: Column(
        children: [
          InfoCard(
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
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Ex. VOL-2026-000123',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                  ),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _search,
                    icon: _loading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search_rounded),
                    label: Text(
                      _loading ? 'Recherche...' : 'Rechercher ma demande',
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
            _FollowUpCard(result: _result!),
          ],
        ],
      ),
    );
  }
}

class VolunteerRequestFormPage extends StatefulWidget {
  const VolunteerRequestFormPage({super.key});

  @override
  State<VolunteerRequestFormPage> createState() =>
      _VolunteerRequestFormPageState();
}

class _VolunteerRequestFormPageState extends State<VolunteerRequestFormPage> {
  final _service = VolunteerService();
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    for (final name in const [
      'nom',
      'prenoms',
      'date_naissance',
      'lieu_naissance',
      'nationalite',
      'numero_cnib',
      'telephone',
      'email',
      'contact_urgence',
      'nom_contact_urgence',
      'region_residence',
      'province_residence',
      'commune_residence',
      'adresse_residence',
      'niveau_etude',
      'profession',
      'motivation',
    ])
      name: TextEditingController(),
  };

  VolunteerSession? _session;
  String _sex = 'M';
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  VolunteerApplicationCreated? _created;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _service.close();
    super.dispose();
  }

  Future<void> _loadSession() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _session = null;
    });

    try {
      final sessions = await _service.fetchOpenSessions();
      if (!mounted) return;
      setState(() {
        _session = sessions.isEmpty ? null : sessions.first;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _session = null;
        _error = error.message;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? 'Ce champ est obligatoire.'
        : null;
  }

  Future<void> _pickBirthDate() async {
    final initial =
        DateTime.tryParse(_controllers['date_naissance']!.text) ??
        DateTime(DateTime.now().year - 18);
    final value = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (value != null) {
      _controllers['date_naissance']!.text = _dateOnly(value);
    }
  }

  Future<void> _submit() async {
    if (_session == null || _submitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final body = <String, Object?>{
      'session_id': _session!.id,
      'sexe': _sex,
      for (final entry in _controllers.entries)
        entry.key: entry.value.text.trim(),
    };

    try {
      final created = await _service.submitApplication(data: body);
      if (!mounted) return;
      setState(() => _created = created);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicPageScaffold(
      title: 'Demande de participation volontaire',
      subtitle: 'Consultez la session ouverte puis renseignez votre demande.',
      body: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          : _created != null
          ? _CreatedCard(created: _created!)
          : _error != null
          ? Column(
              children: [
                _ErrorCard(message: _error!),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loadSession,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
                  ),
                ),
              ],
            )
          : _session == null
          ? const _ClosedCard()
          : Column(
              children: [
                _SessionCard(session: _session!),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: InfoCard(
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
                        const SizedBox(height: 6),
                        const Text(
                          'Les champs marqués d’un astérisque sont obligatoires.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 18),
                        _field('Nom *', 'nom', required: true),
                        _field('Prénom(s) *', 'prenoms', required: true),
                        _sexField(),
                        _field(
                          'Date de naissance *',
                          'date_naissance',
                          required: true,
                          readOnly: true,
                          onTap: _pickBirthDate,
                          suffixIcon: const Icon(Icons.calendar_month_outlined),
                        ),
                        _field(
                          'Lieu de naissance *',
                          'lieu_naissance',
                          required: true,
                        ),
                        _field('Nationalité *', 'nationalite', required: true),
                        _field('Numéro CNIB *', 'numero_cnib', required: true),
                        _field(
                          'Téléphone *',
                          'telephone',
                          required: true,
                          keyboardType: TextInputType.phone,
                        ),
                        _field(
                          'Adresse e-mail *',
                          'email',
                          required: true,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _field(
                          'Nom du contact d’urgence *',
                          'nom_contact_urgence',
                          required: true,
                        ),
                        _field(
                          'Téléphone d’urgence *',
                          'contact_urgence',
                          required: true,
                          keyboardType: TextInputType.phone,
                        ),
                        _field(
                          'Région de résidence *',
                          'region_residence',
                          required: true,
                        ),
                        _field(
                          'Province de résidence *',
                          'province_residence',
                          required: true,
                        ),
                        _field('Commune de résidence', 'commune_residence'),
                        _field(
                          'Adresse de résidence *',
                          'adresse_residence',
                          required: true,
                        ),
                        _field('Niveau d’étude', 'niveau_etude'),
                        _field('Profession *', 'profession', required: true),
                        _field(
                          'Motivation *',
                          'motivation',
                          required: true,
                          minLines: 4,
                          maxLines: 6,
                        ),
                        const SizedBox(height: 8),
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
                              Icon(
                                Icons.check_circle_outline,
                                color: AppColors.primary,
                              ),
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
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _submitting ? null : _submit,
                            icon: _submitting
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: Text(
                              _submitting ? 'Envoi...' : 'Soumettre ma demande',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _field(
    String label,
    String name, {
    bool required = false,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          TextFormField(
            controller: _controllers[name],
            validator: required ? _required : null,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            minLines: minLines,
            maxLines: maxLines,
            decoration: InputDecoration(suffixIcon: suffixIcon),
          ),
        ],
      ),
    );
  }

  Widget _sexField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sexe *', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            initialValue: _sex,
            items: const [
              DropdownMenuItem(value: 'M', child: Text('Masculin')),
              DropdownMenuItem(value: 'F', child: Text('Féminin')),
              DropdownMenuItem(value: 'AUTRE', child: Text('Autre')),
            ],
            onChanged: (value) => setState(() => _sex = value ?? 'M'),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final VolunteerSession session;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SESSION OUVERTE',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            session.name,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (session.typeLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              session.typeLabel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          _line(
            'Période d’inscription',
            'Du ${_displayDate(session.registrationOpenDate)} au ${_displayDate(session.registrationCloseDate)}',
          ),
          _line(
            'Période d’immersion',
            'Du ${_displayDate(session.startDate)} au ${_displayDate(session.endDate)}',
          ),
          if (session.description.isNotEmpty)
            _line('Description', session.description),
          if (session.generalDirectives.isNotEmpty)
            _line('Directives utiles', session.generalDirectives),
          if (session.requiredDocuments.isNotEmpty)
            _line('Documents à prévoir', session.requiredDocuments.join(' · ')),
        ],
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
      ],
    ),
  );
}

class _CreatedCard extends StatelessWidget {
  const _CreatedCard({required this.created});

  final VolunteerApplicationCreated created;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryLight,
            child: Icon(
              Icons.check_circle_outline,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Demande enregistrée',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Conservez soigneusement ce code. Il servira à suivre votre demande.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Text(
                  'CODE DE SUIVI',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                SelectableText(
                  created.trackingCode,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Statut : En attente',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/volunteer/track'),
              child: const Text('Consulter le suivi'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard({required this.result});

  final VolunteerFollowUp result;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_turned_in_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.statusLabel,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.message,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const Divider(height: 28),
          _item('Code de suivi', result.trackingCode),
          _item('Nom complet', result.fullName),
          _item('Session', result.session),
          _item('Date de soumission', _displayDateTime(result.submissionDate)),
          if (result.decisionDate != null)
            _item('Date de décision', _displayDateTime(result.decisionDate!)),
          if (result.decisionReason.isNotEmpty)
            _item('Motif de décision', result.decisionReason),
          if (result.fasoImCode.isNotEmpty)
            _item('Code FasoIM', result.fasoImCode),
        ],
      ),
    );
  }

  Widget _item(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        SelectableText(
          value,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

class _ClosedCard extends StatelessWidget {
  const _ClosedCard();

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        children: [
          const Icon(
            Icons.person_off_outlined,
            size: 50,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Les inscriptions volontaires sont actuellement fermées',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Aucune session n’accepte de nouvelles demandes pour le moment. Revenez pendant la prochaine période d’inscription.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (_) => false,
            ),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour à l’accueil'),
          ),
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
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFC62828)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFC62828), height: 1.4),
            ),
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
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onPressed, child: Text(buttonText)),
          ),
        ],
      ),
    );
  }
}

String _dateOnly(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String _displayDate(String? value) {
  if (value == null || value.isEmpty) return 'Non renseignée';
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _displayDateTime(String value) {
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return value;
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} à $hour:$minute';
}
