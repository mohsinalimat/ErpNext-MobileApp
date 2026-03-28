import '../../domain/entities/quotation_details.dart';
import 'quotation_activity_model.dart';
import 'quotation_follow_up_model.dart';

class QuotationDetailsModel extends QuotationDetails {
  const QuotationDetailsModel({
    required super.name,
    required super.data,
    required super.printData,
    required super.followUps,
    required super.activityLog,
  });

  factory QuotationDetailsModel.fromJson(Map<String, dynamic> json) {
    final root = _extractRoot(json);
    final followUpsRaw = _extractList(root, const ['follow_ups']);
    final activityRaw = _extractList(root, const ['activity_log', 'activities', 'timeline']);

    return QuotationDetailsModel(
      name: root['name']?.toString() ?? root['id']?.toString() ?? '',
      data: _buildDisplayData(root),
      printData: _readMap(root['print']),
      followUps: followUpsRaw
          .whereType<Map<String, dynamic>>()
          .map(QuotationFollowUpModel.fromJson)
          .toList(),
      activityLog: activityRaw
          .whereType<Map<String, dynamic>>()
          .map(QuotationActivityModel.fromJson)
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

    _mergeFlatMap(data, _readMap(root['form_data']));
    _mergeFlatMap(data, _readMap(root['editable_fields']));
    _mergeFlatMap(data, _readMap(root['edit_data']));
    _mergeFlatMap(data, _readMap(root['values']));
    _mergeFlatMap(data, _readMap(root['doc']));

    final identity = _readMap(root['identity']);
    addValue('id', root['id']);
    addValue('display_name', identity['display_name']);
    addValue('party_name', identity['party_name']);
    addValue('customer_name', identity['customer_name']);
    addValue('title', identity['title']);

    final status = _readMap(root['status']);
    addValue('status', status['current'] ?? root['status']);
    addValue('workflow_state', status['workflow_state'] ?? root['workflow_state']);
    addValue(
      'quotation_from',
      status['quotation_from'] ??
          root['quotation_from'] ??
          status['opportunity_from'] ??
          root['opportunity_from'],
    );
    addValue('owner', status['owner'] ?? root['owner']);
    addValue('source', status['source'] ?? root['source']);
    addValue('sales_stage', status['sales_stage'] ?? root['sales_stage']);

    final valueMap = _readMap(root['value']);
    addValue('currency', valueMap['currency'] ?? root['currency']);
    addValue('quotation_amount', valueMap['quotation_amount'] ?? root['quotation_amount']);
    addValue('expected_closing', valueMap['expected_closing'] ?? root['expected_closing']);
    addValue('probability', valueMap['probability'] ?? root['probability']);

    final contact = _readMap(root['contact']);
    addValue('contact_person', contact['contact_person'] ?? root['contact_person']);
    addValue('email_id', contact['email'] ?? root['email_id']);
    addValue('mobile_no', contact['mobile'] ?? root['mobile_no']);
    addValue('whatsapp_no', contact['whatsapp'] ?? root['whatsapp_no']);
    addValue('phone', contact['phone'] ?? root['phone']);

    final address = _readMap(root['address']);
    addValue('city', address['city'] ?? root['city']);
    addValue('state', address['state'] ?? root['state']);
    addValue('country', address['country'] ?? root['country']);
    addValue('territory', address['territory'] ?? root['territory']);

    addValue('notes', root['notes']);

    final summary = _readMap(root['follow_up_summary']);
    addValue('last_update_date', root['last_update_date'] ?? summary['last_update_date']);
    addValue(
      'next_follow_up_date',
      root['next_follow_up_date'] ?? summary['next_follow_up_date'],
    );
    addValue(
      'last_follow_up_report',
      root['last_follow_up_report'] ?? summary['last_follow_up_report'],
    );

    final print = _readMap(root['print']);
    addValue('print_url', print['print_url'] ?? root['print_url']);
    addValue('pdf_url', print['pdf_url'] ?? root['pdf_url']);
    addValue(
      'default_print_format',
      print['default_print_format'] ?? root['default_print_format'],
    );

    for (final entry in root.entries) {
      if (entry.value is Map || entry.value is List) continue;
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
