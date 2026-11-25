import 'package:flutter/material.dart';

import 'package:logix_optiflow/presentation/pages/staff/staff_clinical_care_screen.dart';

class VisualEvaluationScreen extends StatelessWidget {
  const VisualEvaluationScreen({super.key, this.patientId, this.appointmentId});
  final String? patientId;
  final String? appointmentId;
  @override
  Widget build(BuildContext context) => ClinicalCareScreen(patientId: patientId, appointmentId: appointmentId);
}
