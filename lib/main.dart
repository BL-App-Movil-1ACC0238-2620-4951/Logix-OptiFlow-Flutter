import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:logix_optiflow/app.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await setupDependencies();
  runApp(const OptiFlowApp());
}
