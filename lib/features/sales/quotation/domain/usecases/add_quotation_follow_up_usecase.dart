import '../repositories/quotation_repository.dart';

class AddQuotationFollowUpUseCase {
  final QuotationRepository repository;

  AddQuotationFollowUpUseCase(this.repository);

  Future<void> call({
    required String quotationName,
    required String followUpDate,
    required String expectedResultDate,
    required String details,
    String? attachment,
  }) {
    return repository.addQuotationFollowUp(
      quotationName: quotationName,
      followUpDate: followUpDate,
      expectedResultDate: expectedResultDate,
      details: details,
      attachment: attachment,
    );
  }
}
