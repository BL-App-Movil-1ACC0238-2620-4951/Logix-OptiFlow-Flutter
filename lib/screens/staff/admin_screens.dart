import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/optiflow_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chrome.dart';

// ---------------------------------------------------------------- Personal
class StaffMembersScreen extends StatefulWidget {
  const StaffMembersScreen({super.key});

  @override
  State<StaffMembersScreen> createState() => _StaffMembersScreenState();
}

class _StaffMembersScreenState extends State<StaffMembersScreen> {
  bool showForm = false;
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String selectedRole = 'Optometrista';
  String? editingId;

  static const roles = ['Optometrista', 'Técnico de taller', 'Asesora de óptica', 'Administrador'];

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  void _saveMember() {
    if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
      showAppMessage(context, 'Por favor completa nombre y correo.');
      return;
    }
    context.read<OptiFlowController>().addStaffMember(
          name: nameCtrl.text,
          email: emailCtrl.text,
          role: selectedRole,
        );
    nameCtrl.clear();
    emailCtrl.clear();
    passCtrl.clear();
    setState(() => showForm = false);
    showAppMessage(context, 'Miembro del equipo registrado exitosamente.');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final members = app.staffMembers;

    return StaffScaffold(
      tab: StaffTab.more,
      topBar: StaffTopBar(
        title: 'Personal',
        subtitle: 'Equipo de Óptica Visión Norte',
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Equipo de Óptica', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
              ),
              if (!showForm)
                ElevatedButton.icon(
                  onPressed: () => setState(() => showForm = true),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.staffAccent,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (showForm) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nuevo miembro del personal', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre completo', hintText: 'Ej. Dr. Rodrigo Palma'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo electrónico', hintText: 'rodrigo@optiflow.com'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña temporal (mín. 8)', hintText: '••••••••'),
                  ),
                  const SizedBox(height: 12),
                  Text('Rol asignado', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.staffInk)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final r in roles)
                        ChoiceChip(
                          label: Text(r),
                          selected: selectedRole == r,
                          onSelected: (_) => setState(() => selectedRole = r),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => showForm = false),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveMember,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.staffAccent, foregroundColor: AppColors.white),
                          child: const Text('Registrar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          for (final member in members) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: member.active ? AppColors.staffChip : AppColors.slate200,
                        child: Text(member.initials, style: TextStyle(color: member.active ? AppColors.staffHeader : AppColors.slate500, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(member.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: member.active ? AppColors.staffInk : AppColors.slate500)),
                            Text(member.email, style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400)),
                          ],
                        ),
                      ),
                      StatusCapsule(
                        member.active ? member.role : 'Inactivo',
                        color: member.active ? AppColors.staffAccent : AppColors.slate500,
                        background: member.active ? AppColors.staffBlue50 : AppColors.slate200,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  if (editingId == member.id) ...[
                    Text('Selecciona nuevo rol:', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate500)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final r in roles)
                          ActionChip(
                            label: Text(r, style: const TextStyle(fontSize: 11)),
                            onPressed: () {
                              app.updateStaffMemberRole(member.id, r);
                              setState(() => editingId = null);
                              showAppMessage(context, 'Rol actualizado a $r');
                            },
                          ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => editingId = member.id),
                          child: const Text('Cambiar rol', style: TextStyle(fontSize: 12, color: AppColors.staffAccent)),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () {
                            app.toggleStaffMemberStatus(member.id);
                            showAppMessage(context, member.active ? 'Miembro desactivado' : 'Miembro activado');
                          },
                          child: Text(
                            member.active ? 'Desactivar' : 'Activar',
                            style: TextStyle(fontSize: 12, color: member.active ? AppColors.errorRed : AppColors.staffGreen),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Proveedores
class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final nameCtrl = TextEditingController();
  final contactCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    contactCtrl.dispose();
    super.dispose();
  }

  void _add() {
    if (nameCtrl.text.trim().isEmpty) {
      showAppMessage(context, 'Ingresa el nombre o razón social del proveedor.');
      return;
    }
    context.read<OptiFlowController>().addSupplier(
          name: nameCtrl.text,
          contact: contactCtrl.text,
        );
    nameCtrl.clear();
    contactCtrl.clear();
    showAppMessage(context, 'Proveedor registrado.');
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = context.watch<OptiFlowController>().suppliers;

    return StaffScaffold(
      tab: StaffTab.more,
      topBar: StaffTopBar(title: 'Proveedores', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nuevo proveedor', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre o razón social', hintText: 'Ej. Zeiss Vision Care')),
                const SizedBox(height: 10),
                TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contacto', hintText: 'pedidos@zeiss.com · +56 9 8888 7777')),
                const SizedBox(height: 14),
                SolidButton(label: 'Registrar proveedor', onPressed: _add),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Registrados (${suppliers.length})', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 10),
          if (suppliers.isEmpty) Text('Todavía no hay proveedores registrados.', style: GoogleFonts.inter(color: AppColors.slate400)),
          for (final sup in suppliers) ...[
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const IconTile(icon: Icons.business_outlined, background: AppColors.staffChip, color: AppColors.staffHeader),
                title: Text(sup.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.staffInk)),
                subtitle: Text(sup.contact ?? 'Sin información de contacto', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Horarios
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int selectedDayOffset = 0;
  final fromCtrl = TextEditingController(text: '09:00');
  final toCtrl = TextEditingController(text: '13:00');
  int selectedMinutes = 30;

  static const durations = [15, 30, 45, 60];

  @override
  void dispose() {
    fromCtrl.dispose();
    toCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<OptiFlowController>().openScheduleSlots(
          from: fromCtrl.text.trim(),
          to: toCtrl.text.trim(),
          durationMinutes: selectedMinutes,
        );
    showAppMessage(context, 'Turnos abiertos para el horario seleccionado.');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<OptiFlowController>();
    final slots = app.dayScheduleSlots;
    final now = DateTime.now();

    return StaffScaffold(
      tab: StaffTab.more,
      topBar: StaffTopBar(title: 'Horarios de atención', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Día de atención', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final day = now.add(Duration(days: index));
                final label = DateFormat('EEE d', 'es').format(day).replaceAll('.', '');
                final selected = selectedDayOffset == index;
                return ChoiceChip(
                  label: Text(label[0].toUpperCase() + label.substring(1)),
                  selected: selected,
                  onSelected: (_) => setState(() => selectedDayOffset = index),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: fromCtrl,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(labelText: 'Desde', hintText: '09:00'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: toCtrl,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(labelText: 'Hasta', hintText: '13:00'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Duración de cada turno', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final m in durations)
                ChoiceChip(
                  label: Text('$m min'),
                  selected: selectedMinutes == m,
                  onSelected: (_) => setState(() => selectedMinutes = m),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SolidButton(label: 'Abrir turnos', icon: Icons.calendar_month_outlined, onPressed: _submit),
          const SizedBox(height: 24),
          Text('Turnos programados (${slots.length})', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.8,
            ),
            itemCount: slots.length,
            itemBuilder: (_, index) {
              final slot = slots[index];
              return Container(
                decoration: BoxDecoration(
                  color: slot.available ? AppColors.white : AppColors.periwinkle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: slot.available ? AppColors.slate200 : AppColors.lavender),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(slot.time, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.staffInk)),
                    const SizedBox(height: 2),
                    Text(
                      slot.available ? 'Libre' : 'Reservado',
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: slot.available ? AppColors.staffGreen : AppColors.staffAccent),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
