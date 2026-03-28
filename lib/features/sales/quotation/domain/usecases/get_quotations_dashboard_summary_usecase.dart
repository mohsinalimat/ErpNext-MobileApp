import '../entities/quotation_dashboard_summary.dart';
import '../repositories/quotation_repository.dart';

class GetQuotationsDashboardSummaryUseCase {
  final QuotationRepository repository;

  GetQuotationsDashboardSummaryUseCase(this.repository);

  Future<QuotationDashboardSummary> call({
    String? status,
    String? search,
  }) {
    return repository.getDashboardSummary(status: status, search: search);
  }
}
