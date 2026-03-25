import 'lead_activity.dart';
import 'lead_follow_up.dart';

class LeadDetails {
  final String name;
  final Map<String, dynamic> data;
  final List<LeadFollowUp> followUps;
  final List<LeadActivity> activityLog;

  const LeadDetails({
    required this.name,
    required this.data,
    required this.followUps,
    required this.activityLog,
  });
}
