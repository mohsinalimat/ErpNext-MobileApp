import '../repositories/opportunity_repository.dart';

class CreateOpportunityUseCase {
  final OpportunityRepository repository;

  CreateOpportunityUseCase(this.repository);

  Future<String> call(Map<String, dynamic> data) {
    return repository.createOpportunity(data);
  }
}
