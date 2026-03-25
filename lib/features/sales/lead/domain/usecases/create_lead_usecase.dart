import '../repositories/lead_repository.dart';

class CreateLeadUseCase {
  final LeadRepository repository;

  CreateLeadUseCase(this.repository);

  Future<String> call(Map<String, dynamic> data) {
    return repository.createLead(data);
  }
}
