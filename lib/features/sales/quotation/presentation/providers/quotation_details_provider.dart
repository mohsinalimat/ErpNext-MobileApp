import 'package:flutter/material.dart';

import '../../../../../core/utils/app_logger.dart';
import '../../domain/entities/quotation_details.dart';
import '../../domain/entities/quotation_workflow_info.dart';
import '../../domain/usecases/add_quotation_follow_up_usecase.dart';
import '../../domain/usecases/execute_quotation_workflow_action_usecase.dart';
import '../../domain/usecases/get_quotation_details_usecase.dart';
import '../../domain/usecases/get_quotation_print_data_usecase.dart';
import '../../domain/usecases/get_quotation_workflow_actions_usecase.dart';
import '../../domain/usecases/upload_quotation_attachment_usecase.dart';

class QuotationDetailsProvider extends ChangeNotifier {
  QuotationDetailsProvider(
    this._getQuotationDetailsUseCase,
    this._addQuotationFollowUpUseCase,
    this._getQuotationWorkflowActionsUseCase,
    this._executeQuotationWorkflowActionUseCase,
    this._uploadQuotationAttachmentUseCase,
    this._getQuotationPrintDataUseCase,
  );

  final GetQuotationDetailsUseCase _getQuotationDetailsUseCase;
  final AddQuotationFollowUpUseCase _addQuotationFollowUpUseCase;
  final GetQuotationWorkflowActionsUseCase _getQuotationWorkflowActionsUseCase;
  final ExecuteQuotationWorkflowActionUseCase _executeQuotationWorkflowActionUseCase;
  final UploadQuotationAttachmentUseCase _uploadQuotationAttachmentUseCase;
  final GetQuotationPrintDataUseCase _getQuotationPrintDataUseCase;

  bool _isLoading = false;
  bool _isWorkflowLoading = false;
  String? _error;
  QuotationDetails? _details;
  QuotationWorkflowInfo _workflow = const QuotationWorkflowInfo.empty();
  Map<String, dynamic> _printData = const {};

  bool get isLoading => _isLoading;
  bool get isWorkflowLoading => _isWorkflowLoading;
  String? get error => _error;
  QuotationDetails? get details => _details;
  QuotationWorkflowInfo get workflow => _workflow;
  Map<String, dynamic> get printData => _printData;

  Future<void> load(String quotationName) async {
    _isLoading = true;
    _error = null;
    _workflow = const QuotationWorkflowInfo.empty();
    _printData = const {};
    notifyListeners();

    try {
      _details = await _getQuotationDetailsUseCase.call(quotationName);
      _printData = _details?.printData ?? const {};

      try {
        _workflow = await _getQuotationWorkflowActionsUseCase.call(quotationName);
      } catch (e) {
        AppLogger.error('quotation workflow load failed: $e');
      }

      try {
        final remotePrint = await _getQuotationPrintDataUseCase.call(
          quotationName: quotationName,
        );
        if (remotePrint.isNotEmpty) {
          _printData = remotePrint;
        }
      } catch (e) {
        AppLogger.error('quotation print data failed: $e');
      }
    } catch (e) {
      _error = e.toString();
      AppLogger.error('quotation details failed: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPrintData({
    required String quotationName,
    String? printFormat,
  }) async {
    _error = null;
    try {
      final remotePrint = await _getQuotationPrintDataUseCase.call(
        quotationName: quotationName,
        printFormat: printFormat,
      );
      _printData = remotePrint;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      AppLogger.error('quotation print refresh failed: $_error');
      rethrow;
    }
  }

  Future<void> addFollowUp({
    required String quotationName,
    required String followUpDate,
    required String expectedResultDate,
    required String details,
    String? attachment,
    String? attachmentPath,
  }) async {
    _error = null;

    try {
      AppLogger.sales(
        'quotation follow up submit start quotation=$quotationName attachmentPath=$attachmentPath attachment=$attachment',
      );
      String? uploadedAttachment = attachment;
      if (attachmentPath != null && attachmentPath.isNotEmpty) {
        uploadedAttachment = await _uploadQuotationAttachmentUseCase.call(
          filePath: attachmentPath,
          quotationName: quotationName,
        );
        AppLogger.sales(
          'quotation follow up attachment uploaded url=$uploadedAttachment',
        );
      }

      await _addQuotationFollowUpUseCase.call(
        quotationName: quotationName,
        followUpDate: followUpDate,
        expectedResultDate: expectedResultDate,
        details: details,
        attachment: uploadedAttachment,
      );
      AppLogger.sales('quotation follow up API success quotation=$quotationName');
    } catch (e) {
      _error = e.toString();
      AppLogger.error('quotation follow up failed: $_error');
      rethrow;
    }
  }

  Future<void> executeWorkflowAction({
    required String quotationName,
    required String action,
  }) async {
    _error = null;
    _isWorkflowLoading = true;
    notifyListeners();

    try {
      _workflow = await _executeQuotationWorkflowActionUseCase.call(
        quotationName: quotationName,
        action: action,
      );
      await load(quotationName);
      AppLogger.sales(
        'quotation workflow updated quotation=$quotationName action=$action',
      );
    } catch (e) {
      _error = e.toString();
      AppLogger.error('quotation workflow update failed: $_error');
      rethrow;
    } finally {
      _isWorkflowLoading = false;
      notifyListeners();
    }
  }
}
