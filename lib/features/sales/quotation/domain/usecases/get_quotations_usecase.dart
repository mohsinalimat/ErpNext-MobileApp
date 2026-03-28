import '../entities/quotation.dart';
import '../repositories/quotation_repository.dart';

class GetQuotationsUseCase {
  final QuotationRepository repository;

  GetQuotationsUseCase(this.repository);

  Future<List<Quotation>> call({
    required int start,
    required int limit,
    String? status,
    String? search,
    String? followUpFilter,
    String? sortBy,
  }) {
    return repository.getQuotations(
      start: start,
      limit: limit,
      status: status,
      search: search,
      followUpFilter: followUpFilter,
      sortBy: sortBy,
    );
  }
}
