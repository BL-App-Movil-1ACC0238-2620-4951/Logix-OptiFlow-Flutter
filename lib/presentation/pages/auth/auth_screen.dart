import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/optiflow_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/chrome.dart';
import 'auth_fields.dart';
import 'auth_switch.dart';

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
    if (app.busy) return;
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
    if (app.session?.isAuthenticated == true) context.go(app.homeRoute);
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
                    AuthModeSwitch(
                      register: register,
                      onChanged: (value) => setState(() => register = value),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: AuthRoleCard(letter: 'P', title: 'Paciente', description: 'Mis citas, receta y monturas', selected: !clinical, onTap: () => setState(() => clinical = false))),
                        const SizedBox(width: 12),
                        Expanded(child: AuthRoleCard(letter: 'C', title: 'Personal clínico', description: 'Catálogo, agenda y pacientes', selected: clinical, onTap: () => setState(() => clinical = true))),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (register) ...[
                      AuthField(label: 'Nombre completo', controller: name, hint: 'Nombre'),
                      const SizedBox(height: 14),
                    ],
                    AuthField(label: 'Correo electrónico', controller: email, hint: 'correo@gmail.com', keyboard: TextInputType.emailAddress, fillColor: register ? const Color(0xFFEEF2FD) : AppColors.mintWhite),
                    if (register && !clinical) ...[
                      const SizedBox(height: 14),
                      AuthField(label: 'Teléfono', controller: phone, hint: '999 888 777', keyboard: TextInputType.phone),
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
                    AuthField(
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
                      AuthTermsRow(accepted: terms, onToggle: () => setState(() => terms = !terms)),
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
                          'Ingresa con tu cuenta de personal. Las cuentas y los permisos los asigna el administrador de la óptica.',
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
