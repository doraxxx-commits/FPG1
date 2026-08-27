import '../models/club.dart';
import '../models/player.dart';
import '../models/player_career.dart';

/// P1.6: verifies that the player-controlled career and its world projection
/// describe the same person after a WorldEngine tick.
class CareerWorldIntegrityValidator {
  const CareerWorldIntegrityValidator();

  List<String> validate({
    required PlayerCareer career,
    required Player projection,
    required List<Club> clubs,
  }) {
    final errors = <String>[];
    if (career.id != projection.id) errors.add('career/projection id mismatch');
    if (career.clubId != projection.clubId) errors.add('clubId mismatch');
    if (career.age != projection.age) errors.add('age mismatch');
    if (career.overall != projection.overall) errors.add('overall mismatch');
    if (career.potential != projection.potential) errors.add('potential mismatch');
    if (career.pace != projection.pace ||
        career.shooting != projection.shooting ||
        career.passing != projection.passing ||
        career.dribbling != projection.dribbling ||
        career.defending != projection.defending ||
        career.physical != projection.physical) {
      errors.add('attribute mismatch');
    }
    if (career.fitness != projection.fitness ||
        career.form != projection.form ||
        career.fatigue != projection.fatigue) {
      errors.add('condition mismatch');
    }
    if (career.contractYearsRemaining != projection.contractYearsRemaining) {
      errors.add('contract duration mismatch');
    }
    if (career.clubId != null && !clubs.any((c) => c.id == career.clubId)) {
      errors.add('career club does not exist');
    }
    return errors;
  }

  bool isValid({
    required PlayerCareer career,
    required Player projection,
    required List<Club> clubs,
  }) => validate(career: career, projection: projection, clubs: clubs).isEmpty;
}
