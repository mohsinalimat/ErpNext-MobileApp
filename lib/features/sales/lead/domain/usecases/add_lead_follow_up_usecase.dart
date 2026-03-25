import '../repositories/lead_repository.dart';

class AddLeadFollowUpUseCase {
  final LeadRepository repository;

  AddLeadFollowUpUseCase(this.repository);

  Future<void> call({
    required String leadName,
    required String followUpDate,
    required String expectedResultDate,
    required String details,
    String? attachment,
  }) {
    return repository.addLeadFollowUp(
      leadName: leadName,
      followUpDate: followUpDate,
      expectedResultDate: expectedResultDate,
      details: details,
      attachment: attachment,
    );
  }
}
