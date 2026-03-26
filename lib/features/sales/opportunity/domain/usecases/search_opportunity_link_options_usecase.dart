import '../entities/opportunity_option_item.dart';
import '../repositories/opportunity_repository.dart';

class SearchOpportunityLinkOptionsUseCase {
  final OpportunityRepository repository;

  SearchOpportunityLinkOptionsUseCase(this.repository);

  Future<List<OpportunityOptionItem>> call({
    required String doctype,
    String query = '',
  }) {
    return repository.searchLinkOptions(doctype: doctype, query: query);
  }
}
