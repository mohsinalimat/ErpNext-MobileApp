import '../entities/opportunity_workflow_info.dart';
import '../repositories/opportunity_repository.dart';

class ExecuteOpportunityWorkflowActionUseCase {
  final OpportunityRepository repository;

  ExecuteOpportunityWorkflowActionUseCase(this.repository);

  Future<OpportunityWorkflowInfo> call({
    required String opportunityName,
    required String action,
  }) {
    return repository.executeWorkflowAction(
      opportunityName: opportunityName,
      action: action,
    );
  }
}
