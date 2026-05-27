/// Form field validators for the RespiraTrack patient app.
///
/// All validators follow the Flutter FormField signature:
///   String? Function(String? value)
///
/// Return null  → field is valid
/// Return String → error message to display
class AppValidators {
  AppValidators._();

  // ── TB Case Number ───────────────────────────────────────

  /// Validates PHNT-{province}-{municipality}-{S|DR}{YY}-{XXXX} format.
  static String? tbCaseNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'TB case number is required.';
    }
    final pattern = RegExp(r'^PHNT-\d{3,4}-\d{3}-(S|DR)\d{2}-\d{4}$');
    if (!pattern.hasMatch(value.trim().toUpperCase())) {
      return 'Format must be PHNT-137-071-S26-0001.';
    }
    return null;
  }

  // ── Phone Number ─────────────────────────────────────────

  /// Validates Philippine mobile numbers in E.164 format: +639XXXXXXXXX
  static String? phoneNumber(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Phone number is required.' : null;
    }
    final pattern = RegExp(r'^\+639\d{9}$');
    if (!pattern.hasMatch(value.trim())) {
      return 'Phone number must be in the format +639XXXXXXXXX.';
    }
    return null;
  }

  // ── PIN ──────────────────────────────────────────────────

  /// Validates a 4-digit numeric PIN.
  static String? pin(String? value, {String label = 'PIN'}) {
    if (value == null || value.isEmpty) return '$label is required.';
    if (value.length != 4) return '$label must be exactly 4 digits.';
    if (!RegExp(r'^\d{4}$').hasMatch(value))
      return '$label must contain only numbers.';
    return null;
  }

  /// Validates that a confirmation PIN matches the original.
  static String? confirmPin(String? value, {required String original}) {
    final baseError = pin(value, label: 'Confirm PIN');
    if (baseError != null) return baseError;
    if (value != original) return 'PINs do not match.';
    return null;
  }

  // ── Email ────────────────────────────────────────────────

  static String? email(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Email address is required.' : null;
    }
    final pattern = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!pattern.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  // ── Name ─────────────────────────────────────────────────

  static String? name(String? value, {String label = 'Name'}) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    if (value.trim().length < 2) return '$label must be at least 2 characters.';
    if (value.trim().length > 64)
      return '$label must not exceed 64 characters.';
    return null;
  }

  // ── Required (generic) ───────────────────────────────────

  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  // ── Free text (notes, remarks) ───────────────────────────

  /// Optional free-text field with a max length guard.
  static String? freeText(String? value, {int maxLength = 500}) {
    if (value == null || value.isEmpty) return null;
    if (value.length > maxLength)
      return 'Must not exceed $maxLength characters.';
    return null;
  }

  // ── Date ─────────────────────────────────────────────────

  /// Ensures the selected date is not in the future.
  static String? notFutureDate(DateTime? value, {String label = 'Date'}) {
    if (value == null) return '$label is required.';
    if (value.isAfter(DateTime.now())) return '$label cannot be in the future.';
    return null;
  }

  /// Ensures the selected date is not in the past.
  static String? notPastDate(DateTime? value, {String label = 'Date'}) {
    if (value == null) return '$label is required.';
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    if (value.isBefore(today)) return '$label cannot be in the past.';
    return null;
  }

  // ── Symptom severity ─────────────────────────────────────

  /// Validates that severity is 1, 2, or 3.
  static String? symptomSeverity(int? value) {
    if (value == null) return 'Severity is required.';
    if (![1, 2, 3].contains(value))
      return 'Severity must be 1 (Mild), 2 (Moderate), or 3 (Severe).';
    return null;
  }

  // ── Composite: login identifier ──────────────────────────

  /// Validates whichever identifier the patient chose to log in with.
  /// [method] should be "tb_case_number", "phone_number", or "email".
  static String? loginIdentifier(String? value, {required String method}) {
    switch (method) {
      case 'tb_case_number':
        return tbCaseNumber(value);
      case 'phone_number':
        return phoneNumber(value, required: true);
      case 'email':
        return email(value, required: true);
      default:
        return required(value, label: 'Identifier');
    }
  }
}
