import '../entities/lead.dart';
import '../entities/lead_dashboard_summary.dart';
import '../entities/lead_details.dart';
import '../entities/lead_follow_up.dart';
import '../entities/lead_option_item.dart';
import '../entities/lead_required_fields_result.dart';

abstract class LeadRepository {
  Future<List<Lead>> getLeads({
    required int start,
    required int limit,
    String? status,
    String? search,
    String? followUpFilter,
    String? sortBy,
  });
  Future<LeadDashboardSummary> getDashboardSummary({
    String? status,
    String? search,
  });

  Future<LeadDetails> getLeadDetails(String leadName);
  Future<LeadRequiredFieldsResult> getRequiredFields(Map<String, dynamic> data);
  Future<String> createLead(Map<String, dynamic> data);
  Future<void> updateLead(String leadName, Map<String, dynamic> data);
  Future<void> addLeadFollowUp({
    required String leadName,
    required String followUpDate,
    required String expectedResultDate,
    required String details,
    String? attachment,
  });
  Future<List<LeadFollowUp>> getLeadFollowUps(String leadName);
  Future<List<LeadOptionItem>> searchLinkOptions({
    required String doctype,
    String query = '',
  });
  Future<String> uploadAttachment({
    required String filePath,
    required String leadName,
  });
}
