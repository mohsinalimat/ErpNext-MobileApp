import '../entities/opportunity_follow_up.dart';
import '../repositories/opportunity_repository.dart';

class GetOpportunityFollowUpsUseCase {
  final OpportunityRepository repository;

  GetOpportunityFollowUpsUseCase(this.repository);

  Future<List<OpportunityFollowUp>> call(String opportunityName) {
    return repository.getOpportunityFollowUps(opportunityName);
  }
}
