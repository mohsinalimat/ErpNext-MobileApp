import '../repositories/quotation_repository.dart';

class GetQuotationPrintDataUseCase {
  final QuotationRepository repository;

  GetQuotationPrintDataUseCase(this.repository);

  Future<Map<String, dynamic>> call({
    required String quotationName,
    String? printFormat,
  }) {
    return repository.getQuotationPrintData(
      quotationName: quotationName,
      printFormat: printFormat,
    );
  }
}
