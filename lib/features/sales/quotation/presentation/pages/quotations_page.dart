import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/utils/app_logger.dart';
import '../../domain/entities/quotation.dart';
import '../providers/quotations_provider.dart';
import 'quotation_details_page.dart';
import '../widgets/quotation_scope.dart';

class QuotationsPage extends StatefulWidget {
  final bool embedded;

  const QuotationsPage({super.key, this.embedded = false});

  @override
  State<QuotationsPage> createState() => _QuotationsPageState();
}

class _QuotationsPageState extends State<QuotationsPage> {
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
    ('this_week', 'This Week'),
    ('month', 'This Month'),
    ('never_contacted', 'Never Contacted'),
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
        context.read<QuotationsProvider>().loadMore();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<QuotationsProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotationsProvider>();

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
                    hintText: 'Search quotation, customer, email...',
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
              onRefresh: provider.fetchQuotations,
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
                                      onPressed: provider.fetchQuotations,
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : provider.quotations.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 140),
                                Center(child: Text('No quotations found')),
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
                              itemCount: provider.quotations.length +
                                  (provider.hasMore || provider.isLoadingMore
                                      ? 1
                                      : 0),
                              itemBuilder: (context, index) {
                                if (index >= provider.quotations.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final quotation = provider.quotations[index];
                                return _QuotationCard(
                                  quotation: quotation,
                                  onTap: () async {
                                    AppLogger.nav('open quotation details ${quotation.name}');
                                    final changed = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => QuotationScope(
                                          child: QuotationDetailsPage(
                                            quotationName: quotation.name,
                                          ),
                                        ),
                                      ),
                                    );
                                    if (changed == true && mounted) {
                                      await context
                                          .read<QuotationsProvider>()
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
      appBar: widget.embedded ? null : AppBar(title: const Text('Quotations')),
      backgroundColor: widget.embedded ? Colors.transparent : null,
      body: body,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.provider});

  final QuotationsProvider provider;

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

class _QuotationCard extends StatelessWidget {
  const _QuotationCard({required this.quotation, required this.onTap});

  final Quotation quotation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = quotation.firstName.isNotEmpty
        ? quotation.firstName
        : (quotation.companyName.isNotEmpty ? quotation.companyName : quotation.name);

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
                        if (quotation.companyName.isNotEmpty)
                          Text(
                            quotation.companyName,
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: quotation.status),
                ],
              ),
              const SizedBox(height: 12),
              Text('Code: ${quotation.name}'),
              if (quotation.email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Email: ${quotation.email}'),
              ],
              if (quotation.mobileNo.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Mobile: ${quotation.mobileNo}'),
              ],
              if (quotation.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  quotation.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
              ],
              if (quotation.source.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('From: ${quotation.source}'),
              ],
              const SizedBox(height: 4),
              Text(
                'Workflow State: ${((quotation.workflowState ?? '').trim().isEmpty) ? '-' : quotation.workflowState!.trim()}',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (quotation.lastModified.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Last Modified: ${_displayDate(quotation.lastModified)}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
              if (quotation.nextFollowUpDate.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Next Follow Up: ${_displayDate(quotation.nextFollowUpDate)}',
                  style: TextStyle(
                    color: _followUpColor(quotation.nextFollowUpDate),
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
      'open' => const Color(0xFF0369A1),
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
        status.isEmpty ? 'Quotation' : status,
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
