import 'package:flutter/material.dart';

import '../../../../../core/utils/app_logger.dart';
import '../../domain/entities/opportunity.dart';
import '../../domain/entities/opportunity_dashboard_summary.dart';
import '../../domain/usecases/get_opportunities_dashboard_summary_usecase.dart';
import '../../domain/usecases/get_opportunities_usecase.dart';

class OpportunitiesProvider extends ChangeNotifier {
  OpportunitiesProvider(
    this._getOpportunitiesUseCase,
    this._getOpportunitiesDashboardSummaryUseCase,
  );

  final GetOpportunitiesUseCase _getOpportunitiesUseCase;
  final GetOpportunitiesDashboardSummaryUseCase _getOpportunitiesDashboardSummaryUseCase;
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
  List<Opportunity> _opportunities = [];
  OpportunityDashboardSummary _summary = const OpportunityDashboardSummary.empty();

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingSummary => _isLoadingSummary;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get status => _status;
  String get followUpFilter => _followUpFilter;
  String get sortBy => _sortBy;
  List<Opportunity> get opportunities => _applyLocalFilter(_opportunities);
  OpportunityDashboardSummary get summary {
    if (_followUpFilter == 'all') {
      return _hasAnySummary(_summary) ? _summary : _buildLocalSummary(_opportunities);
    }
    return _buildLocalSummary(opportunities);
  }

  Future<void> initialize() async {
    await Future.wait([fetchOpportunities(), fetchSummary()]);
  }

