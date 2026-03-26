import '../entities/opportunity.dart';
import '../entities/opportunity_dashboard_summary.dart';
import '../entities/opportunity_details.dart';
import '../entities/opportunity_follow_up.dart';
import '../entities/opportunity_option_item.dart';
import '../entities/opportunity_required_fields_result.dart';
import '../entities/opportunity_workflow_info.dart';

abstract class OpportunityRepository {
  Future<OpportunityRequiredFieldsResult> getOpportunityForm({
    String? opportunityName,
  });
  Future<Map<String, String>> getPartyPrefill({
    required String partyType,
    required String partyName,
  });
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
  Future<OpportunityWorkflowInfo> getWorkflowActions(String opportunityName);
  Future<OpportunityWorkflowInfo> executeWorkflowAction({
    required String opportunityName,
    required String action,
  });
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
