import '../../domain/entities/opportunity_activity.dart';

class OpportunityActivityModel extends OpportunityActivity {
  const OpportunityActivityModel({
    required super.subject,
    required super.description,
    required super.by,
    required super.date,
  });

  factory OpportunityActivityModel.fromJson(Map<String, dynamic> json) {
    return OpportunityActivityModel(
      subject: _readValue(json, const ['subject', 'title', 'status']),
      description: _readValue(json, const ['description', 'content', 'comment']),
      by: _readValue(json, const ['owner', 'by', 'user']),
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
