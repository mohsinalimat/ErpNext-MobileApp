import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/utils/app_logger.dart';
import '../../domain/entities/opportunity_field.dart';
import '../../domain/entities/opportunity_option_item.dart';
import '../../domain/entities/opportunity_required_field_definition.dart';
import '../../domain/usecases/create_opportunity_usecase.dart';
import '../../domain/usecases/get_opportunity_required_fields_usecase.dart';
import '../../domain/usecases/search_opportunity_link_options_usecase.dart';
import '../../domain/usecases/update_opportunity_usecase.dart';

class OpportunityFormProvider extends ChangeNotifier {
  OpportunityFormProvider(
    this._getOpportunityRequiredFieldsUseCase,
    this._createOpportunityUseCase,
    this._updateOpportunityUseCase,
    this._searchOpportunityLinkOptionsUseCase,
  );

  final GetOpportunityRequiredFieldsUseCase _getOpportunityRequiredFieldsUseCase;
  final CreateOpportunityUseCase _createOpportunityUseCase;
  final UpdateOpportunityUseCase _updateOpportunityUseCase;
  final SearchOpportunityLinkOptionsUseCase _searchOpportunityLinkOptionsUseCase;

  final Map<String, String> _values = {};
  final Map<String, OpportunityRequiredFieldDefinition> _definitions = {};
  final List<_OpportunityFieldConfig> _catalog = const [
    _OpportunityFieldConfig('department', 'Department', OpportunityFieldType.link),
    _OpportunityFieldConfig(
      'custom_customer_type',
      'Customer Type',
      OpportunityFieldType.select,
    ),
    _OpportunityFieldConfig('first_name', 'First Name', OpportunityFieldType.text),
    _OpportunityFieldConfig('last_name', 'Last Name', OpportunityFieldType.text),
    _OpportunityFieldConfig('company_name', 'Company Name', OpportunityFieldType.text),
    _OpportunityFieldConfig('email_id', 'Email', OpportunityFieldType.email),
    _OpportunityFieldConfig('mobile_no', 'Mobile No', OpportunityFieldType.phone),
    _OpportunityFieldConfig('phone', 'Phone', OpportunityFieldType.phone),
    _OpportunityFieldConfig('website', 'Website', OpportunityFieldType.text),
    _OpportunityFieldConfig('status', 'Status', OpportunityFieldType.select),
    _OpportunityFieldConfig('source', 'Source', OpportunityFieldType.link),
    _OpportunityFieldConfig('territory', 'Territory', OpportunityFieldType.link),
    _OpportunityFieldConfig('short_address', 'Short Address', OpportunityFieldType.multiline),
    _OpportunityFieldConfig('city', 'City', OpportunityFieldType.text),
    _OpportunityFieldConfig('country', 'Country', OpportunityFieldType.link),
    _OpportunityFieldConfig('annual_revenue', 'Annual Revenue', OpportunityFieldType.number),
    _OpportunityFieldConfig('no_of_employees', 'No. of Employees', OpportunityFieldType.number),
    _OpportunityFieldConfig('notes', 'Notes', OpportunityFieldType.multiline),
  ];

