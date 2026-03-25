import '../entities/lead.dart';
import '../repositories/lead_repository.dart';

class GetLeadsUseCase {
  final LeadRepository repository;

  GetLeadsUseCase(this.repository);

  Future<List<Lead>> call({
    required int start,
    required int limit,
    String? status,
    String? search,
    String? followUpFilter,
    String? sortBy,
  }) {
    return repository.getLeads(
      start: start,
      limit: limit,
      status: status,
      search: search,
      followUpFilter: followUpFilter,
      sortBy: sortBy,
    );
  }
}
