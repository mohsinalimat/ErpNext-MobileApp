import '../repositories/quotation_repository.dart';

class UploadQuotationAttachmentUseCase {
  final QuotationRepository repository;

  UploadQuotationAttachmentUseCase(this.repository);

  Future<String> call({
    required String filePath,
    required String quotationName,
  }) {
    return repository.uploadAttachment(filePath: filePath, quotationName: quotationName);
  }
}
