import '../../core/errors/api_exception.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/clinical_forms.dart';
import '../../domain/entities/clinical_record.dart';
import '../../domain/entities/staff_patient.dart';
import '../../domain/repositories/clinical_repository.dart';

/// Port of Movile's ClinicalCareViewModel. Kept independent of Flutter so the
/// complete sequence and recovery cases can run without the widget test engine.
class ClinicalCareFlow {
  ClinicalCareFlow(
      {required this.repository,
      required this.patientId,
      required this.appointmentId,
      this.onChanged,
      this.onCompleted,
      bool Function()? isActive})
      : _isActive = isActive ?? (() => true);
  final ClinicalRepository repository;
  final String patientId;
  final String appointmentId;
  final bool Function() _isActive;
  void Function()? onChanged;
  final Future<void> Function()? onCompleted;
  bool _disposed = false;
  int _loadVersion = 0;
  int formRevision = 0;
  bool loading = false;
  bool saving = false;
  bool _loaded = false;
  String? loadError;
  String? error;
  CareStep step = CareStep.examination;
  StaffPatient? patient;
  Appointment? appointment;
  ClinicalRecord? record;
  String observations = '';
  String allergies = '';
  String previousConditions = '';
  String familyHistory = '';
  PrescriptionForm prescription = PrescriptionForm();
  bool prescriptionSaved = false;

  bool get active => !_disposed && _isActive();
  bool get _canSave =>
      active &&
      _loaded &&
      !loading &&
      !saving &&
      loadError == null &&
      step != CareStep.done;
  String _message(Object e) => e is ApiException
      ? e.message
      : e is FormatException
          ? e.message.toString()
          : 'No se pudo completar la operación. Intenta nuevamente.';
  void _emit() {
    if (active) onChanged?.call();
  }

  void dispose() {
    _disposed = true;
    _loadVersion++;
    onChanged = null;
  }

  void _checkRecord(ClinicalRecord value) {
    if (value.id == null ||
        value.id!.isEmpty ||
        value.patientId != patientId ||
        value.appointmentId != appointmentId) {
      throw ApiException(
          'La ficha recibida no corresponde a esta cita y paciente.');
    }
  }

  void _resume(ClinicalRecord value, {required bool completed}) {
    _checkRecord(value);
    if (value.status == 'PENDING') return;
    record = value;
    observations = value.observations ?? '';
    allergies = value.medicalHistory?.allergies.join(', ') ?? '';
    previousConditions =
        value.medicalHistory?.previousConditions.join(', ') ?? '';
    familyHistory = value.medicalHistory?.familyOcularHistory ?? '';
    prescriptionSaved = value.prescription != null;
    if (value.prescription != null) {
      prescription = PrescriptionForm.fromValues(value.prescription!);
    }
    step = prescriptionSaved && completed
        ? CareStep.done
        : prescriptionSaved || value.medicalHistory != null
            ? CareStep.prescription
            : CareStep.history;
    formRevision++;
  }

  Future<void> load() async {
    if (!active || saving) return;
    final version = ++_loadVersion;
    loading = true;
    loadError = null;
    error = null;
    _emit();
    try {
      if (patientId.isEmpty || appointmentId.isEmpty) {
        throw ApiException('No se encontró la cita.');
      }
      final results = await Future.wait<Object>([
        repository.patient(patientId),
        repository.appointments(patientId),
        repository.records(patientId)
      ]);
      if (!active || version != _loadVersion) return;
      final loadedPatient = results[0] as StaffPatient;
      final found = (results[1] as List<Appointment>)
          .where((a) => a.id == appointmentId && a.patientId == patientId)
          .firstOrNull;
      if (loadedPatient.id != patientId || found == null) {
        throw ApiException('No se encontró la cita de este paciente.');
      }
      if (found.status == 'CANCELLED') {
        throw ApiException('La cita fue cancelada; no se puede atender.');
      }
      patient = loadedPatient;
      appointment = found;
      final existing = (results[2] as List<ClinicalRecord>)
          .where((r) => r.appointmentId == appointmentId)
          .firstOrNull;
      if (existing != null) {
        _resume(existing, completed: found.status == 'COMPLETED');
      }
      if (found.status == 'COMPLETED' && step != CareStep.done) {
        throw ApiException(
            'La cita ya fue completada. Consulta su ficha clínica.');
      }
      _loaded = true;
    } catch (e) {
      if (active && version == _loadVersion) loadError = _message(e);
    } finally {
      if (active && version == _loadVersion) {
        loading = false;
        _emit();
      }
    }
  }

