class StaffMember {
  const StaffMember({
    required this.id,
    required this.opticalStoreId,
    required this.name,
    required this.email,
    required this.role,
    this.active = true,
  });

  final String id;
  final String opticalStoreId;
  final String name;
  final String email;
  /// Rol del backend (`OPTOMETRIST`, `SALES_ADVISOR`, `TECHNICIAN` o `ADMIN`).
  final String role;
  final bool active;
}
