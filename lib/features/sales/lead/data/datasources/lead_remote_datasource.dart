import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/auth_session.dart';
import '../../../../../core/utils/app_logger.dart';
import '../models/lead_dashboard_summary_model.dart';
import '../models/lead_details_model.dart';
import '../models/lead_follow_up_model.dart';
import '../models/lead_model.dart';
import '../models/lead_option_item_model.dart';
import '../models/lead_required_fields_result_model.dart';

class LeadRemoteDataSource {
  Future<List<LeadModel>> getLeads({
    required int start,
    required int limit,
    String? status,
    String? search,
    String? followUpFilter,
    String? sortBy,
  }) async {
    final uri = ApiConstants.uri(ApiConstants.leadsEndpoint).replace(
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

    AppLogger.sales('load leads start=$start limit=$limit status=$status');
    final response = await http.get(uri, headers: AuthSession.authHeaders());
    AppLogger.sales(
      'load leads response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load leads: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final list = _extractList(decoded);

    return list
        .whereType<Map<String, dynamic>>()
        .map(LeadModel.fromJson)
        .toList();
  }

  Future<LeadDashboardSummaryModel> getDashboardSummary({
    String? status,
    String? search,
  }) async {
    final uri = ApiConstants.uri(
      ApiConstants.leadsDashboardSummaryEndpoint,
    ).replace(
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final response = await http.get(uri, headers: AuthSession.authHeaders());
    AppLogger.sales(
      'leads dashboard summary response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load leads dashboard summary: ${response.statusCode}',
      );
    }

    return LeadDashboardSummaryModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<LeadDetailsModel> getLeadDetails(String leadName) async {
    final uri = ApiConstants.uri(ApiConstants.leadDetailsEndpoint).replace(
      queryParameters: {'lead_name': leadName},
    );

    AppLogger.sales('lead details request lead_name=$leadName');
    var response = await http.get(uri, headers: AuthSession.authHeaders());
    AppLogger.sales(
      'lead details GET response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      response = await http.post(
        ApiConstants.uri(ApiConstants.leadDetailsEndpoint),
        headers: AuthSession.authHeaders(withJson: false),
        body: {'lead_name': leadName},
      );
      AppLogger.sales(
        'lead details POST response=${response.statusCode} body=${_preview(response.body)}',
      );
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load lead details: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final payload = _extractMap(decoded);
    return LeadDetailsModel.fromJson(payload);
  }

  Future<LeadRequiredFieldsResultModel> getRequiredFields(
    Map<String, dynamic> data,
  ) async {
    AppLogger.sales('lead required fields payload=${jsonEncode({'data': data})}');
    final response = await http.post(
      ApiConstants.uri(ApiConstants.leadRequiredFieldsEndpoint),
      headers: AuthSession.authHeaders(),
      body: jsonEncode({'data': data}),
    );
    AppLogger.sales(
      'lead required fields response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load lead required fields: ${response.statusCode}',
      );
    }

    return LeadRequiredFieldsResultModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<String> createLead(Map<String, dynamic> data) async {
    AppLogger.sales('create lead payload=${jsonEncode({'data': data})}');
    final response = await http.post(
      ApiConstants.uri(ApiConstants.createLeadEndpoint),
      headers: AuthSession.authHeaders(),
      body: jsonEncode({'data': data}),
    );
    AppLogger.sales(
      'create lead response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create lead: ${response.statusCode}');
    }

    final payload = _extractMap(jsonDecode(response.body));
    final createdName = payload['name']?.toString() ??
        payload['lead_name']?.toString() ??
        payload['message']?.toString() ??
        '';
    AppLogger.sales('create lead parsed result=$createdName payload=$payload');
    return createdName;
  }

  Future<void> updateLead(String leadName, Map<String, dynamic> data) async {
    AppLogger.sales(
      'update lead payload=${jsonEncode({'lead_name': leadName, 'data': data})}',
    );
    final response = await http.post(
      ApiConstants.uri(ApiConstants.updateLeadEndpoint),
      headers: AuthSession.authHeaders(),
      body: jsonEncode({'lead_name': leadName, 'data': data}),
    );
    AppLogger.sales(
      'update lead response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update lead: ${response.statusCode}');
    }
  }

  Future<void> addLeadFollowUp({
    required String leadName,
    required String followUpDate,
    required String expectedResultDate,
    required String details,
    String? attachment,
  }) async {
    final body = {
      'lead_name': leadName,
      'follow_up_date': followUpDate,
      'expected_result_date': expectedResultDate,
      'details': details,
      if (attachment != null && attachment.isNotEmpty) 'attachment': attachment,
    };
    AppLogger.sales('add lead follow up payload=${jsonEncode(body)}');

    final response = await http.post(
      ApiConstants.uri(ApiConstants.addLeadFollowUpEndpoint),
      headers: AuthSession.authHeaders(),
      body: jsonEncode(body),
    );
    AppLogger.sales(
      'add lead follow up response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add lead follow up: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final payload = decoded['message'] ?? decoded['data'] ?? decoded;
      if (payload is Map<String, dynamic>) {
        final status = payload['status']?.toString().toLowerCase();
        if (status == 'error') {
          throw Exception(
            payload['message']?.toString() ?? 'Add lead follow up failed',
          );
        }
      }
    }
  }

  Future<String> uploadAttachment({
    required String filePath,
    required String leadName,
  }) async {
    AppLogger.sales('lead upload attachment start path=$filePath lead=$leadName');

    final request = http.MultipartRequest(
      'POST',
      ApiConstants.uri('/api/method/upload_file'),
    );

    request.headers.addAll(AuthSession.authHeaders(withJson: false));
    request.fields['doctype'] = 'Lead';
    request.fields['docname'] = leadName;
    request.fields['is_private'] = '0';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    AppLogger.sales(
      'lead upload attachment response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload attachment: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid upload response format');
    }

    final payload = decoded['message'] ?? decoded['data'] ?? decoded;
    if (payload is! Map<String, dynamic>) {
      throw Exception('Invalid upload payload');
    }

    final fileUrl = payload['file_url']?.toString();
    if (fileUrl == null || fileUrl.isEmpty) {
      throw Exception('Upload succeeded but file_url missing');
    }

    AppLogger.sales('lead upload attachment success url=$fileUrl');
    return fileUrl;
  }

