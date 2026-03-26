import 'opportunity_workflow_action.dart';

class OpportunityWorkflowInfo {
  final String opportunityName;
  final String workflowName;
  final int actionCount;
  final List<OpportunityWorkflowAction> actions;

  const OpportunityWorkflowInfo({
    required this.opportunityName,
    required this.workflowName,
    required this.actionCount,
    required this.actions,
  });

  const OpportunityWorkflowInfo.empty()
      : opportunityName = '',
        workflowName = '',
        actionCount = 0,
        actions = const [];
}
