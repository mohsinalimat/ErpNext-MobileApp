import '../../domain/entities/quotation_workflow_action.dart';

class QuotationWorkflowActionModel extends QuotationWorkflowAction {
  const QuotationWorkflowActionModel({
    required super.action,
    required super.allowed,
    required super.nextState,
    required super.state,
  });

  factory QuotationWorkflowActionModel.fromJson(Map<String, dynamic> json) {
    return QuotationWorkflowActionModel(
      action: json['action']?.toString() ?? '',
      allowed: json['allowed']?.toString() ?? '',
      nextState: json['next_state']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
    );
  }
}