  Timer? _requiredFieldsDebounce;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  String? _successMessage;
  String? _opportunityName;
  List<String> _requiredKeys = [];
  List<String> _missingKeys = [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  String? get successMessage => _successMessage;
  bool get isEdit => _opportunityName != null && _opportunityName!.isNotEmpty;
  List<String> get missingKeys => _missingKeys;

  List<OpportunityField> get fields {
    final fieldMap = <String, OpportunityField>{};
    for (final item in _catalog) {
      final definition = _definitions[item.key];
      fieldMap[item.key] = OpportunityField(
        key: item.key,
        label: definition?.label ?? item.label,
        type: definition?.fieldType ?? item.type,
        required: _requiredKeys.contains(item.key),
        value: _values[item.key] ?? '',
        options: definition?.options ?? item.options,
        linkDoctype: definition?.linkDoctype ?? item.linkDoctype,
      );
    }

    for (final key in _requiredKeys) {
      final definition = _definitions[key];
      fieldMap.putIfAbsent(
        key,
        () => OpportunityField(
          key: key,
          label: definition?.label ?? _labelFromKey(key),
          type: definition?.fieldType ?? _guessType(key),
          required: true,
          value: _values[key] ?? '',
          options: definition?.options ?? const [],
          linkDoctype: definition?.linkDoctype,
        ),
      );
    }

    for (final entry in _values.entries) {
      if (entry.value.trim().isEmpty) continue;
      final definition = _definitions[entry.key];
      fieldMap.putIfAbsent(
        entry.key,
        () => OpportunityField(
          key: entry.key,
          label: definition?.label ?? _labelFromKey(entry.key),
          type: definition?.fieldType ?? _guessType(entry.key),
          required: _requiredKeys.contains(entry.key),
          value: entry.value,
          options: definition?.options ?? const [],
          linkDoctype: definition?.linkDoctype,
        ),
      );
    }

    final list = fieldMap.values.toList();
    list.removeWhere((field) => isEdit && const {
      'id',
      'name',
      'doctype',
    }.contains(field.key));
    list.sort((a, b) {
      final ar = a.required ? 0 : 1;
      final br = b.required ? 0 : 1;
      if (ar != br) return ar.compareTo(br);
      return a.label.compareTo(b.label);
    });
    return list;
  }

  Future<void> initialize({
    String? opportunityName,
    Map<String, dynamic>? initialData,
  }) async {
    _opportunityName = opportunityName;
    _error = null;
    _successMessage = null;
    _requiredKeys = [];
    _missingKeys = [];
    _definitions.clear();
    _values.clear();

    if (initialData != null) {
      for (final entry in initialData.entries) {
        if (entry.value == null) continue;
        final value = entry.value.toString().trim();
        if (value.isEmpty) continue;
        _values[entry.key] = value;
      }
    }

    await refreshRequiredFields();
  }

  void updateValue(String key, String value) {
    _values[key] = value;
    _successMessage = null;
    notifyListeners();

    _requiredFieldsDebounce?.cancel();
    _requiredFieldsDebounce = Timer(
      const Duration(milliseconds: 350),
      refreshRequiredFields,
    );
  }

  Future<void> refreshRequiredFields() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.sales('refresh required fields values=${_sanitizedValues()}');
      final result = await _getOpportunityRequiredFieldsUseCase.call(_sanitizedValues());
      _requiredKeys = result.requiredFields;
      _missingKeys = result.missingFields;
      _definitions
        ..clear()
        ..addEntries(
          result.definitions.map((item) => MapEntry(item.fieldname, item)),
        );
      AppLogger.sales(
        'required fields resolved required=$_requiredKeys missing=$_missingKeys definitions=${_definitions.keys.toList()}',
      );
    } catch (e) {
      _error = e.toString();
      AppLogger.error('opportunity required fields failed: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<OpportunityOptionItem>> searchOptions(
    OpportunityField field, {
    String query = '',
  }) async {
    if (field.type == OpportunityFieldType.select) {
      final normalized = query.trim().toLowerCase();
      final items = field.options
          .where(
            (item) =>
                normalized.isEmpty || item.toLowerCase().contains(normalized),
          )
          .map((item) => OpportunityOptionItem(value: item, label: item))
          .toList();
      if (field.value.isNotEmpty &&
          items.every((item) => item.value != field.value)) {
        items.insert(0, OpportunityOptionItem(value: field.value, label: field.value));
      }
      return items;
    }

    if (field.type == OpportunityFieldType.link) {
      final doctype = field.linkDoctype;
      if (doctype == null || doctype.isEmpty) return const [];
      final items = await _searchOpportunityLinkOptionsUseCase.call(
        doctype: doctype,
        query: query,
      );
      if (field.value.isNotEmpty &&
          items.every((item) => item.value != field.value)) {
        return [
          OpportunityOptionItem(value: field.value, label: field.value),
          ...items,
        ];
      }
      return items;
    }

    return const [];
  }

  Future<bool> submit() async {
    _isSubmitting = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final payload = _sanitizedValues();
      AppLogger.sales('opportunity submit start isEdit=$isEdit payload=$payload');
      final result = await _getOpportunityRequiredFieldsUseCase.call(payload);
      _requiredKeys = result.requiredFields;
      _missingKeys = result.missingFields;
      _definitions
        ..clear()
        ..addEntries(
          result.definitions.map((item) => MapEntry(item.fieldname, item)),
        );

      if (_missingKeys.isNotEmpty) {
        _error = 'Please complete all required fields.';
        AppLogger.sales('opportunity submit blocked missing=$_missingKeys');
        return false;
      }

      if (isEdit) {
        await _updateOpportunityUseCase.call(_opportunityName!, payload);
        _successMessage = 'Opportunity updated successfully.';
        AppLogger.sales('opportunity update success opportunity_name=$_opportunityName');
      } else {
        final createdOpportunityName = await _createOpportunityUseCase.call(payload);
        _opportunityName = createdOpportunityName.isEmpty ? _opportunityName : createdOpportunityName;
        _successMessage = 'Opportunity created successfully.';
        AppLogger.sales('opportunity create success opportunity_name=$_opportunityName');
      }

      return true;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('opportunity submit failed: $_error');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _sanitizedValues() {
    final output = <String, dynamic>{};
    for (final entry in _values.entries) {
      final value = entry.value.trim();
      if (value.isNotEmpty) output[entry.key] = value;
    }
    return output;
  }

  OpportunityFieldType _guessType(String key) {
    for (final item in _catalog) {
      if (item.key == key) return item.type;
    }
    if (key.contains('date')) return OpportunityFieldType.date;
    if (key.contains('email')) return OpportunityFieldType.email;
    if (key.contains('mobile') || key.contains('phone')) return OpportunityFieldType.phone;
    if (key.contains('note') || key.contains('detail')) return OpportunityFieldType.multiline;
    return OpportunityFieldType.text;
  }

  String _labelFromKey(String key) {
    return key
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  @override
  void dispose() {
    _requiredFieldsDebounce?.cancel();
    super.dispose();
  }
}

class _OpportunityFieldConfig {
  final String key;
  final String label;
  final OpportunityFieldType type;
  final List<String> options;
  final String? linkDoctype;

  const _OpportunityFieldConfig(
    this.key,
    this.label,
    this.type, {
    this.options = const [],
    this.linkDoctype,
  });
}
