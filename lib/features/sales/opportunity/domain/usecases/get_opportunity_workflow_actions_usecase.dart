import '../entities/opportunity_workflow_info.dart';
import '../repositories/opportunity_repository.dart';

class GetOpportunityWorkflowActionsUseCase {
  final OpportunityRepository repository;

  GetOpportunityWorkflowActionsUseCase(this.repository);

  Future<OpportunityWorkflowInfo> call(String opportunityName) {
    return repository.getWorkflowActions(opportunityName);
  }
}
