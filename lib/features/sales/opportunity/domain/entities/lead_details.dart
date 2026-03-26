import 'opportunity_activity.dart';
import 'opportunity_follow_up.dart';

class OpportunityDetails {
  final String name;
  final Map<String, dynamic> data;
  final List<OpportunityFollowUp> followUps;
  final List<OpportunityActivity> activityLog;

  const OpportunityDetails({
    required this.name,
    required this.data,
    required this.followUps,
    required this.activityLog,
  });
}
