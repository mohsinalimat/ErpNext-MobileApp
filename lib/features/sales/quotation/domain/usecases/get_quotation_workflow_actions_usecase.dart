import '../entities/quotation_workflow_info.dart';
import '../repositories/quotation_repository.dart';

class GetQuotationWorkflowActionsUseCase {
  final QuotationRepository repository;

  GetQuotationWorkflowActionsUseCase(this.repository);

  Future<QuotationWorkflowInfo> call(String quotationName) {
    return repository.getWorkflowActions(quotationName);
  }
}
