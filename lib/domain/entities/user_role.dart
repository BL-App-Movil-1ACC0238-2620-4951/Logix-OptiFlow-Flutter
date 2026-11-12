enum StaffFeature {
  agenda, patients, clinical, stock, inventory, catalog, quotes, sales,
  production, alerts, reports, management,
}

enum UserRole {
  patient('PATIENT', 'Paciente'),
  optometrist('OPTOMETRIST', 'Optometrista'),
  salesAdvisor('SALES_ADVISOR', 'Asesor de ventas'),
  technician('TECHNICIAN', 'Técnico'),
  admin('ADMIN', 'Administrador');

  const UserRole(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static UserRole? fromApi(String? value) {
    for (final role in values) {
      if (role.apiValue == value) return role;
    }
    return null;
  }

  Set<StaffFeature> get features => switch (this) {
    patient => const {},
    optometrist => const {
      StaffFeature.agenda, StaffFeature.patients, StaffFeature.clinical,
    },
    salesAdvisor => const {
      StaffFeature.agenda, StaffFeature.patients, StaffFeature.stock,
      StaffFeature.catalog, StaffFeature.quotes, StaffFeature.sales,
    },
    technician => const {StaffFeature.production},
    admin => StaffFeature.values.toSet(),
  };

  bool can(StaffFeature feature) => features.contains(feature);
}
