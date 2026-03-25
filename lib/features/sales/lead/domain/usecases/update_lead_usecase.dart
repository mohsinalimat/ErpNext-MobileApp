import '../repositories/lead_repository.dart';

class UpdateLeadUseCase {
  final LeadRepository repository;

  UpdateLeadUseCase(this.repository);

  Future<void> call(String leadName, Map<String, dynamic> data) {
    return repository.updateLead(leadName, data);
  }
}
