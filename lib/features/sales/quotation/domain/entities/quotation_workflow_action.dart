class QuotationWorkflowAction {
  final String action;
  final String allowed;
  final String nextState;
  final String state;

  const QuotationWorkflowAction({
    required this.action,
    required this.allowed,
    required this.nextState,
    required this.state,
  });
}