  void changed() {
    if (active && !saving) {
      error = null;
      _emit();
    }
  }

  bool back() {
    if (!active || saving || step != CareStep.prescription || prescriptionSaved) {
      return false;
    }
    step = CareStep.history;
    error = null;
    _emit();
    return true;
  }

  Future<bool> saveExamination() async {
    if (!_canSave || step != CareStep.examination) return false;
    if (observations.length > 500) {
      error = 'Las observaciones pueden tener hasta 500 caracteres.';
      _emit();
      return false;
    }
    saving = true;
    error = null;
    _emit();
    try {
      try {
        final saved = await repository.examine(
            patientId: patientId,
            appointmentId: appointmentId,
            observations: observations);
        if (!active) return false;
        _checkRecord(saved);
        if (saved.status == 'PENDING') {
          throw ApiException('No se pudo verificar el registro del examen.');
        }
        record = saved;
        step = CareStep.history;
      } on ApiException catch (e) {
        if (e.statusCode != 409 || !active) rethrow;
        final records = await repository.records(patientId);
        if (!active) return false;
        final existing = records
            .where((r) =>
                r.appointmentId == appointmentId && r.status != 'PENDING')
            .firstOrNull;
        if (existing == null) rethrow;
        _resume(existing, completed: false);
      }
      return true;
    } catch (e) {
      if (active) error = _message(e);
      return false;
    } finally {
      if (active) {
        saving = false;
        _emit();
      }
    }
  }

  Future<bool> saveHistory() async {
    if (!_canSave ||
        step != CareStep.history ||
        record?.id == null ||
        prescriptionSaved) {
      return false;
    }
    MedicalHistory history;
    try {
      history =
          validateMedicalHistory(allergies, previousConditions, familyHistory);
    } catch (e) {
      error = _message(e);
      _emit();
      return false;
    }
    saving = true;
    error = null;
    _emit();
    try {
      final saved = await repository.saveHistory(record!.id!, history);
      if (!active) return false;
      _checkRecord(saved);
      if (saved.medicalHistory == null) {
        throw ApiException('No se pudo verificar el guardado de antecedentes.');
      }
      record = saved;
      step = CareStep.prescription;
      return true;
    } catch (e) {
      if (active) error = _message(e);
      return false;
    } finally {
      if (active) {
        saving = false;
        _emit();
      }
    }
  }

  Future<bool> savePrescriptionAndFinish() async {
    if (!_canSave || step != CareStep.prescription || record?.id == null) {
      return false;
    }
    PrescriptionValues? values;
    try {
      if (!prescriptionSaved) values = prescription.validate();
    } catch (e) {
      error = _message(e);
      _emit();
      return false;
    }
    saving = true;
    error = null;
    _emit();
    try {
      if (!prescriptionSaved) {
        try {
          final saved = await repository.prescribe(record!.id!, values!);
          if (!active) return false;
          prescription = PrescriptionForm.fromValues(saved);
          prescriptionSaved = true;
          formRevision++;
        } on ApiException catch (e) {
          if (e.statusCode != 409 || !active) rethrow;
          final records = await repository.records(patientId);
          if (!active) return false;
          final existing = records
              .where((r) => r.id == record!.id && r.prescription != null)
              .firstOrNull;
          if (existing == null) rethrow;
          _resume(existing, completed: false);
        }
      }
      if (!active) return false;
      final completed = await repository.complete(appointmentId);
      if (!active) return false;
      if (completed.id != appointmentId ||
          completed.patientId != patientId ||
          completed.status != 'COMPLETED') {
        throw ApiException('No se pudo verificar el cierre de esta cita.');
      }
      appointment = completed;
      step = CareStep.done;
      _emit();
      try {
        await onCompleted?.call();
      } catch (_) {
        /* Reads after a confirmed save must not trigger another write. */
      }
      return true;
    } catch (e) {
      if (active) {
        error = prescriptionSaved
            ? 'La receta se guardó, pero no se pudo cerrar la cita: ${_message(e)}'
            : _message(e);
      }
      return false;
    } finally {
      if (active) {
        saving = false;
        _emit();
      }
    }
  }
}
