import 'package:flutter/material.dart';

import '../../../../../core/utils/app_logger.dart';
import '../../domain/entities/lead_details.dart';
import '../../domain/usecases/add_lead_follow_up_usecase.dart';
import '../../domain/usecases/get_lead_details_usecase.dart';
import '../../domain/usecases/upload_lead_attachment_usecase.dart';

class LeadDetailsProvider extends ChangeNotifier {
  LeadDetailsProvider(
    this._getLeadDetailsUseCase,
    this._addLeadFollowUpUseCase,
    this._uploadLeadAttachmentUseCase,
  );

  final GetLeadDetailsUseCase _getLeadDetailsUseCase;
  final AddLeadFollowUpUseCase _addLeadFollowUpUseCase;
  final UploadLeadAttachmentUseCase _uploadLeadAttachmentUseCase;

  bool _isLoading = false;
  String? _error;
  LeadDetails? _details;

  bool get isLoading => _isLoading;
  String? get error => _error;
  LeadDetails? get details => _details;

  Future<void> load(String leadName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _details = await _getLeadDetailsUseCase.call(leadName);
    } catch (e) {
      _error = e.toString();
      AppLogger.error('lead details failed: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFollowUp({
    required String leadName,
    required String followUpDate,
    required String expectedResultDate,
    required String details,
    String? attachment,
    String? attachmentPath,
  }) async {
    _error = null;

    try {
      AppLogger.sales(
        'lead follow up submit start lead=$leadName attachmentPath=$attachmentPath attachment=$attachment',
      );
      String? uploadedAttachment = attachment;
      if (attachmentPath != null && attachmentPath.isNotEmpty) {
        uploadedAttachment = await _uploadLeadAttachmentUseCase.call(
          filePath: attachmentPath,
          leadName: leadName,
        );
        AppLogger.sales(
          'lead follow up attachment uploaded url=$uploadedAttachment',
        );
      }

      await _addLeadFollowUpUseCase.call(
        leadName: leadName,
        followUpDate: followUpDate,
        expectedResultDate: expectedResultDate,
        details: details,
        attachment: uploadedAttachment,
      );
      AppLogger.sales('lead follow up API success lead=$leadName');
    } catch (e) {
      _error = e.toString();
      AppLogger.error('lead follow up failed: $_error');
      rethrow;
    }
  }
}
