import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/core/theme/app_colors.dart';
import 'package:logix_optiflow/core/theme/app_fonts.dart';
import 'package:logix_optiflow/features/notification/domain/patient_notification.dart';
import 'package:logix_optiflow/features/notification/presentation/notifications_view_model.dart';
import 'package:logix_optiflow/presentation/widgets/chrome.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with WidgetsBindingObserver {
  final _vm = getIt<NotificationsViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _vm.refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Al volver a la app (por ejemplo, tocando un push) se recarga la lista.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _vm.refresh();
  }

  void _open(PatientNotification item) {
    if (item.kind == NotificationKind.survey) {
      // Responder la encuesta también la marca como leída en el backend.
      if (item.surveyRating == null) {
        showDialog<void>(context: context, builder: (_) => _SurveyDialog(item: item));
      }
      return;
    }
    _vm.markRead(item);
    final path = switch (item.kind) {
      NotificationKind.appointment => item.appointmentId == null ? '/p/appointments' : '/p/appointment/${item.appointmentId}',
      NotificationKind.order => item.workOrderId == null ? '/p/orders' : '/p/order/${item.workOrderId}',
      NotificationKind.health => '/p/book',
      NotificationKind.promo => '/p/profile',
      NotificationKind.survey => null,
    };
    if (path != null) context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final state = _vm.state;
        final sections = _vm.sections;
        return PatientScaffold(
          tab: null,
          topBar: DarkTopBar(title: 'Notificaciones', onBack: () => context.canPop() ? context.pop() : context.go('/p/home')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _vm.markAllRead,
                  child: Text('Marcar leídas', style: AppFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.electric)),
                ),
              ),
              if (state.loading && sections.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.electric)),
                ),
              if (state.error != null) Padding(padding: const EdgeInsets.only(top: 12), child: ErrorBanner(state.error)),
              for (final section in sections) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(section.title, style: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
                ),
                const SizedBox(height: 8),
                for (final item in section.items) _NotificationRow(item: item, onTap: () => _open(item)),
              ],
              if (!state.loading && state.error == null && sections.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Text('No tienes notificaciones por ahora.', textAlign: TextAlign.center, style: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.slate500)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item, required this.onTap});
  final PatientNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.kind) {
      NotificationKind.appointment => LucideIcons.calendar,
      NotificationKind.order => LucideIcons.package,
      NotificationKind.health => LucideIcons.eye,
      NotificationKind.promo => LucideIcons.megaphone,
      NotificationKind.survey => LucideIcons.star,
    };
    final survey = item.kind == NotificationKind.survey;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTile(icon: icon, background: AppColors.periwinkle, color: AppColors.navyBlue),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: AppFonts.plusJakartaSans(fontSize: 13, fontWeight: item.read ? FontWeight.w500 : FontWeight.w700, color: AppColors.deepNavy)),
                      const SizedBox(height: 3),
                      Text(item.message, style: AppFonts.openSansCondensed(fontSize: 12, color: AppColors.slate500)),
                      if (survey) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.surveyRating != null ? 'Respondiste con ${item.surveyRating} de 5 estrellas' : 'Toca para responder',
                          style: AppFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.electric),
                        ),
                      ],
                      const SizedBox(height: 9),
                      Text(_ago(item.occurredAt), style: AppFonts.plusJakartaSans(fontSize: 10, color: AppColors.slate400)),
                    ],
                  ),
                ),
                if (!item.read)
                  Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: const BoxDecoration(color: AppColors.electric, shape: BoxShape.circle))
                else if (!survey)
                  const Padding(padding: EdgeInsets.only(top: 18), child: Icon(LucideIcons.chevronRight, color: AppColors.navyBlue, size: 20)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.skyTint),
        ],
      ),
    );
  }

  String _ago(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inHours < 1) return 'Hace un momento';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inHours < 48) return 'Ayer';
    return 'Hace ${diff.inDays} días';
  }
}

class _SurveyDialog extends StatefulWidget {
  const _SurveyDialog({required this.item});
  final PatientNotification item;

  @override
  State<_SurveyDialog> createState() => _SurveyDialogState();
}

class _SurveyDialogState extends State<_SurveyDialog> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_rating == 0) {
      showAppMessage(context, 'Elige de 1 a 5 estrellas');
      return;
    }
    if (_sending) return;
    setState(() => _sending = true);
    final error = await getIt<NotificationsViewModel>().answerSurvey(widget.item.id, _rating, _comment.text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) {
      showAppMessage(context, error);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Encuesta de satisfacción', style: AppFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
            const SizedBox(height: 6),
            Text(widget.item.message, style: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.slate500)),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var value = 1; value <= 5; value++)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _rating = value),
                      child: Icon(LucideIcons.star, size: 30, color: value <= _rating ? AppColors.electric : AppColors.slate300),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _comment,
              maxLength: 500,
              maxLines: null,
              style: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.deepNavy),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                hintText: 'Cuéntanos más (opcional)',
                hintStyle: AppFonts.plusJakartaSans(fontSize: 13, color: AppColors.slate400),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.skyTint)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.electric)),
              ),
            ),
            const SizedBox(height: 16),
            SolidButton(
              label: _sending ? 'Enviando...' : 'Enviar respuesta',
              onPressed: _send,
              height: 46,
              textStyle: AppFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
