import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../domain/entities/quotation_activity.dart';
import '../../domain/entities/quotation_follow_up.dart';
import '../providers/quotation_details_provider.dart';

class QuotationDetailsPage extends StatefulWidget {
  final String quotationName;

  const QuotationDetailsPage({super.key, required this.quotationName});

  @override
  State<QuotationDetailsPage> createState() => _QuotationDetailsPageState();
}

class _QuotationDetailsPageState extends State<QuotationDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<QuotationDetailsProvider>().load(widget.quotationName);
    });
  }

  Future<void> _openAddFollowUpDialog() async {
    final provider = context.read<QuotationDetailsProvider>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _AddQuotationFollowUpDialog(
        quotationName: widget.quotationName,
        provider: provider,
      ),
    );

    if (saved == true && mounted) {
      await context.read<QuotationDetailsProvider>().load(widget.quotationName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Follow up added successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotationDetailsProvider>();
    final details = provider.details;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quotationName),
        actions: [
          IconButton(
            tooltip: 'Open In ERPNext',
            onPressed: _openErpQuotation,
            icon: const Icon(Icons.open_in_browser_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.isLoading ? null : _openAddFollowUpDialog,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Add Follow Up'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && details == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : details == null
                  ? const Center(child: Text('No quotation details found'))
                  : RefreshIndicator(
                      onRefresh: () => provider.load(widget.quotationName),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        children: [
                          _QuotationSummaryCard(
                            data: details.data,
                            onOpenErp: _openErpQuotation,
                          ),
                          const SizedBox(height: 16),
                          _QuotationWorkflowCard(
                            quotationName: widget.quotationName,
                            data: details.data,
                          ),
                          const SizedBox(height: 16),
                          _QuotationPrintCard(
                            quotationName: widget.quotationName,
                            initialPrintData: details.printData,
                          ),
                          const SizedBox(height: 16),
                          _QuickActionsCard(data: details.data),
                          const SizedBox(height: 16),
                          const _SectionTitle(title: 'Quotation Data'),
                          const SizedBox(height: 8),
                          ...details.data.entries
                              .where((entry) => entry.value != null)
                              .where((entry) => entry.value.toString().trim().isNotEmpty)
                              .where((entry) => !{'content', 'print_url', 'pdf_url', 'default_print_format'}.contains(entry.key))
                              .map(
                                (entry) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(_labelFromKey(entry.key)),
                                    subtitle: Text(entry.value.toString()),
                                  ),
                                ),
                              ),
                          const SizedBox(height: 12),
                          _SectionTitle(
                            title: 'Follow Ups',
                            actionLabel: 'Add',
                            onTap: _openAddFollowUpDialog,
                          ),
                          const SizedBox(height: 8),
                          if (details.followUps.isEmpty)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No follow ups available'),
                              ),
                            )
                          else
                            ...details.followUps.map((item) => _FollowUpCard(followUp: item)),
                          const SizedBox(height: 12),
                          const _SectionTitle(title: 'Activity Log'),
                          const SizedBox(height: 8),
                          if (details.activityLog.isEmpty)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No activity log available'),
                              ),
                            )
                          else
                            ...details.activityLog.map((item) => _ActivityCard(activity: item)),
                        ],
                      ),
                    ),
    );
  }

  Future<void> _openErpQuotation() async {
    final encodedName = Uri.encodeComponent(widget.quotationName);
    final uri = Uri.parse('${ApiConstants.baseUrl}/app/quotation/$encodedName');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _QuotationSummaryCard extends StatelessWidget {
  const _QuotationSummaryCard({
    required this.data,
    required this.onOpenErp,
  });

  final Map<String, dynamic> data;
  final VoidCallback onOpenErp;

  @override
  Widget build(BuildContext context) {
    final name = _readDisplayName(data);
    final company = data['customer_name']?.toString() ?? data['party_name']?.toString() ?? '';
    final businessStatus = data['status']?.toString() ?? 'Quotation';
    final workflowState = data['workflow_state']?.toString() ?? '';
    final content = data['content']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0EA5A4)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (company.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(company, style: const TextStyle(color: Colors.white70)),
          ],
          if (content.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(content, style: const TextStyle(color: Colors.white)),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(label: 'Status: $businessStatus'),
              if (workflowState.isNotEmpty) _SummaryChip(label: 'Workflow: $workflowState'),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onOpenErp,
            icon: const Icon(Icons.open_in_browser_rounded),
            label: const Text('Open In ERPNext'),
          ),
        ],
      ),
    );
  }
}

