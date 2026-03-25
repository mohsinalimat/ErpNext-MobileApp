import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_dashboard_summary.dart';
import '../../domain/entities/lead_details.dart';
import '../../domain/entities/lead_follow_up.dart';
import '../../domain/entities/lead_option_item.dart';
import '../../domain/entities/lead_required_fields_result.dart';
import '../../domain/repositories/lead_repository.dart';
import '../datasources/lead_remote_datasource.dart';

class LeadRepositoryImpl implements LeadRepository {
  final LeadRemoteDataSource remoteDataSource;

  LeadRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> addLeadFollowUp({
    required String leadName,
    required String followUpDate,
    required String expectedResultDate,
    required String details,
    String? attachment,
  }) {
    return remoteDataSource.addLeadFollowUp(
      leadName: leadName,
      followUpDate: followUpDate,
      expectedResultDate: expectedResultDate,
      details: details,
      attachment: attachment,
    );
  }

  @override
  Future<String> createLead(Map<String, dynamic> data) {
    return remoteDataSource.createLead(data);
  }

  @override
  Future<LeadDetails> getLeadDetails(String leadName) {
    return remoteDataSource.getLeadDetails(leadName);
  }

  @override
  Future<List<LeadFollowUp>> getLeadFollowUps(String leadName) {
    return remoteDataSource.getLeadFollowUps(leadName);
  }

  @override
  Future<List<Lead>> getLeads({
    required int start,
    required int limit,
    String? status,
    String? search,
    String? followUpFilter,
    String? sortBy,
  }) {
    return remoteDataSource.getLeads(
      start: start,
      limit: limit,
      status: status,
      search: search,
      followUpFilter: followUpFilter,
      sortBy: sortBy,
    );
  }

  @override
  Future<LeadDashboardSummary> getDashboardSummary({
    String? status,
    String? search,
  }) {
    return remoteDataSource.getDashboardSummary(status: status, search: search);
  }

  @override
  Future<LeadRequiredFieldsResult> getRequiredFields(Map<String, dynamic> data) {
    return remoteDataSource.getRequiredFields(data);
  }

  @override
  Future<void> updateLead(String leadName, Map<String, dynamic> data) {
    return remoteDataSource.updateLead(leadName, data);
  }

  @override
  Future<List<LeadOptionItem>> searchLinkOptions({
    required String doctype,
    String query = '',
  }) {
    return remoteDataSource.searchLinkOptions(doctype: doctype, query: query);
  }

  @override
  Future<String> uploadAttachment({
    required String filePath,
    required String leadName,
  }) {
    return remoteDataSource.uploadAttachment(
      filePath: filePath,
      leadName: leadName,
    );
  }
}
