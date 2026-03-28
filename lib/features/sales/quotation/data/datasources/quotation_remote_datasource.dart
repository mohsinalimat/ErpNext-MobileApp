import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/auth_session.dart';
import '../../../../../core/utils/app_logger.dart';
import '../models/quotation_dashboard_summary_model.dart';
import '../models/quotation_details_model.dart';
import '../models/quotation_follow_up_model.dart';
import '../models/quotation_model.dart';
import '../models/quotation_workflow_info_model.dart';

class QuotationRemoteDataSource {
  Future<List<QuotationModel>> getQuotations({
    required int start,
    required int limit,
    String? status,
    String? search,
    String? followUpFilter,
    String? sortBy,
  }) async {
    final uri = ApiConstants.uri(ApiConstants.quotationsEndpoint).replace(
      queryParameters: {
        'limit_start': '$start',
        'limit_page_length': '$limit',
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
        if (followUpFilter != null && followUpFilter.isNotEmpty)
          'follow_up_filter': followUpFilter,
        if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
      },
    );

    AppLogger.sales(
      'load quotations start=$start limit=$limit status=$status '
      'followUpFilter=$followUpFilter sortBy=$sortBy',
    );
    final response = await http.get(uri, headers: AuthSession.authHeaders());
    AppLogger.sales(
      'load quotations response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractApiError(
          response.body,
          fallback: 'Quotation list API is not available on the server.',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    _throwIfApiPayloadError(
      decoded,
      fallback: 'Quotation list API returned an error.',
    );

    final list = _extractList(decoded);
    return list
        .whereType<Map<String, dynamic>>()
        .map(QuotationModel.fromJson)
        .toList();
  }

  Future<QuotationDashboardSummaryModel> getDashboardSummary({
    String? status,
    String? search,
  }) async {
    final uri = ApiConstants.uri(
      ApiConstants.quotationsDashboardSummaryEndpoint,
    ).replace(
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final response = await http.get(uri, headers: AuthSession.authHeaders());
    AppLogger.sales(
      'quotations dashboard summary response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractApiError(
          response.body,
          fallback: 'Quotation dashboard summary API is not available on the server.',
        ),
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    _throwIfApiPayloadError(
      decoded,
      fallback: 'Quotation dashboard summary API returned an error.',
    );
    return QuotationDashboardSummaryModel.fromJson(decoded);
  }

  Future<QuotationDetailsModel> getQuotationDetails(String quotationName) async {
    final uri = ApiConstants.uri(ApiConstants.quotationDetailsEndpoint).replace(
      queryParameters: {'quotation_name': quotationName},
    );

    AppLogger.sales('quotation details request quotation_name=$quotationName');
    final response = await http.get(uri, headers: AuthSession.authHeaders());
    AppLogger.sales(
      'quotation details response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractApiError(
          response.body,
          fallback: 'Quotation details API is not available on the server.',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    _throwIfApiPayloadError(
      decoded,
      fallback: 'Quotation details API returned an error.',
    );
    return QuotationDetailsModel.fromJson(_extractMap(decoded));
  }

  Future<Map<String, dynamic>> getQuotationPrintData({
    required String quotationName,
    String? printFormat,
  }) async {
    final uri = ApiConstants.uri(ApiConstants.quotationPrintDataEndpoint)
        .replace(
          queryParameters: {
            'quotation_name': quotationName,
            if (printFormat != null && printFormat.isNotEmpty)
              'print_format': printFormat,
          },
        );

    final response = await http.get(uri, headers: AuthSession.authHeaders());
    AppLogger.sales(
      'quotation print data response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractApiError(
          response.body,
          fallback: 'Quotation print API is not available on the server.',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    _throwIfApiPayloadError(
      decoded,
      fallback: 'Quotation print API returned an error.',
    );
    return _extractMap(decoded);
  }

  Future<QuotationWorkflowInfoModel> getWorkflowActions(
    String quotationName,
  ) async {
    final uri = ApiConstants.uri(
      ApiConstants.quotationWorkflowActionsEndpoint,
    ).replace(queryParameters: {'quotation_name': quotationName});

    final response = await http.get(uri, headers: AuthSession.authHeaders());
    AppLogger.sales(
      'quotation workflow actions response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractApiError(
          response.body,
          fallback: 'Quotation workflow actions API is not available on the server.',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    _throwIfApiPayloadError(
      decoded,
      fallback: 'Quotation workflow actions API returned an error.',
    );
    return QuotationWorkflowInfoModel.fromJson(decoded as Map<String, dynamic>);
  }

  Future<QuotationWorkflowInfoModel> executeWorkflowAction({
    required String quotationName,
    required String action,
  }) async {
    final response = await http.post(
      ApiConstants.uri(ApiConstants.executeQuotationWorkflowActionEndpoint),
      headers: AuthSession.authHeaders(),
      body: jsonEncode({
        'quotation_name': quotationName,
        'action': action,
      }),
    );
    AppLogger.sales(
      'execute quotation workflow response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractApiError(
          response.body,
          fallback: 'Execute quotation workflow API is not available on the server.',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    _throwIfApiPayloadError(
      decoded,
      fallback: 'Execute quotation workflow API returned an error.',
    );
    return QuotationWorkflowInfoModel.fromJson(decoded as Map<String, dynamic>);
  }

  Future<void> addQuotationFollowUp({
    required String quotationName,
    required String followUpDate,
    required String expectedResultDate,
    required String details,
    String? attachment,
  }) async {
    final body = {
      'quotation_name': quotationName,
      'follow_up_date': followUpDate,
      'expected_result_date': expectedResultDate,
      'details': details,
      if (attachment != null && attachment.isNotEmpty) 'attachment': attachment,
    };
    AppLogger.sales('add quotation follow up payload=${jsonEncode(body)}');

    final response = await http.post(
      ApiConstants.uri(ApiConstants.addQuotationFollowUpEndpoint),
      headers: AuthSession.authHeaders(),
      body: jsonEncode(body),
    );
    AppLogger.sales(
      'add quotation follow up response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractApiError(
          response.body,
          fallback: 'Quotation follow up API is not available on the server.',
        ),
      );
    }

    _throwIfApiPayloadError(
      jsonDecode(response.body),
      fallback: 'Quotation follow up API returned an error.',
    );
  }

  Future<String> uploadAttachment({
    required String filePath,
    required String quotationName,
  }) async {
    AppLogger.sales(
      'quotation upload attachment start path=$filePath quotation=$quotationName',
    );

    final request = http.MultipartRequest(
      'POST',
      ApiConstants.uri('/api/method/upload_file'),
    );
    request.headers.addAll(AuthSession.authHeaders(withJson: false));
    request.fields['doctype'] = 'Quotation';
    request.fields['docname'] = quotationName;
    request.fields['is_private'] = '0';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    AppLogger.sales(
      'quotation upload attachment response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload attachment: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final payload = _extractMap(decoded);
    final fileUrl = payload['file_url']?.toString() ?? '';
    if (fileUrl.isEmpty) {
      throw Exception('Upload succeeded but file_url missing');
    }
    AppLogger.sales('quotation upload attachment success url=$fileUrl');
    return fileUrl;
  }

  Future<List<QuotationFollowUpModel>> getQuotationFollowUps(
    String quotationName,
  ) async {
    final uri = ApiConstants.uri(ApiConstants.quotationFollowUpsEndpoint)
        .replace(queryParameters: {'quotation_name': quotationName});

    final response = await http.get(uri, headers: AuthSession.authHeaders());
    AppLogger.sales(
      'quotation follow ups response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractApiError(
          response.body,
          fallback: 'Quotation follow ups API is not available on the server.',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    _throwIfApiPayloadError(
      decoded,
      fallback: 'Quotation follow ups API returned an error.',
    );
    final list = _extractList(decoded);
    return list
        .whereType<Map<String, dynamic>>()
        .map(QuotationFollowUpModel.fromJson)
        .toList();
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is! Map<String, dynamic>) return const [];

    for (final key in ['data', 'message', 'result', 'follow_ups']) {
      final value = decoded[key];
      if (value is List) return value;
      if (value is Map<String, dynamic>) {
        for (final nestedKey in ['data', 'items', 'results', 'follow_ups']) {
          final nested = value[nestedKey];
          if (nested is List) return nested;
        }
      }
    }
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) return <String, dynamic>{};

    final message = decoded['message'];
    if (message is Map<String, dynamic>) {
      final nested = message['data'];
      if (nested is Map<String, dynamic>) return nested;
      return message;
    }

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }

    return decoded;
  }

  void _throwIfApiPayloadError(dynamic decoded, {required String fallback}) {
    if (decoded is! Map<String, dynamic>) return;

    final candidates = [
      decoded,
      if (decoded['message'] is Map<String, dynamic>) decoded['message'],
      if (decoded['data'] is Map<String, dynamic>) decoded['data'],
    ];

    for (final candidate in candidates) {
      if (candidate is! Map<String, dynamic>) continue;
      final status = candidate['status']?.toString().toLowerCase();
      if (status == 'error') {
        throw Exception(candidate['message']?.toString() ?? fallback);
      }
    }
  }

  String _extractApiError(String body, {required String fallback}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final exception = decoded['exception']?.toString() ?? '';
        final message = decoded['message']?.toString() ?? '';
        final combined = '$exception $message'.trim().toLowerCase();
        if (combined.contains('has no attribute')) {
          return fallback;
        }
        if (message.isNotEmpty) return message;
        if (exception.isNotEmpty) return exception;
      }
    } catch (_) {
      // Ignore parse failure and return fallback.
    }
    return fallback;
  }

  String _preview(String body, {int max = 500}) {
    if (body.length <= max) return body;
    return '${body.substring(0, max)}...';
  }
}
