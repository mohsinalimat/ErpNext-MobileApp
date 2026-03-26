import '../../domain/entities/opportunity_field.dart';
import '../../domain/entities/opportunity_required_field_definition.dart';
import '../../domain/entities/opportunity_required_fields_result.dart';

class OpportunityRequiredFieldsResultModel
    extends OpportunityRequiredFieldsResult {
  const OpportunityRequiredFieldsResultModel({
    required super.requiredFields,
    required super.missingFields,
    required super.definitions,
    required super.defaultValues,
  });

  factory OpportunityRequiredFieldsResultModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final payload = _extractPayload(json);
    final requiredDefinitions = _readDefinitions(payload['required_fields']);
    final formDefinitions = _readDefinitions(payload['form_fields']);
    final definitions = <String, OpportunityRequiredFieldDefinition>{};

    for (final item in [...formDefinitions, ...requiredDefinitions]) {
      definitions[item.fieldname] = item;
    }

    return OpportunityRequiredFieldsResultModel(
      requiredFields: [
        ...requiredDefinitions.map((item) => item.fieldname),
        ...formDefinitions.where((item) => item.required).map((item) => item.fieldname),
      ].where((item) => item.isNotEmpty).toSet().toList(),
      missingFields: _readStringList(payload['missing_fields']),
      definitions: definitions.values.toList(),
      defaultValues: _readStringMap(payload['default_values']),
    );
  }

  static Map<String, dynamic> _extractPayload(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;

    final message = json['message'];
    if (message is Map<String, dynamic>) return message;

    return json;
  }

  static Map<String, String> _readStringMap(dynamic value) {
    if (value is! Map<String, dynamic>) return const {};
    final result = <String, String>{};
    for (final entry in value.entries) {
      final text = entry.value?.toString().trim() ?? '';
      if (text.isNotEmpty) result[entry.key] = text;
    }
    return result;
  }

  static List<OpportunityRequiredFieldDefinition> _readDefinitions(dynamic value) {
    if (value is! List) return const [];

    return value.map((item) {
      if (item is String) {
        return OpportunityRequiredFieldDefinition(
          fieldname: item,
          label: _labelFromKey(item),
          fieldType: OpportunityFieldType.text,
          required: true,
        );
      }

      if (item is! Map<String, dynamic>) {
        final text = item?.toString() ?? '';
        return OpportunityRequiredFieldDefinition(
          fieldname: text,
          label: _labelFromKey(text),
          fieldType: OpportunityFieldType.text,
        );
      }

      final fieldname = item['fieldname']?.toString() ??
          item['field_name']?.toString() ??
          item['name']?.toString() ??
          '';
      final label = item['label']?.toString() ?? _labelFromKey(fieldname);
      final rawOptions = item['options'];
      final fieldType = _mapFieldType(item['fieldtype']?.toString(), rawOptions);

      return OpportunityRequiredFieldDefinition(
        fieldname: fieldname,
        label: label,
        fieldType: fieldType,
        required: _toBool(item['required'] ?? item['reqd']),
        readOnly: _toBool(item['read_only']),
        hidden: _toBool(item['hidden']),
        value: item['value']?.toString() ?? '',
        options: _readOptions(rawOptions, fieldType),
        linkDoctype: item['link_doctype']?.toString() ??
            ((fieldType == OpportunityFieldType.link ||
                        fieldType == OpportunityFieldType.dynamicLink) &&
                    rawOptions != null
                ? rawOptions.toString()
                : null),
        linkDoctypeField: item['link_doctype_field']?.toString(),
      );
    }).where((item) => item.fieldname.isNotEmpty).toList();
  }

  static OpportunityFieldType _mapFieldType(
    String? fieldType,
    dynamic rawOptions,
  ) {
    final normalized = (fieldType ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'select':
        return OpportunityFieldType.select;
      case 'link':
        return OpportunityFieldType.link;
      case 'dynamic link':
        return OpportunityFieldType.dynamicLink;
      case 'small text':
      case 'text':
      case 'long text':
      case 'text editor':
        return OpportunityFieldType.multiline;
      case 'data':
        return OpportunityFieldType.text;
      case 'date':
        return OpportunityFieldType.date;
      case 'int':
      case 'float':
      case 'currency':
      case 'percent':
        return OpportunityFieldType.number;
      case 'phone':
        return OpportunityFieldType.phone;
      case 'email':
        return OpportunityFieldType.email;
      default:
        if (rawOptions is String && rawOptions.contains('\n')) {
          return OpportunityFieldType.select;
        }
        return OpportunityFieldType.text;
    }
  }

  static List<String> _readOptions(
    dynamic rawOptions,
    OpportunityFieldType fieldType,
  ) {
    if (fieldType == OpportunityFieldType.select) {
      if (rawOptions is String) {
        return rawOptions
            .split('\n')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
      if (rawOptions is List) {
        return rawOptions
            .map((item) {
              if (item is Map<String, dynamic>) {
                return item['value']?.toString() ??
                    item['label']?.toString() ??
                    '';
              }
              return item?.toString() ?? '';
            })
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }

    if (rawOptions is List) {
      return rawOptions
          .map((item) {
            if (item is Map<String, dynamic>) {
              return item['value']?.toString() ??
                  item['label']?.toString() ??
                  '';
            }
            return item?.toString() ?? '';
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map(_normalizeFieldName).where((item) => item.isNotEmpty).toSet().toList();
  }

  static String _normalizeFieldName(dynamic item) {
    if (item is String) return item;
    if (item is Map<String, dynamic>) {
      return item['fieldname']?.toString() ??
          item['field_name']?.toString() ??
          item['name']?.toString() ??
          '';
    }
    return item?.toString() ?? '';
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().toLowerCase() ?? '';
    return text == '1' || text == 'true' || text == 'yes';
  }

  static String _labelFromKey(String key) {
    return key
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
