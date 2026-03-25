import '../../domain/entities/lead_details.dart';
import 'lead_activity_model.dart';
import 'lead_follow_up_model.dart';

class LeadDetailsModel extends LeadDetails {
  const LeadDetailsModel({
    required super.name,
    required super.data,
    required super.followUps,
    required super.activityLog,
  });

  factory LeadDetailsModel.fromJson(Map<String, dynamic> json) {
    final root = _extractRoot(json);
    final followUpsRaw = _extractList(root, const [
      'follow_ups',
      'mobile_api_follow_ups',
      'lead_follow_ups',
    ]);
    final activityRaw = _extractList(root, const [
      'activity_log',
      'activities',
      'timeline',
    ]);
    final cleanedData = _buildDisplayData(root);

    return LeadDetailsModel(
      name: root['name']?.toString() ?? root['id']?.toString() ?? '',
      data: cleanedData,
      followUps: followUpsRaw
          .whereType<Map<String, dynamic>>()
          .map(LeadFollowUpModel.fromJson)
          .toList(),
      activityLog: activityRaw
          .whereType<Map<String, dynamic>>()
          .map(LeadActivityModel.fromJson)
          .toList(),
    );
  }

  static Map<String, dynamic> _extractRoot(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return json;
  }

  static List<dynamic> _extractList(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) return value;
    }
    return const [];
  }

  static Map<String, dynamic> _buildDisplayData(Map<String, dynamic> root) {
    final data = <String, dynamic>{};

    void addValue(String key, dynamic value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty || text == 'null') return;
      data[key] = value;
    }

    final identity = _readMap(root['identity']);
    _mergeFlatMap(data, _readMap(root['form_data']));
    _mergeFlatMap(data, _readMap(root['editable_fields']));
    _mergeFlatMap(data, _readMap(root['edit_data']));
    _mergeFlatMap(data, _readMap(root['values']));
    _mergeFlatMap(data, _readMap(root['doc']));
    addValue('id', root['id']);
    addValue('first_name', identity['first_name'] ?? root['first_name']);
    addValue('middle_name', identity['middle_name']);
    addValue('last_name', identity['last_name']);
    addValue('company_name', identity['company_name'] ?? root['company_name']);
    addValue('display_name', identity['display_name']);

    final status = _readMap(root['status']);
    addValue('status', status['current'] ?? root['status']);
    addValue('source', status['source'] ?? root['source']);
    addValue('owner', status['owner'] ?? root['owner']);

    final contact = _readMap(root['contact']);
    addValue('email_id', contact['email'] ?? root['email_id']);
    addValue('mobile_no', contact['mobile'] ?? root['mobile_no']);
    addValue('whatsapp_no', contact['whatsapp'] ?? root['whatsapp_no']);
    addValue('phone', contact['phone'] ?? root['phone']);

    final address = _readMap(root['address']);
    addValue('short_address', root['short_address']);
    addValue('city', address['city'] ?? root['city']);
    addValue('country', address['country'] ?? root['country']);
    addValue('territory', address['territory'] ?? root['territory']);

    final summary = _readMap(root['follow_up_summary']);
    addValue(
      'mobile_api_last_update_date',
      summary['last_update_date'] ?? root['mobile_api_last_update_date'],
    );
    addValue(
      'mobile_api_next_follow_up_date',
      summary['next_follow_up_date'] ?? root['mobile_api_next_follow_up_date'],
    );
    addValue(
      'mobile_api_last_follow_up_report',
      summary['last_follow_up_report'] ?? root['mobile_api_last_follow_up_report'],
    );

    for (final entry in root.entries) {
      if (entry.value is Map || entry.value is List) continue;
      if (const {
        'id',
        'doctype',
        'name',
        'lead_name',
        'first_name',
        'company_name',
        'status',
        'source',
        'owner',
        'email_id',
        'mobile_no',
        'whatsapp_no',
        'phone',
        'city',
        'country',
        'territory',
        'mobile_api_last_update_date',
        'mobile_api_next_follow_up_date',
        'mobile_api_last_follow_up_report',
      }.contains(entry.key)) {
        continue;
      }
      addValue(entry.key, entry.value);
    }

    return data;
  }

  static void _mergeFlatMap(
    Map<String, dynamic> target,
    Map<String, dynamic> source,
  ) {
    for (final entry in source.entries) {
      final value = entry.value;
      if (value is Map || value is List || value == null) continue;
      final text = value.toString().trim();
      if (text.isEmpty || text == 'null') continue;
      target[entry.key] = value;
    }
  }

  static Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return const <String, dynamic>{};
  }
}
