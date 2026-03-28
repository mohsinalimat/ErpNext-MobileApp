import '../../domain/entities/quotation_activity.dart';

class QuotationActivityModel extends QuotationActivity {
  const QuotationActivityModel({
    required super.subject,
    required super.description,
    required super.by,
    required super.date,
  });

  factory QuotationActivityModel.fromJson(Map<String, dynamic> json) {
    return QuotationActivityModel(
      subject: _readValue(json, const ['subject', 'title', 'status']),
      description: _readValue(json, const ['description', 'content', 'comment']),
      by: _readValue(json, const ['comment_by', 'owner', 'by', 'user']),
      date: _readValue(json, const ['creation', 'date', 'modified']),
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
