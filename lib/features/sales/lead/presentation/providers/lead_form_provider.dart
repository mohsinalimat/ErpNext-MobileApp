import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/utils/app_logger.dart';
import '../../domain/entities/lead_field.dart';
import '../../domain/entities/lead_option_item.dart';
import '../../domain/entities/lead_required_field_definition.dart';
import '../../domain/usecases/create_lead_usecase.dart';
import '../../domain/usecases/get_lead_required_fields_usecase.dart';
import '../../domain/usecases/search_lead_link_options_usecase.dart';
import '../../domain/usecases/update_lead_usecase.dart';

class LeadFormProvider extends ChangeNotifier {
  LeadFormProvider(
    this._getLeadRequiredFieldsUseCase,
    this._createLeadUseCase,
    this._updateLeadUseCase,
    this._searchLeadLinkOptionsUseCase,
  );

  final GetLeadRequiredFieldsUseCase _getLeadRequiredFieldsUseCase;
  final CreateLeadUseCase _createLeadUseCase;
  final UpdateLeadUseCase _updateLeadUseCase;
  final SearchLeadLinkOptionsUseCase _searchLeadLinkOptionsUseCase;

  final Map<String, String> _values = {};
  final Map<String, LeadRequiredFieldDefinition> _definitions = {};
  final List<_LeadFieldConfig> _catalog = const [
    _LeadFieldConfig('department', 'Department', LeadFieldType.link),
    _LeadFieldConfig(
      'custom_customer_type',
      'Customer Type',
      LeadFieldType.select,
    ),
    _LeadFieldConfig('first_name', 'First Name', LeadFieldType.text),
    _LeadFieldConfig('last_name', 'Last Name', LeadFieldType.text),
    _LeadFieldConfig('company_name', 'Company Name', LeadFieldType.text),
    _LeadFieldConfig('email_id', 'Email', LeadFieldType.email),
    _LeadFieldConfig('mobile_no', 'Mobile No', LeadFieldType.phone),
    _LeadFieldConfig('phone', 'Phone', LeadFieldType.phone),
    _LeadFieldConfig('website', 'Website', LeadFieldType.text),
    _LeadFieldConfig('status', 'Status', LeadFieldType.select),
    _LeadFieldConfig('source', 'Source', LeadFieldType.link),
    _LeadFieldConfig('territory', 'Territory', LeadFieldType.link),
    _LeadFieldConfig('short_address', 'Short Address', LeadFieldType.multiline),
    _LeadFieldConfig('city', 'City', LeadFieldType.text),
    _LeadFieldConfig('country', 'Country', LeadFieldType.link),
    _LeadFieldConfig('annual_revenue', 'Annual Revenue', LeadFieldType.number),
    _LeadFieldConfig('no_of_employees', 'No. of Employees', LeadFieldType.number),
    _LeadFieldConfig('notes', 'Notes', LeadFieldType.multiline),
  ];

  Timer? _requiredFieldsDebounce;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  String? _successMessage;
  String? _leadName;
  List<String> _requiredKeys = [];
  List<String> _missingKeys = [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  String? get successMessage => _successMessage;
  bool get isEdit => _leadName != null && _leadName!.isNotEmpty;
  List<String> get missingKeys => _missingKeys;

  List<LeadField> get fields {
    final fieldMap = <String, LeadField>{};
    for (final item in _catalog) {
      final definition = _definitions[item.key];
      fieldMap[item.key] = LeadField(
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
        () => LeadField(
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
        () => LeadField(
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
    String? leadName,
    Map<String, dynamic>? initialData,
  }) async {
    _leadName = leadName;
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
      final result = await _getLeadRequiredFieldsUseCase.call(_sanitizedValues());
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
      AppLogger.error('lead required fields failed: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<LeadOptionItem>> searchOptions(
    LeadField field, {
    String query = '',
  }) async {
    if (field.type == LeadFieldType.select) {
      final normalized = query.trim().toLowerCase();
      final items = field.options
          .where(
            (item) =>
                normalized.isEmpty || item.toLowerCase().contains(normalized),
          )
          .map((item) => LeadOptionItem(value: item, label: item))
          .toList();
      if (field.value.isNotEmpty &&
          items.every((item) => item.value != field.value)) {
        items.insert(0, LeadOptionItem(value: field.value, label: field.value));
      }
      return items;
    }

    if (field.type == LeadFieldType.link) {
      final doctype = field.linkDoctype;
      if (doctype == null || doctype.isEmpty) return const [];
      final items = await _searchLeadLinkOptionsUseCase.call(
        doctype: doctype,
        query: query,
      );
      if (field.value.isNotEmpty &&
          items.every((item) => item.value != field.value)) {
        return [
          LeadOptionItem(value: field.value, label: field.value),
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
      AppLogger.sales('lead submit start isEdit=$isEdit payload=$payload');
      final result = await _getLeadRequiredFieldsUseCase.call(payload);
      _requiredKeys = result.requiredFields;
      _missingKeys = result.missingFields;
      _definitions
        ..clear()
        ..addEntries(
          result.definitions.map((item) => MapEntry(item.fieldname, item)),
        );

      if (_missingKeys.isNotEmpty) {
        _error = 'Please complete all required fields.';
        AppLogger.sales('lead submit blocked missing=$_missingKeys');
        return false;
      }

      if (isEdit) {
        await _updateLeadUseCase.call(_leadName!, payload);
        _successMessage = 'Lead updated successfully.';
        AppLogger.sales('lead update success lead_name=$_leadName');
      } else {
        final createdLeadName = await _createLeadUseCase.call(payload);
        _leadName = createdLeadName.isEmpty ? _leadName : createdLeadName;
        _successMessage = 'Lead created successfully.';
        AppLogger.sales('lead create success lead_name=$_leadName');
      }

      return true;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('lead submit failed: $_error');
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

  LeadFieldType _guessType(String key) {
    for (final item in _catalog) {
      if (item.key == key) return item.type;
    }
    if (key.contains('date')) return LeadFieldType.date;
    if (key.contains('email')) return LeadFieldType.email;
    if (key.contains('mobile') || key.contains('phone')) return LeadFieldType.phone;
    if (key.contains('note') || key.contains('detail')) return LeadFieldType.multiline;
    return LeadFieldType.text;
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

class _LeadFieldConfig {
  final String key;
  final String label;
  final LeadFieldType type;
  final List<String> options;
  final String? linkDoctype;

  const _LeadFieldConfig(
    this.key,
    this.label,
    this.type, {
    this.options = const [],
    this.linkDoctype,
  });
}
