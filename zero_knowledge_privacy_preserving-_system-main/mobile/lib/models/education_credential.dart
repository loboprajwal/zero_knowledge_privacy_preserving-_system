import 'dart:convert';

/// Represents a student's education credential stored securely in the local Vault.
class EducationCredential {
  final String studentName;
  final String degree;
  final int
  degreeCode; // Numeric identifier (1 = Bachelor of Technology / Bachelor's Degree)
  final String university;
  final int graduationYear;
  final String credentialId;
  final String status; // 'VALID' or 'REVOKED'

  const EducationCredential({
    required this.studentName,
    required this.degree,
    required this.degreeCode,
    required this.university,
    required this.graduationYear,
    required this.credentialId,
    required this.status,
  });

  /// Default demo education credential
  factory EducationCredential.demo() {
    return const EducationCredential(
      studentName: 'Prashant Pandita',
      degree: 'Bachelor of Technology',
      degreeCode: 1,
      university: 'Fr. C. Rodrigues Institute of Technology',
      graduationYear: 2027,
      credentialId: 'EDU-DEMO-001',
      status: 'VALID',
    );
  }

  bool get isValid => status.toUpperCase() == 'VALID';

  Map<String, dynamic> toJson() => {
    'student_name': studentName,
    'degree': degree,
    'degree_code': degreeCode,
    'university': university,
    'graduation_year': graduationYear,
    'credential_id': credentialId,
    'status': status,
  };

  factory EducationCredential.fromJson(Map<String, dynamic> json) {
    return EducationCredential(
      studentName: json['student_name'] ?? 'Prashant Pandita',
      degree: json['degree'] ?? 'Bachelor of Technology',
      degreeCode: json['degree_code'] ?? 1,
      university:
          json['university'] ?? 'Fr. C. Rodrigues Institute of Technology',
      graduationYear: json['graduation_year'] ?? 2027,
      credentialId: json['credential_id'] ?? 'EDU-DEMO-001',
      status: json['status'] ?? 'VALID',
    );
  }

  String toRawJson() => jsonEncode(toJson());

  /// Serializes an issuer offer that may be delivered through an offline QR.
  /// A proof payload is deliberately not a valid credential offer.
  String toOfferJson() =>
      jsonEncode({'type': 'education_credential', 'credential': toJson()});

  factory EducationCredential.fromOfferJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> ||
          decoded['type'] != 'education_credential') {
        throw const FormatException(
          'This QR is not an education credential offer.',
        );
      }
      final credential = decoded['credential'];
      if (credential is! Map<String, dynamic>) {
        throw const FormatException('The credential offer is incomplete.');
      }

      final studentName = credential['student_name'];
      final degree = credential['degree'];
      final degreeCode = credential['degree_code'];
      final university = credential['university'];
      final graduationYear = credential['graduation_year'];
      final credentialId = credential['credential_id'];
      final status = credential['status'];
      final validStatus = status == 'VALID' || status == 'REVOKED';

      if (studentName is! String ||
          studentName.trim().isEmpty ||
          degree is! String ||
          degree.trim().isEmpty ||
          degreeCode is! int ||
          degreeCode < 1 ||
          university is! String ||
          university.trim().isEmpty ||
          graduationYear is! int ||
          graduationYear < 1900 ||
          credentialId is! String ||
          credentialId.trim().isEmpty ||
          !validStatus) {
        throw const FormatException('The credential offer has invalid fields.');
      }

      return EducationCredential(
        studentName: studentName,
        degree: degree,
        degreeCode: degreeCode,
        university: university,
        graduationYear: graduationYear,
        credentialId: credentialId,
        status: status,
      );
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('The credential offer could not be read.');
    }
  }

  factory EducationCredential.fromRawJson(String raw) =>
      EducationCredential.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  EducationCredential copyWith({
    String? studentName,
    String? degree,
    int? degreeCode,
    String? university,
    int? graduationYear,
    String? credentialId,
    String? status,
  }) {
    return EducationCredential(
      studentName: studentName ?? this.studentName,
      degree: degree ?? this.degree,
      degreeCode: degreeCode ?? this.degreeCode,
      university: university ?? this.university,
      graduationYear: graduationYear ?? this.graduationYear,
      credentialId: credentialId ?? this.credentialId,
      status: status ?? this.status,
    );
  }
}
