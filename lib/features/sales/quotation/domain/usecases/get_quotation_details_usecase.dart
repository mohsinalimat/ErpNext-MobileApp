import '../entities/quotation_details.dart';
import '../repositories/quotation_repository.dart';

class GetQuotationDetailsUseCase {
  final QuotationRepository repository;

  GetQuotationDetailsUseCase(this.repository);

  Future<QuotationDetails> call(String quotationName) {
    return repository.getQuotationDetails(quotationName);
  }
}