  Future<void> fetchOpportunities() async {
    _isLoading = true;
    _error = null;
    _hasMore = true;
    _nextStart = 0;
    _opportunities = [];
    notifyListeners();

    try {
      final batch = await _getOpportunitiesUseCase.call(
        start: 0,
        limit: _pageSize,
        status: _status.isEmpty ? null : _status,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        followUpFilter: _toApiFollowUpFilter(_followUpFilter),
        sortBy: _sortBy,
      );

      _opportunities = batch;
      _logOpportunityClassification(_opportunities);
      _nextStart = batch.length;
      _hasMore = batch.length == _pageSize;
      if (!_isLoadingSummary) {
        _summary = _buildLocalSummary(_opportunities);
      }
    } catch (e) {
      _error = e.toString();
      AppLogger.error('opportunities fetch failed: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSummary() async {
    _isLoadingSummary = true;
    notifyListeners();

    try {
      final remoteSummary = await _getOpportunitiesDashboardSummaryUseCase.call(
        status: _status.isEmpty ? null : _status,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      _summary = _hasAnySummary(remoteSummary)
          ? remoteSummary
          : _buildLocalSummary(_opportunities);
    } catch (e) {
      AppLogger.error('opportunities summary failed: $e');
      _summary = _buildLocalSummary(_opportunities);
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
      final batch = await _getOpportunitiesUseCase.call(
        start: _nextStart,
        limit: _pageSize,
        status: _status.isEmpty ? null : _status,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        followUpFilter: _toApiFollowUpFilter(_followUpFilter),
        sortBy: _sortBy,
      );

      final existing = _opportunities.map((opportunity) => opportunity.name).toSet();
      _opportunities = [..._opportunities, ...batch.where((opportunity) => !existing.contains(opportunity.name))];
      _logOpportunityClassification(_opportunities);
      _nextStart += batch.length;
      _hasMore = batch.length == _pageSize;
      if (!_isLoadingSummary) {
        _summary = _buildLocalSummary(_opportunities);
      }
    } catch (e) {
      _error = e.toString();
      AppLogger.error('opportunities load more failed: $_error');
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
    fetchOpportunities();
  }

  List<Opportunity> _applyLocalFilter(List<Opportunity> input) {
    final today = _todayOnly();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return input.where((opportunity) {
      final state = _stateForOpportunity(
        opportunity,
        today: today,
        weekStart: weekStart,
        weekEnd: weekEnd,
      );

      switch (_followUpFilter) {
        case 'overdue':
          return state.isOverdue;
        case 'today':
          return state.isDueToday;
        case 'week':
          return state.isDueThisWeek;
        case 'month':
          return state.isDueThisMonth;
        case 'never':
          return state.isNeverContacted;
        case 'upcoming':
          return state.isUpcoming;
        default:
          return true;
      }
    }).toList();
  }

  OpportunityDashboardSummary _buildLocalSummary(List<Opportunity> opportunities) {
    final today = _todayOnly();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    int overdue = 0;
    int todayCount = 0;
    int weekCount = 0;
    int monthCount = 0;
    int neverCount = 0;
    int upcoming = 0;

    for (final opportunity in opportunities) {
      final state = _stateForOpportunity(
        opportunity,
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

    return OpportunityDashboardSummary(
      overdueCount: overdue,
      todayCount: todayCount,
      thisWeekCount: weekCount,
      monthCount: monthCount,
      neverContactedCount: neverCount,
      upcomingCount: upcoming,
    );
  }

  bool _isNeverContacted(Opportunity opportunity) {
    final last = _dateOnly(opportunity.lastUpdateDate);
    final next = _dateOnly(opportunity.nextFollowUpDate);
    return last == null &&
        next == null &&
        opportunity.lastFollowUpReport.trim().isEmpty;
  }

  _OpportunityFollowState _stateForOpportunity(
    Opportunity opportunity, {
    required DateTime today,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) {
    final next = _dateOnly(opportunity.nextFollowUpDate);
    final overdue = opportunity.isOverdue || (next != null && next.isBefore(today));
    final dueToday =
        opportunity.isDueToday || (next != null && next.isAtSameMomentAs(today));
    final dueThisWeek = opportunity.isDueThisWeek ||
        (next != null && !next.isBefore(weekStart) && !next.isAfter(weekEnd));
    final dueThisMonth = opportunity.isDueThisMonth ||
        (next != null && next.year == today.year && next.month == today.month);
    final never = opportunity.neverContacted || _isNeverContacted(opportunity);
    final upcoming = next != null && next.isAfter(today) && !overdue;

    return _OpportunityFollowState(
      isOverdue: overdue,
      isDueToday: dueToday,
      isDueThisWeek: dueThisWeek,
      isDueThisMonth: dueThisMonth,
      isNeverContacted: never,
      isUpcoming: upcoming,
    );
  }

  void _logOpportunityClassification(List<Opportunity> opportunities) {
    final today = _todayOnly();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    for (final opportunity in opportunities) {
      final state = _stateForOpportunity(
        opportunity,
        today: today,
        weekStart: weekStart,
        weekEnd: weekEnd,
      );
      AppLogger.sales(
        'opportunity filter state name=${opportunity.name} next=${opportunity.nextFollowUpDate} '
        'overdue=${state.isOverdue} today=${state.isDueToday} '
        'week=${state.isDueThisWeek} month=${state.isDueThisMonth} '
        'never=${state.isNeverContacted} upcoming=${state.isUpcoming}',
      );
    }
  }

  bool _hasAnySummary(OpportunityDashboardSummary summary) {
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

  String? _toApiFollowUpFilter(String value) {
    switch (value) {
      case 'overdue':
        return 'overdue';
      case 'today':
        return 'today';
      case 'week':
        return 'this_week';
      case 'month':
        return 'month';
      case 'never':
        return 'never_contacted';
      case 'upcoming':
        return 'upcoming';
      default:
        return null;
    }
  }
}

class _OpportunityFollowState {
  final bool isOverdue;
  final bool isDueToday;
  final bool isDueThisWeek;
  final bool isDueThisMonth;
  final bool isNeverContacted;
  final bool isUpcoming;

  const _OpportunityFollowState({
    required this.isOverdue,
    required this.isDueToday,
    required this.isDueThisWeek,
    required this.isDueThisMonth,
    required this.isNeverContacted,
    required this.isUpcoming,
  });
}
