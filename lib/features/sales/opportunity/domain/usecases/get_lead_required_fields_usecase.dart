import '../entities/opportunity_required_fields_result.dart';
import '../repositories/opportunity_repository.dart';

class GetOpportunityRequiredFieldsUseCase {
  final OpportunityRepository repository;

  GetOpportunityRequiredFieldsUseCase(this.repository);

  Future<OpportunityRequiredFieldsResult> call(Map<String, dynamic> data) {
    return repository.getRequiredFields(data);
  }
}
