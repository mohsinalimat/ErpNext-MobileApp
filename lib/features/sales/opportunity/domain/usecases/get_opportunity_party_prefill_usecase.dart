import '../repositories/opportunity_repository.dart';

class GetOpportunityPartyPrefillUseCase {
  final OpportunityRepository repository;

  GetOpportunityPartyPrefillUseCase(this.repository);

  Future<Map<String, String>> call({
    required String partyType,
    required String partyName,
  }) {
    return repository.getPartyPrefill(
      partyType: partyType,
      partyName: partyName,
    );
  }
}