  Future<List<LeadFollowUpModel>> getLeadFollowUps(String leadName) async {
    final uri = ApiConstants.uri(ApiConstants.leadFollowUpsEndpoint).replace(
      queryParameters: {'lead_name': leadName},
    );

    final response = await http.get(uri, headers: AuthSession.authHeaders());

    if (response.statusCode != 200) {
      throw Exception('Failed to load lead follow ups: ${response.statusCode}');
    }

    final list = _extractList(jsonDecode(response.body));
    return list
        .whereType<Map<String, dynamic>>()
        .map(LeadFollowUpModel.fromJson)
        .toList();
  }

  Future<List<LeadOptionItemModel>> searchLinkOptions({
    required String doctype,
    String query = '',
  }) async {
    final uri = ApiConstants.uri(ApiConstants.searchLinkEndpoint).replace(
      queryParameters: {
        'doctype': doctype,
        'txt': query,
        'page_length': '20',
      },
    );

    final response = await http.get(uri, headers: AuthSession.authHeaders());
    AppLogger.sales(
      'search link doctype=$doctype query="$query" response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to search link options: ${response.statusCode}');
    }

    final list = _extractList(jsonDecode(response.body));
    return list.map(LeadOptionItemModel.fromDynamic).toList();
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is! Map<String, dynamic>) return const [];

    final directKeys = ['data', 'message', 'result', 'leads', 'follow_ups'];
    for (final key in directKeys) {
      final value = decoded[key];
      if (value is List) return value;
    }

    for (final key in directKeys) {
      final value = decoded[key];
      if (value is Map<String, dynamic>) {
        for (final nestedKey in ['items', 'results', 'data', 'leads', 'follow_ups']) {
          final nested = value[nestedKey];
          if (nested is List) return nested;
        }
      }
    }

    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        final nestedData = data['data'];
        if (nestedData is Map<String, dynamic>) return nestedData;
        return data;
      }

      final message = decoded['message'];
      if (message is Map<String, dynamic>) {
        final nestedData = message['data'];
        if (nestedData is Map<String, dynamic>) return nestedData;
        return message;
      }

      final result = decoded['result'];
      if (result is Map<String, dynamic>) {
        final nestedData = result['data'];
        if (nestedData is Map<String, dynamic>) return nestedData;
        return result;
      }

      return decoded;
    }

    return <String, dynamic>{};
  }

  String _preview(String body, {int max = 500}) {
    if (body.length <= max) return body;
    return '${body.substring(0, max)}...';
  }
}
