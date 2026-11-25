import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:logix_optiflow/app.dart';
import 'package:logix_optiflow/core/di/dependency_injection.dart';
import 'package:logix_optiflow/presentation/state/optiflow_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await setupDependencies();
  runApp(
    ChangeNotifierProvider(
      create: (_) => OptiFlowController(),
      child: const OptiFlowApp(),
    ),
  );
}
