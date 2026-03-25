import '../entities/lead_option_item.dart';
import '../repositories/lead_repository.dart';

class SearchLeadLinkOptionsUseCase {
  final LeadRepository repository;

  SearchLeadLinkOptionsUseCase(this.repository);

  Future<List<LeadOptionItem>> call({
    required String doctype,
    String query = '',
  }) {
    return repository.searchLinkOptions(doctype: doctype, query: query);
  }
}
