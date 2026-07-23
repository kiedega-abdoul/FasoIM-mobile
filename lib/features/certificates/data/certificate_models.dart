class CertificateVerification {
  const CertificateVerification({
    required this.valid,
    required this.status,
    required this.integrity,
    this.documentNumber,
    this.fullName,
    this.codeFasoim,
    this.session,
    this.deliveryDate,
    this.signatory,
    this.signatoryFunction,
  });

  final bool valid;
  final String status;
  final bool integrity;
  final String? documentNumber;
  final String? fullName;
  final String? codeFasoim;
  final String? session;
  final String? deliveryDate;
  final String? signatory;
  final String? signatoryFunction;

  factory CertificateVerification.fromJson(Map<String, dynamic> json) {
    return CertificateVerification(
      valid: json['valide'] == true,
      status: _text(json['statut']),
      integrity: json['integrite'] == true,
      documentNumber: _nullableText(json['numero_document']),
      fullName: _nullableText(json['nom_complet']),
      codeFasoim: _nullableText(json['code_fasoim']),
      session: _nullableText(json['session']),
      deliveryDate: _nullableText(
        json['date_delivrance'] ?? json['date_publication'],
      ),
      signatory: _nullableText(json['signataire']),
      signatoryFunction: _nullableText(json['fonction_signataire']),
    );
  }
}

class CertificateConsultation {
  const CertificateConsultation({
    required this.fullName,
    required this.typeImmerge,
    required this.codeFasoim,
    required this.sessionName,
    required this.sessionCode,
    required this.region,
    required this.centre,
    required this.decision,
    required this.decisionLabel,
    required this.available,
    this.documentNumber,
    this.verificationCode,
    this.publicationDate,
    this.downloadUrl,
  });

  final String fullName;
  final String typeImmerge;
  final String codeFasoim;
  final String sessionName;
  final String sessionCode;
  final String region;
  final String centre;
  final String decision;
  final String decisionLabel;
  final bool available;
  final String? documentNumber;
  final String? verificationCode;
  final String? publicationDate;
  final String? downloadUrl;

  factory CertificateConsultation.fromJson(Map<String, dynamic> json) {
    final immerge = _map(json['immerge']);
    final session = _map(json['session']);
    final affectation = _map(json['affectation']);

    final fullName = _text(immerge['nom_complet']).isNotEmpty
        ? _text(immerge['nom_complet'])
        : '${_text(immerge['nom'])} ${_text(immerge['prenoms'])}'.trim();

    return CertificateConsultation(
      fullName: fullName,
      typeImmerge: _text(immerge['type_immerge']),
      codeFasoim: _text(immerge['code_fasoim']).isNotEmpty
          ? _text(immerge['code_fasoim'])
          : _text(json['code_fasoim']),
      sessionName: _text(session['nom']),
      sessionCode: _text(session['code']),
      region: _text(affectation['region']),
      centre: _text(affectation['centre']),
      decision: _text(json['decision']),
      decisionLabel: _text(json['decision_libelle']),
      available: json['attestation_disponible'] == true,
      documentNumber: _nullableText(json['numero_document']),
      verificationCode: _nullableText(json['code_verification']),
      publicationDate: _nullableText(json['date_publication']),
      downloadUrl: _nullableText(json['url_telechargement']),
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

String _text(dynamic value) => value?.toString().trim() ?? '';

String? _nullableText(dynamic value) {
  final result = _text(value);
  return result.isEmpty ? null : result;
}