class _QuotationWorkflowCard extends StatefulWidget {
  const _QuotationWorkflowCard({
    required this.quotationName,
    required this.data,
  });

  final String quotationName;
  final Map<String, dynamic> data;

  @override
  State<_QuotationWorkflowCard> createState() => _QuotationWorkflowCardState();
}

class _QuotationWorkflowCardState extends State<_QuotationWorkflowCard> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotationDetailsProvider>();
    final workflow = provider.workflow;
    final actions = workflow.actions;
    final businessStatus = widget.data['status']?.toString().trim() ?? '';
    final detailsWorkflowState = widget.data['workflow_state']?.toString().trim() ?? '';
    final actionState = actions.isNotEmpty ? actions.first.state.trim() : '';
    final workflowState = actionState.isNotEmpty
        ? actionState
        : (detailsWorkflowState.isNotEmpty ? detailsWorkflowState : '-');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workflow',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _WorkflowStateBadge(status: workflowState),
                if (businessStatus.isNotEmpty) _WorkflowInfoChip(label: 'Status: $businessStatus'),
                if (workflow.workflowName.isNotEmpty) _WorkflowInfoChip(label: workflow.workflowName),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Current Workflow State: $workflowState',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions.map((action) {
                  return FilledButton.tonal(
                    onPressed: _isSubmitting || provider.isWorkflowLoading
                        ? null
                        : () => _applyWorkflowAction(context, action.action),
                    child: Text(action.action),
                  );
                }).toList(),
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Text(
                'No workflow actions available right now.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _applyWorkflowAction(BuildContext context, String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Workflow Action'),
        content: Text(
          'Are you sure you want to run "$action" on this quotation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    final provider = context.read<QuotationDetailsProvider>();

    try {
      await provider.executeWorkflowAction(
        quotationName: widget.quotationName,
        action: action,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Workflow action $action executed')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to update workflow')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _QuotationPrintCard extends StatefulWidget {
  const _QuotationPrintCard({
    required this.quotationName,
    required this.initialPrintData,
  });

  final String quotationName;
  final Map<String, dynamic> initialPrintData;

  @override
  State<_QuotationPrintCard> createState() => _QuotationPrintCardState();
}

class _QuotationPrintCardState extends State<_QuotationPrintCard> {
  String? _selectedFormat;

  @override
  void initState() {
    super.initState();
    _selectedFormat = _defaultFormat(widget.initialPrintData);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotationDetailsProvider>();
    final printData =
        provider.printData.isNotEmpty ? provider.printData : widget.initialPrintData;
    final formats = _formats(printData);
    final effectiveSelected = formats.contains(_selectedFormat)
        ? _selectedFormat
        : (formats.isNotEmpty ? formats.first : null);
    final printUrl = printData['print_url']?.toString() ?? '';
    final pdfUrl = printData['pdf_url']?.toString() ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Print',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (formats.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: effectiveSelected,
                decoration: const InputDecoration(
                  labelText: 'Print Format',
                  border: OutlineInputBorder(),
                ),
                items: formats
                    .map(
                      (format) => DropdownMenuItem<String>(
                        value: format,
                        child: Text(format),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  if (value == null) return;
                  setState(() => _selectedFormat = value);
                  try {
                    await context
                        .read<QuotationDetailsProvider>()
                        .refreshPrintData(
                          quotationName: widget.quotationName,
                          printFormat: value,
                        );
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.read<QuotationDetailsProvider>().error ??
                              'Failed to load print data',
                        ),
                      ),
                    );
                  }
                },
              )
            else
              const Text(
                'No print formats available',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _openErpQuotation(),
                  icon: const Icon(Icons.open_in_browser_rounded),
                  label: const Text('Open In ERPNext'),
                ),
                if (printUrl.isNotEmpty)
                  FilledButton.tonalIcon(
                    onPressed: () => _openUrl(printUrl),
                    icon: const Icon(Icons.language_rounded),
                    label: const Text('Open In Browser'),
                  ),
                if (printUrl.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () => _openUrl(printUrl),
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Open Print View'),
                  ),
                if (pdfUrl.isNotEmpty)
                  FilledButton.tonalIcon(
                    onPressed: () => _openUrl(pdfUrl),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('Open PDF'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<String> _formats(Map<String, dynamic> printData) {
    final raw = printData['available_print_formats'];
    if (raw is List) {
      return raw
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  String? _defaultFormat(Map<String, dynamic> printData) {
    final defaultFormat = printData['default_print_format']?.toString();
    if (defaultFormat != null && defaultFormat.trim().isNotEmpty) {
      return defaultFormat.trim();
    }
    final formats = _formats(printData);
    return formats.isNotEmpty ? formats.first : null;
  }

  Future<void> _openUrl(String value) async {
    final uri = value.startsWith('http')
        ? Uri.parse(value)
        : Uri.parse('${ApiConstants.baseUrl}$value');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openErpQuotation() async {
    final encodedName = Uri.encodeComponent(widget.quotationName);
    final uri = Uri.parse('${ApiConstants.baseUrl}/app/quotation/$encodedName');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final mobile = data['mobile_no']?.toString() ?? '';
    final phone = data['phone']?.toString() ?? '';
    final whatsapp = data['whatsapp_no']?.toString() ?? mobile;
    final email = data['email_id']?.toString() ?? '';

    if (mobile.isEmpty && phone.isEmpty && whatsapp.isEmpty && email.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (mobile.isNotEmpty || phone.isNotEmpty)
              _ActionButton(
                label: 'Call',
                icon: Icons.call_rounded,
                color: const Color(0xFF0F766E),
                onTap: () => _launchUri(
                  Uri.parse('tel:${mobile.isNotEmpty ? mobile : phone}'),
                ),
              ),
            if (mobile.isNotEmpty)
              _ActionButton(
                label: 'SMS',
                icon: Icons.sms_rounded,
                color: const Color(0xFF0369A1),
                onTap: () => _launchUri(Uri.parse('sms:$mobile')),
              ),
            if (whatsapp.isNotEmpty)
              _ActionButton(
                label: 'WhatsApp',
                icon: Icons.chat_rounded,
                color: const Color(0xFF15803D),
                onTap: () => _launchUri(
                  Uri.parse('https://wa.me/${_normalizePhone(whatsapp)}'),
                ),
              ),
            if (email.isNotEmpty)
              _ActionButton(
                label: 'Email',
                icon: Icons.email_rounded,
                color: const Color(0xFF7C3AED),
                onTap: () => _launchUri(Uri.parse('mailto:$email')),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUri(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[^0-9+]'), '');
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
      ),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _WorkflowInfoChip extends StatelessWidget {
  const _WorkflowInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0369A1),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WorkflowStateBadge extends StatelessWidget {
  const _WorkflowStateBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.toLowerCase()) {
      'approved' => const Color(0xFF15803D),
      'rejected' => const Color(0xFFDC2626),
      'pending approval' => const Color(0xFFD97706),
      'pending for sales manager' => const Color(0xFF0369A1),
      _ => const Color(0xFF7C3AED),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        if (actionLabel != null && onTap != null)
          TextButton(onPressed: onTap, child: Text(actionLabel!)),
      ],
    );
  }
}

class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard({required this.followUp});

  final QuotationFollowUp followUp;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _displayDate(followUp.followUpDate),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (followUp.expectedResultDate.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Expected Result: ${_displayDate(followUp.expectedResultDate)}'),
            ],
            if (followUp.details.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(followUp.details),
            ],
            if (followUp.attachment.isNotEmpty) ...[
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () => _openAttachment(followUp.attachment),
                icon: const Icon(Icons.attach_file_rounded),
                label: const Text('Open Attachment'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openAttachment(String path) async {
    final uri = path.startsWith('http')
        ? Uri.parse(path)
        : Uri.parse('${ApiConstants.baseUrl}$path');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final QuotationActivity activity;

  @override
  Widget build(BuildContext context) {
    final parsed = _parseActivityDescription(activity.description);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFECFDF5),
          child: Icon(Icons.history_rounded, color: Color(0xFF0F766E)),
        ),
        title: Text(activity.subject.isEmpty ? 'Activity' : activity.subject),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (parsed.text.isNotEmpty) Text(parsed.text),
            if (parsed.link != null) ...[
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () => _openAttachment(parsed.link!),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Attachment'),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${activity.by.isEmpty ? 'System' : activity.by} • ${_displayDate(activity.date)}',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttachment(String path) async {
    final uri = path.startsWith('http')
        ? Uri.parse(path)
        : Uri.parse('${ApiConstants.baseUrl}$path');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _AddQuotationFollowUpDialog extends StatefulWidget {
  const _AddQuotationFollowUpDialog({
    required this.quotationName,
    required this.provider,
  });

  final String quotationName;
  final QuotationDetailsProvider provider;

  @override
  State<_AddQuotationFollowUpDialog> createState() =>
      _AddQuotationFollowUpDialogState();
}

class _AddQuotationFollowUpDialogState
    extends State<_AddQuotationFollowUpDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _followUpDateController = TextEditingController(
    text: _today(),
  );
  final TextEditingController _expectedDateController = TextEditingController(
    text: _today(addDays: 2),
  );
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _attachmentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? _attachmentPath;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _followUpDateController.dispose();
    _expectedDateController.dispose();
    _detailsController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  Future<void> _pickFromFiles() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null || !mounted) return;
    setState(() {
      _attachmentPath = result.files.single.path!;
      _attachmentController.text = result.files.single.name;
    });
  }

  Future<void> _pickFromCamera() async {
    final file = await _imagePicker.pickImage(source: ImageSource.camera);
    if (file == null || !mounted) return;
    setState(() {
      _attachmentPath = file.path;
      _attachmentController.text = file.name;
    });
  }

  Future<void> _pickFromGallery() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    setState(() {
      _attachmentPath = file.path;
      _attachmentController.text = file.name;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final provider = widget.provider;

    try {
      await provider.addFollowUp(
        quotationName: widget.quotationName,
        followUpDate: _followUpDateController.text.trim(),
        expectedResultDate: _expectedDateController.text.trim(),
        details: _detailsController.text.trim(),
        attachmentPath: _attachmentPath,
        attachment: _attachmentPath == null
            ? _attachmentController.text.trim()
            : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to add follow up')),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Follow Up'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DateInput(label: 'Follow Up Date', controller: _followUpDateController),
              const SizedBox(height: 10),
              _DateInput(label: 'Expected Result Date', controller: _expectedDateController),
              const SizedBox(height: 10),
              TextFormField(
                controller: _detailsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Details',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Details are required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _attachmentController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Attachment',
                  hintText: 'Pick file, camera, or gallery',
                  border: const OutlineInputBorder(),
                  suffixIcon: _attachmentController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            setState(() {
                              _attachmentPath = null;
                              _attachmentController.clear();
                            });
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickFromFiles,
                    icon: const Icon(Icons.attach_file_rounded),
                    label: const Text('File'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Gallery'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickFromCamera,
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Camera'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _DateInput extends StatelessWidget {
  const _DateInput({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today_rounded),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return '$label is required';
        return null;
      },
      onTap: () async {
        final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked == null) return;
        controller.text = _formatDate(picked);
      },
    );
  }
}

String _today({int addDays = 0}) =>
    _formatDate(DateTime.now().add(Duration(days: addDays)));

String _formatDate(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _labelFromKey(String key) {
  const customLabels = {
    'email_id': 'Email',
    'mobile_no': 'Mobile',
    'whatsapp_no': 'WhatsApp',
    'status': 'Business Status',
    'workflow_state': 'Workflow State',
    'quotation_amount': 'Quotation Amount',
    'expected_closing': 'Expected Closing',
    'last_update_date': 'Last Update Date',
    'next_follow_up_date': 'Next Follow Up Date',
    'last_follow_up_report': 'Last Follow Up Report',
  };
  if (customLabels.containsKey(key)) return customLabels[key]!;

  return key
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _displayDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value.isEmpty ? '-' : value;
  return _formatDate(parsed);
}

String _readDisplayName(Map<String, dynamic> data) {
  final values = [
    data['display_name'],
    data['customer_name'],
    data['party_name'],
    data['id'],
  ];

  for (final value in values) {
    final text = value?.toString() ?? '';
    if (text.trim().isNotEmpty) return text;
  }
  return 'Quotation';
}

_ParsedActivityDescription _parseActivityDescription(String raw) {
  if (raw.trim().isEmpty) {
    return const _ParsedActivityDescription(text: '');
  }

  final anchor = RegExp(
    r'<a\s+href="([^"]+)"[^>]*>([^<]+)</a>',
    caseSensitive: false,
  ).firstMatch(raw);

  if (anchor != null) {
    final href = anchor.group(1) ?? '';
    final label = anchor.group(2) ?? '';
    final prefix = raw.substring(0, anchor.start).replaceAll(RegExp(r'<[^>]+>'), '').trim();
    final suffix = raw.substring(anchor.end).replaceAll(RegExp(r'<[^>]+>'), '').trim();
    final textParts = [
      if (prefix.isNotEmpty) prefix,
      if (label.isNotEmpty) label,
      if (suffix.isNotEmpty) suffix,
    ];

    return _ParsedActivityDescription(
      text: textParts.join(' ').trim(),
      link: href.isEmpty ? null : href,
    );
  }

  return _ParsedActivityDescription(
    text: raw.replaceAll(RegExp(r'<[^>]+>'), '').trim(),
  );
}

class _ParsedActivityDescription {
  final String text;
  final String? link;

  const _ParsedActivityDescription({
    required this.text,
    this.link,
  });
}
