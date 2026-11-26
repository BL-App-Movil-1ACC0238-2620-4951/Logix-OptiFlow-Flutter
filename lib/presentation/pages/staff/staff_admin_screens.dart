import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/inventory/presentation/suppliers_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/schedule_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/staff_members_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/presentation/store_search_view_model.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';
import 'package:logix_optiflow/presentation/widgets/staff_widgets.dart';

void _back(BuildContext context) => context.canPop() ? context.pop() : context.go('/s/more');

Widget _adminScaffold(BuildContext context, String title, List<Widget> children) => StaffScaffold(
      tab: null,
      showBottomBar: false,
      topBar: StaffTopBar(title: title, onBack: () => _back(context)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: children),
    );

Text _muted(String text) => Text(text, style: AppFonts.inter(fontSize: 12, color: AppColors.slate400));

/// Mensaje verde de éxito o rojo de error, como el `Feedback` de Kotlin.
List<Widget> _feedback(String? message, String? error) => [
      if (message != null) ...[
        Text(message, style: AppFonts.inter(fontSize: 12, color: AppColors.staffGreen)),
        const SizedBox(height: 12),
      ],
      if (error != null) ...[
        Text(error, style: AppFonts.inter(fontSize: 12, color: AppColors.errorRed)),
        const SizedBox(height: 12),
      ],
    ];

Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(16), double radius = 16, Color color = AppColors.white}) =>
    AppCard(padding: padding, radius: radius, color: color, borderColor: AppColors.staffBorder, child: child);

// ---------------------------------------------------------------- Personal

/// Personal (`/s/admin/staff`), igual a Kotlin: alta, cambio de rol y activación del equipo de la óptica.
class StaffMembersScreen extends StatefulWidget {
  const StaffMembersScreen({super.key});

  @override
  State<StaffMembersScreen> createState() => _StaffMembersScreenState();
}

