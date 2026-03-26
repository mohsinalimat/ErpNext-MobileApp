import '../entities/opportunity.dart';
import '../repositories/opportunity_repository.dart';

class GetOpportunitiesUseCase {
  final OpportunityRepository repository;

  GetOpportunitiesUseCase(this.repository);

  Future<List<Opportunity>> call({
    required int start,
    required int limit,
    String? status,
    String? search,
    String? followUpFilter,
    String? sortBy,
  }) {
    return repository.getOpportunities(
      start: start,
      limit: limit,
      status: status,
      search: search,
      followUpFilter: followUpFilter,
      sortBy: sortBy,
    );
  }
}
