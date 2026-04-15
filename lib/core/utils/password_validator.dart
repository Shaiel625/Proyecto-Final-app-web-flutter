/// Reglas de validación de contraseña compartidas en toda la app.
///
/// Uso en un TextFormField:
///   validator: PasswordValidator.validar,
///
/// Uso para mostrar indicador visual:
///   PasswordStrengthIndicator(password: _ctrl.text)
class PasswordValidator {
  static const int minLength = 8;
 
  // ── Reglas individuales ────────────────────────────────────────────────────
  static bool tieneMayuscula(String v) => v.contains(RegExp(r'[A-Z]'));
  static bool tieneMinuscula(String v) => v.contains(RegExp(r'[a-z]'));
  static bool tieneNumero(String v) => v.contains(RegExp(r'[0-9]'));
  static bool tieneEspecial(String v) =>
      v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\+\=\[\]\\\/]'));
  static bool tieneLongitud(String v) => v.length >= minLength;
 
  /// Devuelve null si es válida, o el mensaje de error si no lo es.
  static String? validar(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa una contraseña';
    if (!tieneLongitud(value)) return 'Mínimo $minLength caracteres';
    if (!tieneMayuscula(value)) return 'Debe tener al menos una mayúscula (A-Z)';
    if (!tieneMinuscula(value)) return 'Debe tener al menos una minúscula (a-z)';
    if (!tieneNumero(value)) return 'Debe tener al menos un número (0-9)';
    if (!tieneEspecial(value)) {
      return 'Debe tener al menos un símbolo (!@#\$%^&*...)';
    }
    return null;
  }
 
  /// Puntaje de 0 a 4 para el indicador visual.
  static int puntaje(String v) {
    int score = 0;
    if (tieneLongitud(v)) score++;
    if (tieneMayuscula(v) && tieneMinuscula(v)) score++;
    if (tieneNumero(v)) score++;
    if (tieneEspecial(v)) score++;
    return score;
  }
}