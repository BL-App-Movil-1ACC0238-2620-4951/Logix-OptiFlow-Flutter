import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/optiflow_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/chrome.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool register = false;
  bool clinical = false;
  bool obscure = true;
  bool terms = false;
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = context.read<OptiFlowController>();
    final message = app.validateAuth(
      register: register,
      clinical: clinical,
      name: name.text,
      email: email.text,
      phone: phone.text,
      password: password.text,
      terms: terms,
    );
    if (message != null) {
      showAppMessage(context, message);
      return;
    }
    if (clinical) {
      if (!mounted) return;
      context.go('/s/home');
      return;
    }
    if (register) {
      await app.register(name: name.text, email: email.text, phone: phone.text, password: password.text);
    } else {
      await app.login(email: email.text, password: password.text);
    }
    if (!mounted) return;
    if (app.error != null) {
      showAppMessage(context, app.error!);
      return;
    }
    if (app.session?.hasToken == true) context.go('/p/home');
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<OptiFlowController>().busy;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.loginGradientTop, AppColors.white],
            stops: [0, 0.82],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(26, 27, 26, 32),
            children: [
              Center(child: Image.asset('assets/images/img_logo.png', width: 137, height: 108, fit: BoxFit.contain)),
              Text('OptiFlow', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.brand)),
              Text('Tu óptica, siempre cerca', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 16, color: AppColors.tagline)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Color(0x331D3B77), blurRadius: 24, offset: Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    Text('Accede a OptiFlow', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.deepNavy, letterSpacing: -0.6)),
                    const SizedBox(height: 4),
                    Text('Elige cómo usarás la plataforma para preparar tu espacio.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppColors.subtitle)),
                    const SizedBox(height: 14),
                    _ModeSwitch(
                      register: register,
                      onChanged: (value) => setState(() => register = value),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _RoleCard(letter: 'P', title: 'Paciente', description: 'Mis citas, receta y monturas', selected: !clinical, onTap: () => setState(() => clinical = false))),
                        const SizedBox(width: 12),
                        Expanded(child: _RoleCard(letter: 'C', title: 'Personal clínico', description: 'Catálogo, agenda y pacientes', selected: clinical, onTap: () => setState(() => clinical = true))),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (register) ...[
                      _Field(label: 'Nombre completo', controller: name, hint: 'Nombre'),
                      const SizedBox(height: 14),
                    ],
                    _Field(label: 'Correo electrónico', controller: email, hint: 'correo@gmail.com', keyboard: TextInputType.emailAddress),
                    if (register && !clinical) ...[
                      const SizedBox(height: 14),
                      _Field(label: 'Teléfono', controller: phone, hint: '999 888 777', keyboard: TextInputType.phone),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: Text('Contraseña', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepNavy))),
                        Text(
                          register ? 'Mín. ${OptiFlowController.minPassword} caracteres' : '¿Olvidaste tu contraseña?',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: register ? FontWeight.w500 : FontWeight.w600, color: register ? AppColors.slate400 : AppColors.electric),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _Field(
                      controller: password,
                      hint: 'Mínimo ${OptiFlowController.minPassword} caracteres',
                      obscure: obscure,
                      trailing: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: AppColors.slate500),
                      ),
                    ),
                    if (register) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => setState(() => terms = !terms),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: terms ? AppColors.electric : AppColors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: terms ? AppColors.electric : AppColors.deepNavy, width: 1.5),
                              ),
                              child: terms ? const Icon(Icons.check, size: 12, color: AppColors.white) : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.slate500, height: 1.4),
                                  children: const [
                                    TextSpan(text: 'Acepto los '),
                                    TextSpan(text: 'Términos de Servicio', style: TextStyle(color: AppColors.electric, fontWeight: FontWeight.w600)),
                                    TextSpan(text: ' y la '),
                                    TextSpan(text: 'Política de Privacidad', style: TextStyle(color: AppColors.electric, fontWeight: FontWeight.w600)),
                                    TextSpan(text: ' de OptiFlow.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SolidButton(
                      label: register ? 'Crear cuenta' : 'Entrar a mi cuenta',
                      loading: busy,
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _submit,
                    ),
                    if (clinical)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'El personal clínico entra en modo demostración. El backend todavía no tiene cuentas de staff.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate500),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.register, required this.onChanged});
  final bool register;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.periwinkle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skyTint.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          _chip('Iniciar sesión', !register, () => onChanged(false)),
          _chip('Registrarme', register, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(color: selected ? AppColors.white : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppColors.deepNavy : AppColors.slate500)),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.letter, required this.title, required this.description, required this.selected, required this.onTap});
  final String letter;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.periwinkle : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.electric : AppColors.slate200, width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: selected ? AppColors.lavender : AppColors.periwinkle, borderRadius: BorderRadius.circular(12)),
              child: Text(letter, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: selected ? AppColors.electric : AppColors.navyBlue)),
            ),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? AppColors.deepNavy : AppColors.slate700)),
            Text(description, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 10, color: selected ? AppColors.slate500 : AppColors.slate400)),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({this.label, required this.controller, required this.hint, this.keyboard, this.obscure = false, this.trailing});

  final String? label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboard;
  final bool obscure;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboard,
          obscureText: obscure,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.deepNavy),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate500),
            filled: true,
            fillColor: AppColors.mintWhite,
            isDense: true,
            suffixIcon: trailing,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.skyTint)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.electric)),
          ),
        ),
      ],
    );
  }
}
