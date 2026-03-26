class OpportunityWorkflowAction {
  final String action;
  final String allowed;
  final String nextState;
  final String state;

  const OpportunityWorkflowAction({
    required this.action,
    required this.allowed,
    required this.nextState,
    required this.state,
  });
}
