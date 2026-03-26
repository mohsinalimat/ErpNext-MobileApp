import '../repositories/opportunity_repository.dart';

class AddOpportunityFollowUpUseCase {
  final OpportunityRepository repository;

  AddOpportunityFollowUpUseCase(this.repository);

  Future<void> call({
    required String opportunityName,
    required String followUpDate,
    required String expectedResultDate,
    required String details,
    String? attachment,
  }) {
    return repository.addOpportunityFollowUp(
      opportunityName: opportunityName,
      followUpDate: followUpDate,
      expectedResultDate: expectedResultDate,
      details: details,
      attachment: attachment,
    );
  }
}
