import 'package:flutter/material.dart';
import '../utils/password_validator.dart';
import '../theme/app_theme.dart';
 
/// Widget que muestra en tiempo real qué reglas cumple la contraseña.
///
/// Uso:
///   PasswordStrengthIndicator(password: _passwordCtrl.text)
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
 
  const PasswordStrengthIndicator({super.key, required this.password});
 
  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
 
    final score = PasswordValidator.puntaje(password);
 
    Color barColor;
    String label;
    switch (score) {
      case 0:
      case 1:
        barColor = AppTheme.error;
        label = 'Muy débil';
        break;
      case 2:
        barColor = AppTheme.warning;
        label = 'Débil';
        break;
      case 3:
        barColor = Colors.amber;
        label = 'Aceptable';
        break;
      default:
        barColor = AppTheme.success;
        label = 'Segura';
    }
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Barra de fortaleza
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 5,
                decoration: BoxDecoration(
                  color: i < score ? barColor : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Contraseña: $label',
          style: TextStyle(
              fontSize: 12, color: barColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        // Checklist de reglas
        _Regla(
            texto: 'Mínimo 8 caracteres',
            cumple: PasswordValidator.tieneLongitud(password)),
        _Regla(
            texto: 'Al menos una mayúscula (A-Z)',
            cumple: PasswordValidator.tieneMayuscula(password)),
        _Regla(
            texto: 'Al menos una minúscula (a-z)',
            cumple: PasswordValidator.tieneMinuscula(password)),
        _Regla(
            texto: 'Al menos un número (0-9)',
            cumple: PasswordValidator.tieneNumero(password)),
        _Regla(
            texto: 'Al menos un símbolo (!@#\$%...)',
            cumple: PasswordValidator.tieneEspecial(password)),
      ],
    );
  }
}
 
class _Regla extends StatelessWidget {
  final String texto;
  final bool cumple;
 
  const _Regla({required this.texto, required this.cumple});
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(
            cumple ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 15,
            color: cumple ? AppTheme.success : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              color: cumple ? AppTheme.success : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}