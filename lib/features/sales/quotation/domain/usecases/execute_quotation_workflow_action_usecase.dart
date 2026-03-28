import '../entities/quotation_workflow_info.dart';
import '../repositories/quotation_repository.dart';

class ExecuteQuotationWorkflowActionUseCase {
  final QuotationRepository repository;

  ExecuteQuotationWorkflowActionUseCase(this.repository);

  Future<QuotationWorkflowInfo> call({
    required String quotationName,
    required String action,
  }) {
    return repository.executeWorkflowAction(
      quotationName: quotationName,
      action: action,
    );
  }
}
