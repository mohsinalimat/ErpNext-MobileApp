import '../entities/quotation_follow_up.dart';
import '../repositories/quotation_repository.dart';

class GetQuotationFollowUpsUseCase {
  final QuotationRepository repository;

  GetQuotationFollowUpsUseCase(this.repository);

  Future<List<QuotationFollowUp>> call(String quotationName) {
    return repository.getQuotationFollowUps(quotationName);
  }
}
