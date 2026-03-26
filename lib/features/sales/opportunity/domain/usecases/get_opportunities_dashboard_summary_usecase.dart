import '../entities/opportunity_dashboard_summary.dart';
import '../repositories/opportunity_repository.dart';

class GetOpportunitiesDashboardSummaryUseCase {
  final OpportunityRepository repository;

  GetOpportunitiesDashboardSummaryUseCase(this.repository);

  Future<OpportunityDashboardSummary> call({
    String? status,
    String? search,
  }) {
    return repository.getDashboardSummary(status: status, search: search);
  }
}
