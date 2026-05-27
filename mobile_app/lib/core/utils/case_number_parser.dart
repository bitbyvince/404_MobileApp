/// Parses and validates TB case numbers in the format:
///   PHNT-{province}-{municipality}-{regimen}{year}-{sequence}
///
/// Examples:
///   PHNT-137-071-S26-0001   → Standard regimen, 2026, patient #1
///   PHNT-1304-071-DR26-0002 → Drug-resistant regimen, patient #2
class CaseNumberParser {
  CaseNumberParser._();

  // PHNT-{3-4 digits}-{3 digits}-{S|DR}{2 digits}-{4 digits}
  static final RegExp _pattern = RegExp(
    r'^PHNT-(\d{3,4})-(\d{3})-(S|DR)(\d{2})-(\d{4})$',
  );

  /// Returns true if [caseNumber] matches the expected format.
  static bool isValid(String caseNumber) =>
      _pattern.hasMatch(caseNumber.trim().toUpperCase());

  /// Parses [caseNumber] into its component parts.
  /// Returns null if the format is invalid.
  static CaseNumberComponents? parse(String caseNumber) {
    final match = _pattern.firstMatch(caseNumber.trim().toUpperCase());
    if (match == null) return null;

    final regimenPrefix = match.group(3)!;
    final yearSuffix = match.group(4)!;

    return CaseNumberComponents(
      provinceCode: match.group(1)!,
      municipalityCode: match.group(2)!,
      regimenPrefix: regimenPrefix,
      year: int.parse('20$yearSuffix'),
      sequence: int.parse(match.group(5)!),
      isDrugResistant: regimenPrefix == 'DR',
      raw: caseNumber.trim().toUpperCase(),
    );
  }

  /// Extracts the 2-digit year from a valid case number.
  /// e.g. "PHNT-137-071-S26-0001" → 2026
  /// Returns null if invalid.
  static int? extractYear(String caseNumber) => parse(caseNumber)?.year;

  /// Extracts the sequential patient number.
  /// e.g. "PHNT-137-071-S26-0042" → 42
  /// Returns null if invalid.
  static int? extractSequence(String caseNumber) => parse(caseNumber)?.sequence;

  /// Returns a human-readable label for the regimen type.
  static String regimenLabel(String caseNumber) {
    final components = parse(caseNumber);
    if (components == null) return 'Unknown';
    return components.isDrugResistant ? 'Drug-Resistant' : 'Standard';
  }

  /// Masks the case number for display in sensitive contexts.
  /// e.g. "PHNT-137-071-S26-0001" → "PHNT-***-***-S26-0001"
  static String mask(String caseNumber) {
    final c = parse(caseNumber);
    if (c == null) return caseNumber;
    return 'PHNT-***-***-${c.regimenPrefix}${c.year.toString().substring(2)}-'
        '${c.sequence.toString().padLeft(4, '0')}';
  }
}

/// Immutable value object holding the parsed parts of a TB case number.
class CaseNumberComponents {
  const CaseNumberComponents({
    required this.provinceCode,
    required this.municipalityCode,
    required this.regimenPrefix,
    required this.year,
    required this.sequence,
    required this.isDrugResistant,
    required this.raw,
  });

  final String provinceCode;
  final String municipalityCode;
  final String regimenPrefix; // "S" or "DR"
  final int year; // full year, e.g. 2026
  final int sequence; // e.g. 42
  final bool isDrugResistant;
  final String raw; // original uppercased input

  @override
  String toString() => raw;
}
