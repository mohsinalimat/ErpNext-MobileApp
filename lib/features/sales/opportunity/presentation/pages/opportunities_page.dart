import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/utils/app_logger.dart';
import '../../domain/entities/opportunity.dart';
import '../providers/opportunities_provider.dart';
import 'opportunity_details_page.dart';
import 'opportunity_form_page.dart';
import '../widgets/opportunity_scope.dart';

class OpportunitiesPage extends StatefulWidget {
  final bool embedded;

  const OpportunitiesPage({super.key, this.embedded = false});

  @override
  State<OpportunitiesPage> createState() => _OpportunitiesPageState();
}

class _OpportunitiesPageState extends State<OpportunitiesPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const _statuses = [
    '',
    'Open',
    'Quotation',
    'Replied',
    'Converted',
    'Lost',
    'Closed',
  ];
  static const _followUpFilters = [
    ('all', 'All'),
    ('overdue', 'Overdue'),
    ('today', 'Today'),
    ('week', 'This Week'),
    ('month', 'This Month'),
    ('never', 'Never Contacted'),
    ('upcoming', 'Upcoming'),
  ];
  static const _sortOptions = [
    ('overdue_first', 'Overdue First'),
    ('next_follow_up_date_asc', 'Next Follow Up'),
    ('never_contacted_first', 'Never Contacted First'),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final threshold = _scrollController.position.maxScrollExtent - 180;
      if (_scrollController.position.pixels >= threshold) {
        context.read<OpportunitiesProvider>().loadMore();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OpportunitiesProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openCreateForm(BuildContext context) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const OpportunityScope(
          child: OpportunityFormPage(),
        ),
      ),
    );
    if (created == true && mounted) {
      await context.read<OpportunitiesProvider>().refreshAfterMutation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OpportunitiesProvider>();

    final body = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF7ED), Color(0xFFFFFBF5)],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: provider.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search opportunity, customer, email...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final item = _statuses[index];
                      return ChoiceChip(
                        label: Text(item.isEmpty ? 'All' : item),
                        selected: provider.status == item,
                        onSelected: (_) => provider.setStatus(item),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemCount: _statuses.length,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final item = _followUpFilters[index];
                      return ChoiceChip(
                        label: Text(item.$2),
                        selected: provider.followUpFilter == item.$1,
                        onSelected: (_) => provider.setFollowUpFilter(item.$1),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemCount: _followUpFilters.length,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: DropdownButton<String>(
                    value: provider.sortBy,
                    underline: const SizedBox.shrink(),
                    items: _sortOptions
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.$1,
                            child: Text(item.$2),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      provider.setSortBy(value);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                _SummaryRow(provider: provider),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.fetchOpportunities,
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                      ? ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFFCA5A5),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.cloud_off_rounded,
                                      color: Color(0xFFDC2626),
                                      size: 34,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      provider.error!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFB91C1C),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      onPressed: provider.fetchOpportunities,
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : provider.opportunities.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 140),
                                Center(child: Text('No opportunities found')),
                              ],
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                8,
                                16,
                                100,
                              ),
                              itemCount: provider.opportunities.length +
                                  (provider.hasMore || provider.isLoadingMore
                                      ? 1
                                      : 0),
                              itemBuilder: (context, index) {
                                if (index >= provider.opportunities.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final opportunity = provider.opportunities[index];
                                return _OpportunityCard(
                                  opportunity: opportunity,
                                  onTap: () async {
                                    AppLogger.nav('open opportunity details ${opportunity.name}');
                                    final changed = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OpportunityScope(
                                          child: OpportunityDetailsPage(
                                            opportunityName: opportunity.name,
                                          ),
                                        ),
                                      ),
                                    );
                                    if (changed == true && mounted) {
                                      await context
                                          .read<OpportunitiesProvider>()
                                          .refreshAfterMutation();
                                    }
                                  },
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Opportunities')),
      backgroundColor: widget.embedded ? Colors.transparent : null,
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Opportunity'),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.provider});

  final OpportunitiesProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingSummary) {
      return const LinearProgressIndicator();
    }

    final summary = provider.summary;
    final items = [
      ('Overdue', summary.overdueCount, const Color(0xFFDC2626)),
      ('Today', summary.todayCount, const Color(0xFFD97706)),
      ('This Week', summary.thisWeekCount, const Color(0xFF0369A1)),
      ('This Month', summary.monthCount, const Color(0xFF0F766E)),
      ('Never', summary.neverContactedCount, const Color(0xFF7C3AED)),
      ('Upcoming', summary.upcomingCount, const Color(0xFF15803D)),
    ];

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 110,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: item.$3.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${item.$2}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: item.$3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.$1,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: items.length,
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({required this.opportunity, required this.onTap});

  final Opportunity opportunity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = opportunity.firstName.isNotEmpty
        ? opportunity.firstName
        : (opportunity.companyName.isNotEmpty ? opportunity.companyName : opportunity.name);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFFFEDD5),
                    child: Text(
                      title.isEmpty ? '?' : title[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF9A3412),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (opportunity.companyName.isNotEmpty)
                          Text(
                            opportunity.companyName,
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: opportunity.status),
                ],
              ),
              const SizedBox(height: 12),
              Text('Code: ${opportunity.name}'),
              if (opportunity.email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Email: ${opportunity.email}'),
              ],
              if (opportunity.mobileNo.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Mobile: ${opportunity.mobileNo}'),
              ],
              if (opportunity.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  opportunity.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
              ],
              if (opportunity.source.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('From: ${opportunity.source}'),
              ],
              const SizedBox(height: 4),
              Text(
                'Workflow State: ${((opportunity.workflowState ?? '').trim().isEmpty) ? '-' : opportunity.workflowState!.trim()}',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (opportunity.lastModified.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Last Modified: ${_displayDate(opportunity.lastModified)}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
              if (opportunity.nextFollowUpDate.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Next Follow Up: ${_displayDate(opportunity.nextFollowUpDate)}',
                  style: TextStyle(
                    color: _followUpColor(opportunity.nextFollowUpDate),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 4),
                const Text(
                  'Next Follow Up: Not scheduled',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _followUpColor(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return const Color(0xFF94A3B8);
    final today = DateTime.now();
    final compare = DateTime(today.year, today.month, today.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target.isBefore(compare)) return const Color(0xFFDC2626);
    if (target.isAtSameMomentAs(compare)) return const Color(0xFFD97706);
    return const Color(0xFF15803D);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.toLowerCase()) {
      'quotation' => const Color(0xFF7C3AED),
      'opportunity' => const Color(0xFF0369A1),
      'converted' => const Color(0xFF15803D),
      'lost' => const Color(0xFFDC2626),
      'replied' => const Color(0xFFD97706),
      'closed' => const Color(0xFF475569),
      _ => const Color(0xFF9A3412),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.isEmpty ? 'Opportunity' : status,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _displayDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final y = parsed.year.toString().padLeft(4, '0');
  final m = parsed.month.toString().padLeft(2, '0');
  final d = parsed.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
