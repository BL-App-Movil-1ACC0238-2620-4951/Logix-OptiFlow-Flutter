import 'package:flutter_test/flutter_test.dart';
import 'package:logix_optiflow/domain/entities/models.dart';

void main() {
  test('mapea estados de cita del backend', () {
    expect(AppointmentStatusLabel.fromApi('BOOKED'), AppointmentStatus.confirmed);
    expect(AppointmentStatusLabel.fromApi('cancelled'), AppointmentStatus.cancelled);
    expect(AppointmentStatusLabel.fromApi('WAITLIST'), AppointmentStatus.pending);
  });
}
