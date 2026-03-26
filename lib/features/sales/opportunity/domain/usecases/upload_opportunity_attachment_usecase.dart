import '../repositories/opportunity_repository.dart';

class UploadOpportunityAttachmentUseCase {
  final OpportunityRepository repository;

  UploadOpportunityAttachmentUseCase(this.repository);

  Future<String> call({
    required String filePath,
    required String opportunityName,
  }) {
    return repository.uploadAttachment(filePath: filePath, opportunityName: opportunityName);
  }
}
