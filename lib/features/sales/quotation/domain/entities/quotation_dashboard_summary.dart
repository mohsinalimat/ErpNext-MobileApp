class QuotationDashboardSummary {
  final int overdueCount;
  final int todayCount;
  final int thisWeekCount;
  final int monthCount;
  final int neverContactedCount;
  final int upcomingCount;

  const QuotationDashboardSummary({
    required this.overdueCount,
    required this.todayCount,
    required this.thisWeekCount,
    required this.monthCount,
    required this.neverContactedCount,
    required this.upcomingCount,
  });

  const QuotationDashboardSummary.empty()
      : overdueCount = 0,
        todayCount = 0,
        thisWeekCount = 0,
        monthCount = 0,
        neverContactedCount = 0,
        upcomingCount = 0;
}
