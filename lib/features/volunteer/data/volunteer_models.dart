class VolunteerSession {
  const VolunteerSession({
    required this.id,
    required this.name,
    required this.code,
    required this.typeLabel,
    required this.startDate,
    required this.endDate,
    required this.registrationOpenDate,
    required this.registrationCloseDate,
    required this.description,
    required this.generalDirectives,
    required this.requiredDocuments,
  });

  final int id;
  final String name;
  final String code;
  final String typeLabel;
  final String startDate;
  final String endDate;
  final String? registrationOpenDate;
  final String? registrationCloseDate;
  final String description;
  final String generalDirectives;
  final List<String> requiredDocuments;

  factory VolunteerSession.fromJson(Map<String, dynamic> json) {
    return VolunteerSession(
      id: _asInt(json['id']),
      name: _asString(json['nom']),
      code: _asString(json['code']),
      typeLabel: _asString(json['type_session_libelle']),
      startDate: _asString(json['date_debut']),
      endDate: _asString(json['date_fin']),
      registrationOpenDate: _asNullableString(
        json['date_ouverture_inscription'],
      ),
      registrationCloseDate: _asNullableString(
        json['date_fermeture_inscription'],
      ),
      description: _asString(json['description']),
      generalDirectives: _asString(json['directives_generales']),
      requiredDocuments: _asStringList(json['documents_exiges']),
    );
  }
}

class VolunteerApplicationCreated {
  const VolunteerApplicationCreated({
    required this.message,
    required this.trackingCode,
    required this.status,
  });

  final String message;
  final String trackingCode;
  final String status;

  factory VolunteerApplicationCreated.fromJson(Map<String, dynamic> json) {
    return VolunteerApplicationCreated(
      message: _asString(json['message']),
      trackingCode: _asString(json['code_suivi']),
      status: _asString(json['statut']),
    );
  }
}

class VolunteerFollowUp {
  const VolunteerFollowUp({
    required this.trackingCode,
    required this.fullName,
    required this.session,
    required this.status,
    required this.statusLabel,
    required this.submissionDate,
    required this.decisionDate,
    required this.decisionReason,
    required this.fasoImCode,
    required this.message,
  });

  final String trackingCode;
  final String fullName;
  final String session;
  final String status;
  final String statusLabel;
  final String submissionDate;
  final String? decisionDate;
  final String decisionReason;
  final String fasoImCode;
  final String message;

  factory VolunteerFollowUp.fromJson(Map<String, dynamic> json) {
    return VolunteerFollowUp(
      trackingCode: _asString(json['code_suivi']),
      fullName: _asString(json['nom_complet']),
      session: _asString(json['session']),
      status: _asString(json['statut']),
      statusLabel: _asString(json['statut_libelle']),
      submissionDate: _asString(json['date_soumission']),
      decisionDate: _asNullableString(json['date_decision']),
      decisionReason: _asString(json['motif_decision']),
      fasoImCode: _asString(json['code_fasoim']),
      message: _asString(json['message']),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}

String _asString(dynamic value) => value == null ? '' : '$value'.trim();

String? _asNullableString(dynamic value) {
  final result = _asString(value);
  return result.isEmpty ? null : result;
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map(_asString)
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
