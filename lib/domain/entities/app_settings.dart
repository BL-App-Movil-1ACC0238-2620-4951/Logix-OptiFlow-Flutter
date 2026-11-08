class AppSettings {
  const AppSettings({this.controlReminders = false});

  final bool controlReminders;

  AppSettings copyWith({bool? controlReminders}) {
    return AppSettings(controlReminders: controlReminders ?? this.controlReminders);
  }
}
