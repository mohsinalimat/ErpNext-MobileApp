import '../entities/lead_follow_up.dart';
import '../repositories/lead_repository.dart';

class GetLeadFollowUpsUseCase {
  final LeadRepository repository;

  GetLeadFollowUpsUseCase(this.repository);

  Future<List<LeadFollowUp>> call(String leadName) {
    return repository.getLeadFollowUps(leadName);
  }
}
