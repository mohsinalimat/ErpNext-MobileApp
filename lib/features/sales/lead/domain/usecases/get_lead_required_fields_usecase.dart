import '../entities/lead_required_fields_result.dart';
import '../repositories/lead_repository.dart';

class GetLeadRequiredFieldsUseCase {
  final LeadRepository repository;

  GetLeadRequiredFieldsUseCase(this.repository);

  Future<LeadRequiredFieldsResult> call(Map<String, dynamic> data) {
    return repository.getRequiredFields(data);
  }
}
