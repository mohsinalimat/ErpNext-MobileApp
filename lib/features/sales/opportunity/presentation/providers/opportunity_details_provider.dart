import 'package:flutter/material.dart';

import '../../../../../core/utils/app_logger.dart';
import '../../domain/entities/opportunity_details.dart';
import '../../domain/entities/opportunity_workflow_info.dart';
import '../../domain/usecases/add_opportunity_follow_up_usecase.dart';
import '../../domain/usecases/execute_opportunity_workflow_action_usecase.dart';
import '../../domain/usecases/get_opportunity_details_usecase.dart';
import '../../domain/usecases/get_opportunity_workflow_actions_usecase.dart';
import '../../domain/usecases/upload_opportunity_attachment_usecase.dart';

class OpportunityDetailsProvider extends ChangeNotifier {
  OpportunityDetailsProvider(
    this._getOpportunityDetailsUseCase,
    this._addOpportunityFollowUpUseCase,
    this._getOpportunityWorkflowActionsUseCase,
    this._executeOpportunityWorkflowActionUseCase,
    this._uploadOpportunityAttachmentUseCase,
  );

  final GetOpportunityDetailsUseCase _getOpportunityDetailsUseCase;
  final AddOpportunityFollowUpUseCase _addOpportunityFollowUpUseCase;
  final GetOpportunityWorkflowActionsUseCase _getOpportunityWorkflowActionsUseCase;
  final ExecuteOpportunityWorkflowActionUseCase _executeOpportunityWorkflowActionUseCase;
  final UploadOpportunityAttachmentUseCase _uploadOpportunityAttachmentUseCase;

  bool _isLoading = false;
  bool _isWorkflowLoading = false;
  String? _error;
  OpportunityDetails? _details;
  OpportunityWorkflowInfo _workflow = const OpportunityWorkflowInfo.empty();

  bool get isLoading => _isLoading;
  bool get isWorkflowLoading => _isWorkflowLoading;
  String? get error => _error;
  OpportunityDetails? get details => _details;
  OpportunityWorkflowInfo get workflow => _workflow;

  Future<void> load(String opportunityName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _details = await _getOpportunityDetailsUseCase.call(opportunityName);
      _workflow = await _getOpportunityWorkflowActionsUseCase.call(opportunityName);
    } catch (e) {
      _error = e.toString();
      AppLogger.error('opportunity details failed: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFollowUp({
    required String opportunityName,
    required String followUpDate,
    required String expectedResultDate,
    required String details,
    String? attachment,
    String? attachmentPath,
  }) async {
    _error = null;

    try {
      AppLogger.sales(
        'opportunity follow up submit start opportunity=$opportunityName attachmentPath=$attachmentPath attachment=$attachment',
      );
      String? uploadedAttachment = attachment;
      if (attachmentPath != null && attachmentPath.isNotEmpty) {
        uploadedAttachment = await _uploadOpportunityAttachmentUseCase.call(
          filePath: attachmentPath,
          opportunityName: opportunityName,
        );
        AppLogger.sales(
          'opportunity follow up attachment uploaded url=$uploadedAttachment',
        );
      }

      await _addOpportunityFollowUpUseCase.call(
        opportunityName: opportunityName,
        followUpDate: followUpDate,
        expectedResultDate: expectedResultDate,
        details: details,
        attachment: uploadedAttachment,
      );
      AppLogger.sales('opportunity follow up API success opportunity=$opportunityName');
    } catch (e) {
      _error = e.toString();
      AppLogger.error('opportunity follow up failed: $_error');
      rethrow;
    }
  }

  Future<void> executeWorkflowAction({
    required String opportunityName,
    required String action,
  }) async {
    _error = null;
    _isWorkflowLoading = true;
    notifyListeners();

    try {
      _workflow = await _executeOpportunityWorkflowActionUseCase.call(
        opportunityName: opportunityName,
        action: action,
      );
      await load(opportunityName);
      AppLogger.sales(
        'opportunity workflow updated opportunity=$opportunityName action=$action',
      );
    } catch (e) {
      _error = e.toString();
      AppLogger.error('opportunity workflow update failed: $_error');
      rethrow;
    } finally {
      _isWorkflowLoading = false;
      notifyListeners();
    }
  }
}
