class Validators {
  Validators._();

  static final RegExp _emailRegExp = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  static final RegExp _digitsOnlyRegExp = RegExp(r'^\d+$');
  static final RegExp _phoneTenDigitsRegExp = RegExp(r'^\d{10}$');

  /// Validates a required field.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName is required";
    }
    return null;
  }

  /// Validates full name.
  static String? validateName(String? value, {int minLength = 3}) {
    if (value == null || value.trim().isEmpty) {
      return "Full name is required";
    }
    if (value != value.trim()) {
      return "Leading or trailing spaces are not allowed";
    }
    if (value.trim().length < minLength) {
      return "Name must be at least $minLength characters";
    }
    return null;
  }

  /// Validates email address.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email is required";
    }
    if (value != value.trim() || value.contains(' ')) {
      return "Email must not contain spaces";
    }
    if (!_emailRegExp.hasMatch(value.trim())) {
      return "Enter a valid email address";
    }
    return null;
  }

  /// Validates 10-digit phone number.
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Phone number is required";
    }
    if (value != value.trim()) {
      return "Leading or trailing spaces are not allowed";
    }
    final clean = value.trim();
    if (clean.length != 10 || !_phoneTenDigitsRegExp.hasMatch(clean)) {
      return "Phone number must be exactly 10 digits";
    }
    return null;
  }

  /// Validates an input that can be either an email address or a 10-digit phone number (used in login / forgot password).
  static String? validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email or phone number is required";
    }
    if (value != value.trim() || value.contains(' ')) {
      return "Leading, trailing, or embedded spaces are not allowed";
    }
    final clean = value.trim();
    if (_digitsOnlyRegExp.hasMatch(clean)) {
      if (clean.length != 10) {
        return "Phone number must be exactly 10 digits";
      }
      return null;
    }
    if (!_emailRegExp.hasMatch(clean)) {
      return "Enter a valid email address or 10-digit phone number";
    }
    return null;
  }

  /// Validates basic password (minimum characters).
  static String? validateBasicPassword(
    String? value, {
    int minLength = 6,
    String fieldName = "Password",
  }) {
    if (value == null || value.isEmpty) {
      return "$fieldName is required";
    }
    if (value.length < minLength) {
      return "$fieldName must be at least $minLength characters";
    }
    return null;
  }

  /// Validates strong password rules: 8+ chars, uppercase, lowercase, number, symbol.
  static String? validateStrongPassword(
    String? value, {
    String fieldName = "Password",
  }) {
    if (value == null || value.isEmpty) {
      return "$fieldName is required";
    }
    if (value != value.trim()) {
      return "Leading or trailing spaces are not allowed";
    }
    if (value.length < 8) {
      return "$fieldName must be at least 8 characters long";
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "$fieldName must contain an uppercase letter (A-Z)";
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return "$fieldName must contain a lowercase letter (a-z)";
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return "$fieldName must contain a number (0-9)";
    }
    if (!RegExp(r'[!@#\$&*~%^()_\-+=\[\]{}|;:,.<>?/]').hasMatch(value)) {
      return "$fieldName must contain a special character (!@#\$&*)";
    }
    return null;
  }

  /// Validates confirm password matches password.
  static String? validateConfirmPassword(
    String? value,
    String password, {
    String fieldName = "Confirm Password",
  }) {
    if (value == null || value.isEmpty) {
      return "$fieldName is required";
    }
    if (value != password) {
      return "Passwords do not match";
    }
    return null;
  }
}
