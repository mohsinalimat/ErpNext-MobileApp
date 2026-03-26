import '../entities/opportunity.dart';
import '../entities/opportunity_dashboard_summary.dart';
import '../entities/opportunity_details.dart';
import '../entities/opportunity_follow_up.dart';
import '../entities/opportunity_option_item.dart';
import '../entities/opportunity_required_fields_result.dart';

abstract class OpportunityRepository {
  Future<List<Opportunity>> getOpportunities({
    required int start,
    required int limit,
    String? status,
    String? search,
    String? followUpFilter,
    String? sortBy,
  });
  Future<OpportunityDashboardSummary> getDashboardSummary({
    String? status,
    String? search,
  });

  Future<OpportunityDetails> getOpportunityDetails(String opportunityName);
  Future<OpportunityRequiredFieldsResult> getRequiredFields(Map<String, dynamic> data);
  Future<String> createOpportunity(Map<String, dynamic> data);
  Future<void> updateOpportunity(String opportunityName, Map<String, dynamic> data);
  Future<void> addOpportunityFollowUp({
    required String opportunityName,
    required String followUpDate,
    required String expectedResultDate,
    required String details,
    String? attachment,
  });
  Future<List<OpportunityFollowUp>> getOpportunityFollowUps(String opportunityName);
  Future<List<OpportunityOptionItem>> searchLinkOptions({
    required String doctype,
    String query = '',
  });
  Future<String> uploadAttachment({
    required String filePath,
    required String opportunityName,
  });
}
