import '../entities/opportunity_required_fields_result.dart';
import '../repositories/opportunity_repository.dart';

class GetOpportunityFormUseCase {
  final OpportunityRepository repository;

  GetOpportunityFormUseCase(this.repository);

  Future<OpportunityRequiredFieldsResult> call({String? opportunityName}) {
    return repository.getOpportunityForm(opportunityName: opportunityName);
  }
}
