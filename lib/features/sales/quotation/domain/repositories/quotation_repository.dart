import '../entities/quotation.dart';
import '../entities/quotation_dashboard_summary.dart';
import '../entities/quotation_details.dart';
import '../entities/quotation_follow_up.dart';
import '../entities/quotation_workflow_info.dart';

abstract class QuotationRepository {
  Future<List<Quotation>> getQuotations({
    required int start,
    required int limit,
    String? status,
    String? search,
    String? followUpFilter,
    String? sortBy,
  });
  Future<QuotationDashboardSummary> getDashboardSummary({
    String? status,
    String? search,
  });

  Future<QuotationDetails> getQuotationDetails(String quotationName);
  Future<Map<String, dynamic>> getQuotationPrintData({
    required String quotationName,
    String? printFormat,
  });
  Future<QuotationWorkflowInfo> getWorkflowActions(String quotationName);
  Future<QuotationWorkflowInfo> executeWorkflowAction({
    required String quotationName,
    required String action,
  });
  Future<void> addQuotationFollowUp({
    required String quotationName,
    required String followUpDate,
    required String expectedResultDate,
    required String details,
    String? attachment,
  });
  Future<List<QuotationFollowUp>> getQuotationFollowUps(String quotationName);
  Future<String> uploadAttachment({
    required String filePath,
    required String quotationName,
  });
}
