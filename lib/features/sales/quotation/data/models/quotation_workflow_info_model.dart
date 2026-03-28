import '../../domain/entities/quotation_workflow_info.dart';
import 'quotation_workflow_action_model.dart';

class QuotationWorkflowInfoModel extends QuotationWorkflowInfo {
  const QuotationWorkflowInfoModel({
    required super.quotationName,
    required super.workflowName,
    required super.actionCount,
    required super.actions,
  });

  factory QuotationWorkflowInfoModel.fromJson(Map<String, dynamic> json) {
    final payload = _extractPayload(json);
    final actions = payload['actions'] is List
        ? (payload['actions'] as List)
            .whereType<Map<String, dynamic>>()
            .map(QuotationWorkflowActionModel.fromJson)
            .toList()
        : const <QuotationWorkflowActionModel>[];

    return QuotationWorkflowInfoModel(
      quotationName: payload['quotation_name']?.toString() ?? '',
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
