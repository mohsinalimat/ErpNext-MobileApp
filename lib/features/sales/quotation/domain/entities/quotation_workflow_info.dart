import 'quotation_workflow_action.dart';

class QuotationWorkflowInfo {
  final String quotationName;
  final String workflowName;
  final int actionCount;
  final List<QuotationWorkflowAction> actions;

  const QuotationWorkflowInfo({
    required this.quotationName,
    required this.workflowName,
    required this.actionCount,
    required this.actions,
  });

  const QuotationWorkflowInfo.empty()
      : quotationName = '',
        workflowName = '',
        actionCount = 0,
        actions = const [];
}
