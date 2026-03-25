import '../entities/lead_dashboard_summary.dart';
import '../repositories/lead_repository.dart';

class GetLeadsDashboardSummaryUseCase {
  final LeadRepository repository;

  GetLeadsDashboardSummaryUseCase(this.repository);

  Future<LeadDashboardSummary> call({
    String? status,
    String? search,
  }) {
    return repository.getDashboardSummary(status: status, search: search);
  }
}
