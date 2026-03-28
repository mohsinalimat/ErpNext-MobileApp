import 'package:flutter/material.dart';

import '../../../../../core/utils/app_logger.dart';
import '../../domain/entities/quotation.dart';
import '../../domain/entities/quotation_dashboard_summary.dart';
import '../../domain/usecases/get_quotations_dashboard_summary_usecase.dart';
import '../../domain/usecases/get_quotations_usecase.dart';

class QuotationsProvider extends ChangeNotifier {
  QuotationsProvider(
    this._getQuotationsUseCase,
    this._getQuotationsDashboardSummaryUseCase,
  );

  final GetQuotationsUseCase _getQuotationsUseCase;
  final GetQuotationsDashboardSummaryUseCase _getQuotationsDashboardSummaryUseCase;
  static const int _pageSize = 20;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingSummary = false;
  bool _hasMore = true;
  int _nextStart = 0;
  String? _error;
  String _searchQuery = '';
  String _status = '';
  String _followUpFilter = 'all';
  String _sortBy = 'overdue_first';
  List<Quotation> _quotations = [];
  QuotationDashboardSummary _summary = const QuotationDashboardSummary.empty();

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingSummary => _isLoadingSummary;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get status => _status;
  String get followUpFilter => _followUpFilter;
  String get sortBy => _sortBy;
  List<Quotation> get quotations =>
      _applyLocalSort(_applyLocalFilter(_quotations));
  QuotationDashboardSummary get summary {
    if (_followUpFilter == 'all') {
      return _hasAnySummary(_summary) ? _summary : _buildLocalSummary(_quotations);
    }
    return _buildLocalSummary(quotations);
  }

  Future<void> initialize() async {
    await Future.wait([fetchQuotations(), fetchSummary()]);
  }

