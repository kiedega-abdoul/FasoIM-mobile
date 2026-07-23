class ArrivalSession {
  const ArrivalSession({
    required this.id,
    required this.name,
    required this.code,
    required this.sessionType,
    required this.sessionTypeLabel,
    required this.targetAudience,
    required this.targetAudienceLabel,
    required this.year,
    required this.startDate,
    required this.endDate,
  });

  factory ArrivalSession.fromJson(Map<String, dynamic> json) {
    return ArrivalSession(
      id: _asInt(json['id']),
      name: _asString(json['nom']),
      code: _asString(json['code']),
      sessionType: _asString(json['type_session']).toLowerCase(),
      sessionTypeLabel: _asString(json['type_session_libelle']),
      targetAudience: _asString(json['public_cible']).toUpperCase(),
      targetAudienceLabel: _asString(json['public_cible_libelle']),
      year: _asInt(json['annee']),
      startDate: _asString(json['date_debut']),
      endDate: _asString(json['date_fin']),
    );
  }

  final int id;
  final String name;
  final String code;
  final String sessionType;
  final String sessionTypeLabel;
  final String targetAudience;
  final String targetAudienceLabel;
  final int year;
  final String startDate;
  final String endDate;

  String get identifierLabel {
    switch (targetAudience) {
      case 'BEPC':
      case 'BAC':
      case 'EXAMEN':
        return 'Numéro de PV';
      case 'CONCOURS':
        return 'Numéro de récépissé';
      case 'SELECTIONNE':
      case 'SELECTION':
        return 'Matricule ou référence de sélection';
      case 'VOLONTAIRE':
        return 'Code de suivi';
      default:
        return 'Code FasoIM ou identifiant officiel';
    }
  }

  String get identifierHint {
    switch (targetAudience) {
      case 'BEPC':
      case 'BAC':
      case 'EXAMEN':
        return 'Ex. 12345678';
      case 'CONCOURS':
        return 'Ex. REC-2026-00125';
      case 'SELECTIONNE':
      case 'SELECTION':
        return 'Ex. MAT-2026-001';
      case 'VOLONTAIRE':
        return 'Ex. VOL-2026-XXXX';
      default:
        return 'Ex. IP2026BAC0100001';
    }
  }

  String get identifierField {
    switch (targetAudience) {
      case 'BEPC':
      case 'BAC':
      case 'EXAMEN':
        return 'numero_pv';
      case 'CONCOURS':
        return 'numero_recepisse';
      case 'SELECTIONNE':
      case 'SELECTION':
        return 'reference_selection';
      case 'VOLONTAIRE':
        return 'code_suivi';
      default:
        return 'code_fasoim';
    }
  }
}

class ArrivalInformation {
  const ArrivalInformation({
    required this.immerge,
    required this.session,
    required this.assignment,
    required this.centerInstructions,
    required this.kits,
    this.accommodation,
  });

  factory ArrivalInformation.fromJson(Map<String, dynamic> json) {
    final root = _unwrap(json);

    return ArrivalInformation(
      immerge: _asMap(
        root['immerge'] ?? root['participant'] ?? root['identite'],
      ),
      session: _asMap(root['session']),
      assignment: _asMap(
        root['affectation'] ??
            root['affectation_centre'] ??
            root['organisation'],
      ),
      accommodation: _nullableMap(root['hebergement'] ?? root['logement']),
      centerInstructions: _asMap(
        root['consignes_centre'] ??
            root['instructions_centre'] ??
            root['consignes'],
      ),
      kits: _asListOfMaps(
        root['kits_a_apporter'] ?? root['articles_a_apporter'] ?? root['kits'],
      ),
    );
  }

  final Map<String, dynamic> immerge;
  final Map<String, dynamic> session;
  final Map<String, dynamic> assignment;
  final Map<String, dynamic>? accommodation;
  final Map<String, dynamic> centerInstructions;
  final List<Map<String, dynamic>> kits;

  String text(Map<String, dynamic>? source, String key) {
    final value = source?[key];
    if (value == null) return '';
    if (value is bool) return value ? 'Oui' : 'Non';
    return value.toString().trim();
  }

  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    final result = json['resultat'];
    if (result is Map) return Map<String, dynamic>.from(result);
    return json;
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _asString(dynamic value) => value?.toString().trim() ?? '';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

Map<String, dynamic>? _nullableMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>> _asListOfMaps(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}
