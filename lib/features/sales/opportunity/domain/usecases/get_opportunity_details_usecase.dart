import '../entities/opportunity_details.dart';
import '../repositories/opportunity_repository.dart';

class GetOpportunityDetailsUseCase {
  final OpportunityRepository repository;

  GetOpportunityDetailsUseCase(this.repository);

  Future<OpportunityDetails> call(String opportunityName) {
    return repository.getOpportunityDetails(opportunityName);
  }
}
