import '../../domain/entities/quotation_follow_up.dart';

class QuotationFollowUpModel extends QuotationFollowUp {
  const QuotationFollowUpModel({
    required super.name,
    required super.followUpDate,
    required super.expectedResultDate,
    required super.details,
    required super.attachment,
    required super.owner,
    required super.creation,
  });

  factory QuotationFollowUpModel.fromJson(Map<String, dynamic> json) {
    return QuotationFollowUpModel(
      name: json['name']?.toString() ?? json['id']?.toString() ?? '',
      followUpDate: _readValue(json, const [
        'follow_up_date',
        'date_follow',
        'mobile_api_last_update_date',
      ]),
      expectedResultDate: _readValue(json, const [
        'expected_result_date',
        'next_follow_up_date',
        'mobile_api_next_follow_up_date',
      ]),
      details: _readValue(json, const [
        'details',
        'follow_up',
        'mobile_api_last_follow_up_report',
      ]),
      attachment: json['attachment']?.toString() ?? '',
      owner: json['owner']?.toString() ?? '',
      creation: json['creation']?.toString() ??
          json['registered_on']?.toString() ??
          '',
    );
  }

  static String _readValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }
}
