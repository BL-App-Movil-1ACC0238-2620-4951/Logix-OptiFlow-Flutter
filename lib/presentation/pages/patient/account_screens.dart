import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/edit_profile_view_model.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _vm = getIt<EditProfileViewModel>();

  @override
  void initState() {
    super.initState();
    _vm.load();
    _vm.addListener(_onSaved);
  }

  void _onSaved() {
    if (!_vm.state.saved || !mounted) return;
    _vm.removeListener(_onSaved);
    showAppMessage(context, 'Perfil actualizado.');
    context.pop();
  }

  @override
  void dispose() {
    _vm.removeListener(_onSaved);
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final state = _vm.state;
        return PatientScaffold(
          tab: PatientTab.profile,
          topBar: LightTopBar(title: 'Editar perfil', onBack: () => context.pop()),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: state.loading
                ? [Text('Cargando tus datos...', style: AppFonts.plusJakartaSans(fontSize: 14, color: AppColors.slate500))]
                : [
                    AppCard(
                      borderColor: AppColors.lavender,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileField(label: 'Nombre completo', initial: state.name, hint: 'Tu nombre y apellido', onChanged: _vm.onName),
                          const SizedBox(height: 14),
                          _ProfileField(label: 'Teléfono', initial: state.phone, hint: '999 888 777', keyboard: TextInputType.phone, onChanged: _vm.onPhone),
                          const SizedBox(height: 14),
                          _ProfileField(
                            label: 'Fecha de nacimiento (opcional)',
                            initial: state.birthDate,
                            hint: '24/05/1990',
                            keyboard: TextInputType.datetime,
                            formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9/]'))],
                            onChanged: _vm.onBirthDate,
                          ),
                          const SizedBox(height: 14),
                          const _FieldLabel('Correo'),
                          const SizedBox(height: 6),
                          Text(state.email, style: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.slate500)),
                          Text('El correo es tu usuario para ingresar y no se puede cambiar.', style: AppFonts.plusJakartaSans(fontSize: 11, color: AppColors.slate500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ErrorBanner(state.error),
                    const SizedBox(height: 10),
                    SolidButton(label: state.saving ? 'Guardando...' : 'Guardar cambios', height: 48, onPressed: _vm.save),
                  ],
          ),
        );
      },
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepNavy));
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.initial, required this.hint, required this.onChanged, this.keyboard, this.formatters});
  final String label;
  final String initial;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.skyTint));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initial,
          onChanged: onChanged,
          keyboardType: keyboard,
          inputFormatters: formatters,
          cursorColor: AppColors.electric,
          style: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.deepNavy),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.slate500),
            isDense: true,
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.electric)),
          ),
        ),
      ],
    );
  }
}

/// Pantallas de texto de Configuración.
enum InfoTopic {
  privacy('Privacidad y seguridad'),
  help('Ayuda y documentación'),
  terms('Términos y privacidad');

  const InfoTopic(this.title);
  final String title;

  static InfoTopic from(String? value) => values.firstWhere((t) => t.name == value?.toLowerCase(), orElse: () => help);
}

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, required this.topic});
  final InfoTopic topic;

  @override
  Widget build(BuildContext context) {
    final sections = switch (topic) {
      InfoTopic.privacy => _privacy,
      InfoTopic.help => _patientHelp,
      InfoTopic.terms => _terms,
    };
    return PatientScaffold(
      tab: PatientTab.profile,
      topBar: LightTopBar(title: topic.title, onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          for (final (title, lines) in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                borderColor: AppColors.lavender,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                    for (final line in lines) ...[
                      const SizedBox(height: 8),
                      Text(line, style: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.slate700, height: 19 / 13)),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text('OptiFlow · Versión 1.0.0', textAlign: TextAlign.center, style: AppFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate300)),
        ],
      ),
    );
  }
}

const _privacy = [
  (
    'Tu cuenta',
    [
      'Tu contraseña se guarda cifrada. Nadie del equipo de OptiFlow ni de la óptica puede verla.',
      'Tu sesión vence a las 24 horas. Después tendrás que volver a ingresar.',
      'Si usas un celular compartido, cierra sesión desde Mi Perfil.',
    ],
  ),
  (
    'Tus datos de salud',
    [
      'Tu historial clínico y tus recetas solo los ven tú y el personal autorizado de la óptica.',
      'Ningún otro paciente puede consultar tu información.',
    ],
  ),
  (
    'Permisos del celular',
    [
      'Ubicación: para mostrarte las ópticas cercanas en el mapa. Puedes negarla y buscar las ópticas igual.',
      'Cámara: para el probador virtual de monturas. La imagen se procesa en tu celular y no se envía a ningún servidor.',
      'Notificaciones: para avisarte de tus citas y del avance de tu pedido.',
    ],
  ),
  ('Pagos', ['Los pagos con tarjeta o Yape se hacen en la página de Mercado Pago. OptiFlow no ve ni guarda los datos de tu tarjeta.']),
];

const _patientHelp = [
  ('¿Cómo reservo una cita?', ['En Citas, toca Reservar cita. Elige la óptica, el día y el horario, y confirma. También puedes empezar desde una óptica en Buscar.']),
  ('¿Cómo cancelo o cambio una cita?', ['En Citas, abre la cita y toca Cancelar cita o Reprogramar cita.']),
  ('¿Dónde veo mi receta?', ['En Mi Perfil → Mis recetas. El optómetra la registra después de tu evaluación en la óptica.']),
  ('¿Cómo sé cuándo están listos mis lentes?', ['En Pedidos ves en qué etapa está tu pedido: taller, control de calidad y listo para recoger. Además te llega una notificación.']),
  ('¿Cómo pago?', ['En Mi Perfil → Mis compras, toca Pagar con tarjeta o Yape. También puedes pagar en efectivo en la óptica.']),
  ('¿Qué son los puntos OptiFlow?', ['Recibes 100 puntos en tu cumpleaños. Tu saldo aparece en Mi Perfil.']),
  ('¿Cómo cambio mis datos?', ['En Mi Perfil, toca Editar perfil para cambiar tu nombre, teléfono o fecha de nacimiento.']),
  ('¿Necesitas más ayuda?', ['Acércate a tu óptica y el personal te ayudará.']),
];

const _terms = [
  (
    'Uso de la app',
    [
      'OptiFlow conecta a pacientes con ópticas para reservar citas, ver recetas, seguir pedidos y pagar.',
      'La atención visual y las recetas son responsabilidad del optómetra de cada óptica.',
      'El probador virtual es una referencia: la montura puede verse un poco distinta en persona.',
    ],
  ),
  (
    'Tu información',
    [
      'Usamos tu nombre, correo, teléfono, citas, recetas y compras solo para darte el servicio.',
      'No vendemos ni compartimos tus datos con terceros. La excepción es Mercado Pago, solo para procesar tus pagos.',
      'Puedes cambiar tu nombre y teléfono en Mi Perfil → Editar perfil. Para eliminar tus datos, pídelo en tu óptica.',
    ],
  ),
  (
    'Tu cuenta',
    [
      'Eres responsable de no compartir tu contraseña.',
      'Si no vas a asistir a una cita, cancélala para que el horario quede libre para otro paciente.',
    ],
  ),
];
