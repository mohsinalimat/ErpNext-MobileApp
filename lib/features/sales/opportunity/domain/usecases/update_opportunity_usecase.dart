import '../repositories/opportunity_repository.dart';

class UpdateOpportunityUseCase {
  final OpportunityRepository repository;

  UpdateOpportunityUseCase(this.repository);

  Future<void> call(String opportunityName, Map<String, dynamic> data) {
    return repository.updateOpportunity(opportunityName, data);
  }
}
