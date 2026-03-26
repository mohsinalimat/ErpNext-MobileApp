import '../../domain/entities/opportunity_workflow_action.dart';

class OpportunityWorkflowActionModel extends OpportunityWorkflowAction {
  const OpportunityWorkflowActionModel({
    required super.action,
    required super.allowed,
    required super.nextState,
    required super.state,
  });

  factory OpportunityWorkflowActionModel.fromJson(Map<String, dynamic> json) {
    return OpportunityWorkflowActionModel(
      action: json['action']?.toString() ?? '',
      allowed: json['allowed']?.toString() ?? '',
      nextState: json['next_state']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
    );
  }
}
