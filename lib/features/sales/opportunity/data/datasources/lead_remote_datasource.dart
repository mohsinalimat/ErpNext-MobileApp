import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/auth_session.dart';
import '../../../../../core/utils/app_logger.dart';
import '../models/opportunity_dashboard_summary_model.dart';
import '../models/opportunity_details_model.dart';
import '../models/opportunity_follow_up_model.dart';
import '../models/opportunity_model.dart';
import '../models/opportunity_option_item_model.dart';
import '../models/opportunity_required_fields_result_model.dart';

class OpportunityRemoteDataSource {
  Future<List<OpportunityModel>> getOpportunities({
    required int start,
    required int limit,
    String? status,
    String? search,
    String? followUpFilter,
    String? sortBy,
  }) async {
    final uri = ApiConstants.uri(ApiConstants.opportunitiesEndpoint).replace(
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

    AppLogger.sales('load opportunities start=$start limit=$limit status=$status');
    final response = await http.get(uri, headers: AuthSession.authHeaders());
    AppLogger.sales(
      'load opportunities response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load opportunities: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final list = _extractList(decoded);

    return list
        .whereType<Map<String, dynamic>>()
        .map(OpportunityModel.fromJson)
        .toList();
  }

  Future<OpportunityDashboardSummaryModel> getDashboardSummary({
    String? status,
    String? search,
  }) async {
    final uri = ApiConstants.uri(
      ApiConstants.opportunitiesDashboardSummaryEndpoint,
    ).replace(
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final response = await http.get(uri, headers: AuthSession.authHeaders());
    AppLogger.sales(
      'opportunities dashboard summary response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load opportunities dashboard summary: ${response.statusCode}',
      );
    }

    return OpportunityDashboardSummaryModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<OpportunityDetailsModel> getOpportunityDetails(String opportunityName) async {
    final uri = ApiConstants.uri(ApiConstants.opportunityDetailsEndpoint).replace(
      queryParameters: {'opportunity_name': opportunityName},
    );

    AppLogger.sales('opportunity details request opportunity_name=$opportunityName');
    var response = await http.get(uri, headers: AuthSession.authHeaders());
    AppLogger.sales(
      'opportunity details GET response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      response = await http.post(
        ApiConstants.uri(ApiConstants.opportunityDetailsEndpoint),
        headers: AuthSession.authHeaders(withJson: false),
        body: {'opportunity_name': opportunityName},
      );
      AppLogger.sales(
        'opportunity details POST response=${response.statusCode} body=${_preview(response.body)}',
      );
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load opportunity details: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final payload = _extractMap(decoded);
    return OpportunityDetailsModel.fromJson(payload);
  }

  Future<OpportunityRequiredFieldsResultModel> getRequiredFields(
    Map<String, dynamic> data,
  ) async {
    AppLogger.sales('opportunity required fields payload=${jsonEncode({'data': data})}');
    final response = await http.post(
      ApiConstants.uri(ApiConstants.opportunityRequiredFieldsEndpoint),
      headers: AuthSession.authHeaders(),
      body: jsonEncode({'data': data}),
    );
    AppLogger.sales(
      'opportunity required fields response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load opportunity required fields: ${response.statusCode}',
      );
    }

    return OpportunityRequiredFieldsResultModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<String> createOpportunity(Map<String, dynamic> data) async {
    AppLogger.sales('create opportunity payload=${jsonEncode({'data': data})}');
    final response = await http.post(
      ApiConstants.uri(ApiConstants.createOpportunityEndpoint),
      headers: AuthSession.authHeaders(),
      body: jsonEncode({'data': data}),
    );
    AppLogger.sales(
      'create opportunity response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create opportunity: ${response.statusCode}');
    }

    final payload = _extractMap(jsonDecode(response.body));
    final createdName = payload['name']?.toString() ??
        payload['opportunity_name']?.toString() ??
        payload['message']?.toString() ??
        '';
    AppLogger.sales('create opportunity parsed result=$createdName payload=$payload');
    return createdName;
  }

  Future<void> updateOpportunity(String opportunityName, Map<String, dynamic> data) async {
    AppLogger.sales(
      'update opportunity payload=${jsonEncode({'opportunity_name': opportunityName, 'data': data})}',
    );
    final response = await http.post(
      ApiConstants.uri(ApiConstants.updateOpportunityEndpoint),
      headers: AuthSession.authHeaders(),
      body: jsonEncode({'opportunity_name': opportunityName, 'data': data}),
    );
    AppLogger.sales(
      'update opportunity response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update opportunity: ${response.statusCode}');
    }
  }

  Future<void> addOpportunityFollowUp({
    required String opportunityName,
    required String followUpDate,
    required String expectedResultDate,
    required String details,
    String? attachment,
  }) async {
    final body = {
      'opportunity_name': opportunityName,
      'follow_up_date': followUpDate,
      'expected_result_date': expectedResultDate,
      'details': details,
      if (attachment != null && attachment.isNotEmpty) 'attachment': attachment,
    };
    AppLogger.sales('add opportunity follow up payload=${jsonEncode(body)}');

    final response = await http.post(
      ApiConstants.uri(ApiConstants.addOpportunityFollowUpEndpoint),
      headers: AuthSession.authHeaders(),
      body: jsonEncode(body),
    );
    AppLogger.sales(
      'add opportunity follow up response=${response.statusCode} body=${_preview(response.body)}',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add opportunity follow up: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final payload = decoded['message'] ?? decoded['data'] ?? decoded;
      if (payload is Map<String, dynamic>) {
        final status = payload['status']?.toString().toLowerCase();
        if (status == 'error') {
          throw Exception(
            payload['message']?.toString() ?? 'Add opportunity follow up failed',
          );
        }
      }
    }
  }

  Future<String> uploadAttachment({
    required String filePath,
    required String opportunityName,
  }) async {
    AppLogger.sales('opportunity upload attachment start path=$filePath opportunity=$opportunityName');

    final request = http.MultipartRequest(
      'POST',
      ApiConstants.uri('/api/method/upload_file'),
    );

    request.headers.addAll(AuthSession.authHeaders(withJson: false));
    request.fields['doctype'] = 'Opportunity';
    request.fields['docname'] = opportunityName;
    request.fields['is_private'] = '0';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    AppLogger.sales(
      'opportunity upload attachment response=${response.statusCode} body=${_preview(response.body)}',
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

    AppLogger.sales('opportunity upload attachment success url=$fileUrl');
    return fileUrl;
  }

  Future<List<OpportunityFollowUpModel>> getOpportunityFollowUps(String opportunityName) async {
    final uri = ApiConstants.uri(ApiConstants.opportunityFollowUpsEndpoint).replace(
      queryParameters: {'opportunity_name': opportunityName},
    );

    final response = await http.get(uri, headers: AuthSession.authHeaders());

    if (response.statusCode != 200) {
      throw Exception('Failed to load opportunity follow ups: ${response.statusCode}');
    }

    final list = _extractList(jsonDecode(response.body));
    return list
        .whereType<Map<String, dynamic>>()
        .map(OpportunityFollowUpModel.fromJson)
        .toList();
  }

  Future<List<OpportunityOptionItemModel>> searchLinkOptions({
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
    return list.map(OpportunityOptionItemModel.fromDynamic).toList();
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is! Map<String, dynamic>) return const [];

    final directKeys = ['data', 'message', 'result', 'opportunities', 'follow_ups'];
    for (final key in directKeys) {
      final value = decoded[key];
      if (value is List) return value;
    }

    for (final key in directKeys) {
      final value = decoded[key];
      if (value is Map<String, dynamic>) {
        for (final nestedKey in ['items', 'results', 'data', 'opportunities', 'follow_ups']) {
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
