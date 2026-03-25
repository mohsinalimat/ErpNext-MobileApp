import '../entities/lead_details.dart';
import '../repositories/lead_repository.dart';

class GetLeadDetailsUseCase {
  final LeadRepository repository;

  GetLeadDetailsUseCase(this.repository);

  Future<LeadDetails> call(String leadName) {
    return repository.getLeadDetails(leadName);
  }
}
