import 'quotation_activity.dart';
import 'quotation_follow_up.dart';

class QuotationDetails {
  final String name;
  final Map<String, dynamic> data;
  final Map<String, dynamic> printData;
  final List<QuotationFollowUp> followUps;
  final List<QuotationActivity> activityLog;

  const QuotationDetails({
    required this.name,
    required this.data,
    required this.printData,
    required this.followUps,
    required this.activityLog,
  });
}
