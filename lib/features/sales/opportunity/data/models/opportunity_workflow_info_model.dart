import '../../domain/entities/opportunity_workflow_info.dart';
import 'opportunity_workflow_action_model.dart';

class OpportunityWorkflowInfoModel extends OpportunityWorkflowInfo {
  const OpportunityWorkflowInfoModel({
    required super.opportunityName,
    required super.workflowName,
    required super.actionCount,
    required super.actions,
  });

  factory OpportunityWorkflowInfoModel.fromJson(Map<String, dynamic> json) {
    final payload = _extractPayload(json);
    final actions = payload['actions'] is List
        ? (payload['actions'] as List)
            .whereType<Map<String, dynamic>>()
            .map(OpportunityWorkflowActionModel.fromJson)
            .toList()
        : const <OpportunityWorkflowActionModel>[];

    return OpportunityWorkflowInfoModel(
      opportunityName: payload['opportunity_name']?.toString() ?? '',
      workflowName: payload['workflow_name']?.toString() ?? '',
      actionCount: int.tryParse(payload['action_count']?.toString() ?? '') ??
          actions.length,
      actions: actions,
    );
  }

  static Map<String, dynamic> _extractPayload(Map<String, dynamic> json) {
    final message = json['message'];
    if (message is Map<String, dynamic>) return message;
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return json;
  }
}