class _StaffMembersScreenState extends State<StaffMembersScreen> {
  final _vm = getIt<StaffMembersViewModel>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm.load(getIt<SessionViewModel>().session?.opticalStoreId);
  }

  @override
  void dispose() {
    _vm.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showForm(bool show) {
    _name.clear();
    _email.clear();
    _password.clear();
    _vm.showForm(show);
  }

  @override
  Widget build(BuildContext context) {
    final staffId = getIt<SessionViewModel>().session?.patientId;
    final storeName = getIt<StoreSearchViewModel>().staffStoreName;
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final state = _vm.state;
        return _adminScaffold(context, 'Personal', [
          Text('Equipo de $storeName', style: AppFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
          const SizedBox(height: 12),
          if (state.showForm) ...[
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nuevo miembro del personal', style: AppFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
                  const SizedBox(height: 12),
                  StaffInput(controller: _name, placeholder: 'Nombre completo', inputFormatters: [LengthLimitingTextInputFormatter(120)]),
                  const SizedBox(height: 10),
                  StaffInput(
                    controller: _email,
                    placeholder: 'Correo',
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s')), LengthLimitingTextInputFormatter(120)],
                  ),
                  const SizedBox(height: 10),
                  StaffInput(controller: _password, placeholder: 'Contraseña temporal (mín. 8)', inputFormatters: [LengthLimitingTextInputFormatter(64)]),
                  const SizedBox(height: 10),
                  StaffSelect(text: 'Rol: ${staffRoleLabel(state.role.apiValue)}', onTap: _vm.nextRole),
                  const SizedBox(height: 12),
                  ..._feedback(null, state.error),
                  Row(
                    children: [
                      Expanded(
                        child: StaffButton(
                          label: 'Cancelar',
                          onPressed: () => _showForm(false),
                          background: AppColors.white,
                          foreground: AppColors.staffInk,
                          border: AppColors.staffBorder,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StaffButton(
                          label: state.saving ? 'Guardando...' : 'Registrar',
                          onPressed: () => _vm.register(name: _name.text, email: _email.text, password: _password.text),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            StaffButton(label: 'Agregar personal', icon: LucideIcons.plus, onPressed: () => _showForm(true)),
            const SizedBox(height: 16),
            ..._feedback(state.message, state.error),
          ],
          if (state.loading) _muted('Cargando...'),
          for (final member in state.members) ...[
            _card(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StaffInitials(_initials(member.name), size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(member.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.inter(fontSize: 12, color: AppColors.staffInk)),
                            Text(member.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.inter(fontSize: 9, color: AppColors.slate400)),
                          ],
                        ),
                      ),
                      StaffPill(member.active ? staffRoleLabel(member.role) : 'Inactivo', size: 8),
                    ],
                  ),
                  if (member.id != staffId) ...[
                    const SizedBox(height: 10),
                    if (state.editingId == member.id)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final role in staffRoles) ...[
                              if (role != staffRoles.first) const SizedBox(width: 8),
                              StaffChip(
                                staffRoleLabel(role.apiValue),
                                selected: role.apiValue == member.role,
                                onTap: () => role.apiValue == member.role ? _vm.editRole(null) : _vm.changeRole(member, role),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _vm.editRole(member.id),
                            child: Text('Cambiar rol', style: AppFonts.inter(fontSize: 10, color: AppColors.staffAccent)),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => _vm.toggleActive(member),
                            child: Text(
                              member.active ? 'Desactivar' : 'Activar',
                              style: AppFonts.inter(fontSize: 10, color: member.active ? AppColors.errorRed : AppColors.staffGreen),
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ]);
      },
    );
  }

  String _initials(String name) =>
      name.split(' ').where((part) => part.trim().isNotEmpty).take(2).map((part) => part[0].toUpperCase()).join();
}

// ---------------------------------------------------------------- Proveedores

/// Proveedores (`/s/admin/suppliers`), igual a Kotlin: alta y lista de registrados.
class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _vm = getIt<SuppliersViewModel>();
  final _name = TextEditingController();
  final _contact = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    _name.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (await _vm.register(_name.text, _contact.text)) {
      _name.clear();
      _contact.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final state = _vm.state;
        return _adminScaffold(context, 'Proveedores', [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nuevo proveedor', style: AppFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.staffInk)),
                const SizedBox(height: 12),
                StaffInput(controller: _name, placeholder: 'Nombre o razón social', inputFormatters: [LengthLimitingTextInputFormatter(255)]),
                const SizedBox(height: 10),
                StaffInput(
                  controller: _contact,
                  placeholder: 'Contacto (correo o teléfono, opcional)',
                  inputFormatters: [LengthLimitingTextInputFormatter(255)],
                ),
                const SizedBox(height: 12),
                ..._feedback(state.message, state.error),
                StaffButton(label: state.saving ? 'Guardando...' : 'Registrar proveedor', onPressed: _register),
              ],
            ),
          ),
          const SizedBox(height: 20),
          StaffSectionTitle('Registrados · ${state.suppliers.length}'),
          const SizedBox(height: 12),
          if (state.loading) _muted('Cargando...'),
          if (!state.loading && state.suppliers.isEmpty) _muted('Todavía no hay proveedores.'),
          if (state.suppliers.isNotEmpty)
            _card(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final (index, supplier) in state.suppliers.indexed) ...[
                    if (index > 0) const Divider(height: 1, color: AppColors.staffBorder),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(supplier.name, style: AppFonts.inter(fontSize: 12, color: AppColors.staffInk)),
                                Text(supplier.contact.isEmpty ? 'Sin contacto' : supplier.contact,
                                    style: AppFonts.inter(fontSize: 9, color: AppColors.slate400)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ]);
      },
    );
  }
}

// ---------------------------------------------------------------- Horarios

/// Horarios de atención (`/s/admin/schedule`), igual a Kotlin: abre turnos de un día en la óptica.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _vm = getIt<ScheduleViewModel>();
  late final _from = TextEditingController(text: _vm.state.from);
  late final _to = TextEditingController(text: _vm.state.to);
  static final _dayChip = DateFormat('EEE d', 'es');
  static final _hour = DateFormat('HH:mm');
  static final _hourFormatters = [FilteringTextInputFormatter.allow(RegExp('[0-9:]')), LengthLimitingTextInputFormatter(5)];

  @override
  void initState() {
    super.initState();
    _vm.load(getIt<SessionViewModel>().session?.opticalStoreId);
  }

  @override
  void dispose() {
    _vm.dispose();
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  String _range(DateTime start, DateTime end) => '${_hour.format(StoreTime.clock(start))}–${_hour.format(StoreTime.clock(end))}';

  @override
  Widget build(BuildContext context) {
    final today = StoreTime.today();
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final state = _vm.state;
        final count = _vm.preview;
        final slots = state.daySlots;
        final label = AppFonts.inter(fontSize: 13, color: AppColors.staffInk);
        return _adminScaffold(context, 'Horarios de atención', [
          Text('Día', style: label),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < scheduleDays; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Builder(builder: (_) {
                    final day = DateTime(today.year, today.month, today.day + i);
                    return StaffChip(_dayChip.format(day).replaceAll('.', ''), selected: day == state.day, onTap: () => _vm.selectDay(day));
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StaffLabel('Desde'),
                    const SizedBox(height: 8),
                    StaffInput(controller: _from, placeholder: '09:00', keyboardType: TextInputType.datetime, inputFormatters: _hourFormatters, onChanged: _vm.setFrom),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StaffLabel('Hasta'),
                    const SizedBox(height: 8),
                    StaffInput(controller: _to, placeholder: '13:00', keyboardType: TextInputType.datetime, inputFormatters: _hourFormatters, onChanged: _vm.setTo),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Duración de cada turno', style: label),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final m in slotMinutes) ...[
                if (m != slotMinutes.first) const SizedBox(width: 8),
                StaffChip('$m min', selected: m == state.minutes, onTap: () => _vm.setMinutes(m)),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(count == null ? 'Revisa las horas.' : 'Se abrirán $count turnos.', style: AppFonts.inter(fontSize: 11, color: AppColors.slate400)),
          const SizedBox(height: 12),
          ..._feedback(state.message, state.error),
          StaffButton(label: state.saving ? 'Abriendo...' : 'Abrir turnos', icon: LucideIcons.calendar, onPressed: _vm.submit),
          const SizedBox(height: 24),
          StaffSectionTitle('Turnos de ese día · ${slots.length}'),
          const SizedBox(height: 12),
          if (state.loading) _muted('Cargando...'),
          if (!state.loading && slots.isEmpty) _muted('No hay turnos abiertos ese día.'),
          for (var i = 0; i < slots.length; i += 3) ...[
            Row(
              children: [
                for (var j = i; j < i + 3; j++) ...[
                  if (j > i) const SizedBox(width: 8),
                  Expanded(
                    child: j >= slots.length
                        ? const SizedBox.shrink()
                        : Builder(builder: (_) {
                            final slot = slots[j];
                            final free = slot.status.toUpperCase() == 'AVAILABLE';
                            return _card(
                              radius: 12,
                              padding: const EdgeInsets.all(10),
                              color: free ? AppColors.white : AppColors.lavender,
                              child: Column(
                                children: [
                                  Text(_range(slot.start, slot.end), style: AppFonts.inter(fontSize: 11, color: AppColors.staffInk)),
                                  Text(free ? 'Libre' : 'Reservado',
                                      style: AppFonts.inter(fontSize: 8, color: free ? AppColors.staffGreen : AppColors.staffAccent)),
                                ],
                              ),
                            );
                          }),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
          ],
        ]);
      },
    );
  }
}
