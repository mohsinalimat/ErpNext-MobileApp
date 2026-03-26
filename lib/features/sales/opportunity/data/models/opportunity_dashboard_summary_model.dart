import '../../domain/entities/opportunity_dashboard_summary.dart';

class OpportunityDashboardSummaryModel extends OpportunityDashboardSummary {
  const OpportunityDashboardSummaryModel({
    required super.overdueCount,
    required super.todayCount,
    required super.thisWeekCount,
    required super.monthCount,
    required super.neverContactedCount,
    required super.upcomingCount,
  });

  factory OpportunityDashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final payload = _extractPayload(json);
    final summary = payload['summary'];
    final data = summary is Map<String, dynamic> ? summary : payload;
    return OpportunityDashboardSummaryModel(
      overdueCount: _toInt(data['overdue_count']),
      todayCount: _toInt(data['today_count']),
      thisWeekCount: _toInt(data['this_week_count']),
      monthCount: _toInt(data['month_count']),
      neverContactedCount: _toInt(data['never_contacted_count']),
      upcomingCount: _toInt(data['upcoming_count']),
    );
  }

  static Map<String, dynamic> _extractPayload(Map<String, dynamic> json) {
    final message = json['message'];
    if (message is Map<String, dynamic>) return message;
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return json;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}
