import '../repositories/lead_repository.dart';

class UploadLeadAttachmentUseCase {
  final LeadRepository repository;

  UploadLeadAttachmentUseCase(this.repository);

  Future<String> call({
    required String filePath,
    required String leadName,
  }) {
    return repository.uploadAttachment(filePath: filePath, leadName: leadName);
  }
}
