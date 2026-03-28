import '../../domain/entities/quotation.dart';
import '../../domain/entities/quotation_dashboard_summary.dart';
import '../../domain/entities/quotation_details.dart';
import '../../domain/entities/quotation_follow_up.dart';
import '../../domain/entities/quotation_workflow_info.dart';
import '../../domain/repositories/quotation_repository.dart';
import '../datasources/quotation_remote_datasource.dart';

class QuotationRepositoryImpl implements QuotationRepository {
  final QuotationRemoteDataSource remoteDataSource;

  QuotationRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> addQuotationFollowUp({
    required String quotationName,
    required String followUpDate,
    required String expectedResultDate,
    required String details,
    String? attachment,
  }) {
    return remoteDataSource.addQuotationFollowUp(
      quotationName: quotationName,
      followUpDate: followUpDate,
      expectedResultDate: expectedResultDate,
      details: details,
      attachment: attachment,
    );
  }

  @override
  Future<QuotationDetails> getQuotationDetails(String quotationName) {
    return remoteDataSource.getQuotationDetails(quotationName);
  }

  @override
  Future<Map<String, dynamic>> getQuotationPrintData({
    required String quotationName,
    String? printFormat,
  }) {
    return remoteDataSource.getQuotationPrintData(
      quotationName: quotationName,
      printFormat: printFormat,
    );
  }

  @override
  Future<List<QuotationFollowUp>> getQuotationFollowUps(String quotationName) {
    return remoteDataSource.getQuotationFollowUps(quotationName);
  }

  @override
  Future<List<Quotation>> getQuotations({
    required int start,
    required int limit,
    String? status,
    String? search,
    String? followUpFilter,
    String? sortBy,
  }) {
    return remoteDataSource.getQuotations(
      start: start,
      limit: limit,
      status: status,
      search: search,
      followUpFilter: followUpFilter,
      sortBy: sortBy,
    );
  }

  @override
  Future<QuotationDashboardSummary> getDashboardSummary({
    String? status,
    String? search,
  }) {
    return remoteDataSource.getDashboardSummary(status: status, search: search);
  }

  @override
  Future<QuotationWorkflowInfo> getWorkflowActions(String quotationName) {
    return remoteDataSource.getWorkflowActions(quotationName);
  }

  @override
  Future<QuotationWorkflowInfo> executeWorkflowAction({
    required String quotationName,
    required String action,
  }) {
    return remoteDataSource.executeWorkflowAction(
      quotationName: quotationName,
      action: action,
    );
  }

  @override
  Future<String> uploadAttachment({
    required String filePath,
    required String quotationName,
  }) {
    return remoteDataSource.uploadAttachment(
      filePath: filePath,
      quotationName: quotationName,
    );
  }
}