  Future<void> fetchQuotations() async {
    _isLoading = true;
    _error = null;
    _hasMore = true;
    _nextStart = 0;
    _quotations = [];
    notifyListeners();

    try {
      final batch = await _getQuotationsUseCase.call(
        start: 0,
        limit: _pageSize,
        status: _status.isEmpty ? null : _status,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      _quotations = batch;
      _logQuotationClassification(_quotations);
      _nextStart = batch.length;
      _hasMore = batch.length == _pageSize;
      if (!_isLoadingSummary) {
        _summary = _buildLocalSummary(_quotations);
      }
    } catch (e) {
      _error = e.toString();
      AppLogger.error('quotations fetch failed: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSummary() async {
    _isLoadingSummary = true;
    notifyListeners();

    try {
      final remoteSummary = await _getQuotationsDashboardSummaryUseCase.call(
        status: _status.isEmpty ? null : _status,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      _summary = _hasAnySummary(remoteSummary)
          ? remoteSummary
          : _buildLocalSummary(_quotations);
    } catch (e) {
      AppLogger.error('quotations summary failed: $e');
      _summary = _buildLocalSummary(_quotations);
    } finally {
      _isLoadingSummary = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _error = null;
    notifyListeners();

    try {
      final batch = await _getQuotationsUseCase.call(
        start: _nextStart,
        limit: _pageSize,
        status: _status.isEmpty ? null : _status,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      final existing = _quotations.map((quotation) => quotation.name).toSet();
      _quotations = [..._quotations, ...batch.where((quotation) => !existing.contains(quotation.name))];
      _logQuotationClassification(_quotations);
      _nextStart += batch.length;
      _hasMore = batch.length == _pageSize;
      if (!_isLoadingSummary) {
        _summary = _buildLocalSummary(_quotations);
      }
    } catch (e) {
      _error = e.toString();
      AppLogger.error('quotations load more failed: $_error');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshAfterMutation() async {
    await initialize();
  }

  void setSearchQuery(String value) {
    _searchQuery = value.trim();
    initialize();
  }

  void setStatus(String value) {
    if (_status == value) return;
    _status = value;
    initialize();
  }

  void setFollowUpFilter(String value) {
    if (_followUpFilter == value) return;
    _followUpFilter = value;
    initialize();
  }

  void setSortBy(String value) {
    if (_sortBy == value) return;
    _sortBy = value;
    fetchQuotations();
  }

  List<Quotation> _applyLocalFilter(List<Quotation> input) {
    final today = _todayOnly();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return input.where((quotation) {
      final state = _stateForQuotation(
        quotation,
        today: today,
        weekStart: weekStart,
        weekEnd: weekEnd,
      );

      switch (_followUpFilter) {
        case 'overdue':
          return state.isOverdue;
        case 'today':
          return state.isDueToday;
        case 'this_week':
          return state.isDueThisWeek;
        case 'month':
          return state.isDueThisMonth;
        case 'never_contacted':
          return state.isNeverContacted;
        case 'upcoming':
          return state.isUpcoming;
        default:
          return true;
      }
    }).toList();
  }

  List<Quotation> _applyLocalSort(List<Quotation> input) {
    final today = _todayOnly();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final items = [...input];

    int compareNextFollowUp(Quotation a, Quotation b) {
      final aDate = _dateOnly(a.nextFollowUpDate);
      final bDate = _dateOnly(b.nextFollowUpDate);
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    }

    int compareLastModifiedDesc(Quotation a, Quotation b) {
      final aDate = DateTime.tryParse(a.lastModified);
      final bDate = DateTime.tryParse(b.lastModified);
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    }

    int compareBoolFirst(bool a, bool b) {
      if (a == b) return 0;
      return a ? -1 : 1;
    }

    items.sort((a, b) {
      final aState = _stateForQuotation(
        a,
        today: today,
        weekStart: weekStart,
        weekEnd: weekEnd,
      );
      final bState = _stateForQuotation(
        b,
        today: today,
        weekStart: weekStart,
        weekEnd: weekEnd,
      );

      switch (_sortBy) {
        case 'next_follow_up_date_asc':
          final nextCompare = compareNextFollowUp(a, b);
          if (nextCompare != 0) return nextCompare;
          return compareLastModifiedDesc(a, b);
        case 'never_contacted_first':
          final neverCompare = compareBoolFirst(
            aState.isNeverContacted,
            bState.isNeverContacted,
          );
          if (neverCompare != 0) return neverCompare;
          final nextCompare = compareNextFollowUp(a, b);
          if (nextCompare != 0) return nextCompare;
          return compareLastModifiedDesc(a, b);
        case 'overdue_first':
        default:
          final overdueCompare = compareBoolFirst(
            aState.isOverdue,
            bState.isOverdue,
          );
          if (overdueCompare != 0) return overdueCompare;
          final todayCompare = compareBoolFirst(
            aState.isDueToday,
            bState.isDueToday,
          );
          if (todayCompare != 0) return todayCompare;
          final nextCompare = compareNextFollowUp(a, b);
          if (nextCompare != 0) return nextCompare;
          return compareLastModifiedDesc(a, b);
      }
    });

    return items;
  }

  QuotationDashboardSummary _buildLocalSummary(List<Quotation> quotations) {
    final today = _todayOnly();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    int overdue = 0;
    int todayCount = 0;
    int weekCount = 0;
    int monthCount = 0;
    int neverCount = 0;
    int upcoming = 0;

    for (final quotation in quotations) {
      final state = _stateForQuotation(
        quotation,
        today: today,
        weekStart: weekStart,
        weekEnd: weekEnd,
      );
      if (state.isNeverContacted) neverCount++;
      if (state.isOverdue) overdue++;
      if (state.isDueToday) todayCount++;
      if (state.isDueThisWeek) weekCount++;
      if (state.isDueThisMonth) monthCount++;
      if (state.isUpcoming) upcoming++;
    }

    return QuotationDashboardSummary(
      overdueCount: overdue,
      todayCount: todayCount,
      thisWeekCount: weekCount,
      monthCount: monthCount,
      neverContactedCount: neverCount,
      upcomingCount: upcoming,
    );
  }

  bool _isNeverContacted(Quotation quotation) {
    final last = _dateOnly(quotation.lastUpdateDate);
    final next = _dateOnly(quotation.nextFollowUpDate);
    return last == null &&
        next == null &&
        quotation.lastFollowUpReport.trim().isEmpty;
  }

  _QuotationFollowState _stateForQuotation(
    Quotation quotation, {
    required DateTime today,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) {
    final next = _dateOnly(quotation.nextFollowUpDate);
    final overdue = quotation.isOverdue || (next != null && next.isBefore(today));
    final dueToday =
        quotation.isDueToday || (next != null && next.isAtSameMomentAs(today));
    final dueThisWeek = quotation.isDueThisWeek ||
        (next != null && !next.isBefore(weekStart) && !next.isAfter(weekEnd));
    final dueThisMonth = quotation.isDueThisMonth ||
        (next != null && next.year == today.year && next.month == today.month);
    final never = quotation.neverContacted || _isNeverContacted(quotation);
    final upcoming = next != null && next.isAfter(today) && !overdue;

    return _QuotationFollowState(
      isOverdue: overdue,
      isDueToday: dueToday,
      isDueThisWeek: dueThisWeek,
      isDueThisMonth: dueThisMonth,
      isNeverContacted: never,
      isUpcoming: upcoming,
    );
  }

  void _logQuotationClassification(List<Quotation> quotations) {
    final today = _todayOnly();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    for (final quotation in quotations) {
      final state = _stateForQuotation(
        quotation,
        today: today,
        weekStart: weekStart,
        weekEnd: weekEnd,
      );
      AppLogger.sales(
        'quotation filter state name=${quotation.name} next=${quotation.nextFollowUpDate} '
        'overdue=${state.isOverdue} today=${state.isDueToday} '
        'week=${state.isDueThisWeek} month=${state.isDueThisMonth} '
        'never=${state.isNeverContacted} upcoming=${state.isUpcoming}',
      );
    }
  }

  bool _hasAnySummary(QuotationDashboardSummary summary) {
    return summary.overdueCount > 0 ||
        summary.todayCount > 0 ||
        summary.thisWeekCount > 0 ||
        summary.monthCount > 0 ||
        summary.neverContactedCount > 0 ||
        summary.upcomingCount > 0;
  }

  DateTime _todayOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime? _dateOnly(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

}

class _QuotationFollowState {
  final bool isOverdue;
  final bool isDueToday;
  final bool isDueThisWeek;
  final bool isDueThisMonth;
  final bool isNeverContacted;
  final bool isUpcoming;

  const _QuotationFollowState({
    required this.isOverdue,
    required this.isDueToday,
    required this.isDueThisWeek,
    required this.isDueThisMonth,
    required this.isNeverContacted,
    required this.isUpcoming,
  });
}
