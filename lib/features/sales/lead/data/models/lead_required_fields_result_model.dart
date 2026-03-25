import '../../domain/entities/lead_field.dart';
import '../../domain/entities/lead_required_field_definition.dart';
import '../../domain/entities/lead_required_fields_result.dart';

class LeadRequiredFieldsResultModel extends LeadRequiredFieldsResult {
  const LeadRequiredFieldsResultModel({
    required super.requiredFields,
    required super.missingFields,
    required super.definitions,
  });

  factory LeadRequiredFieldsResultModel.fromJson(Map<String, dynamic> json) {
    final payload = _extractPayload(json);
    final definitions = _readDefinitions(payload['required_fields']);

    return LeadRequiredFieldsResultModel(
      requiredFields: definitions
          .map((item) => item.fieldname)
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(),
      missingFields: _readStringList(payload['missing_fields']),
      definitions: definitions,
    );
  }

  static Map<String, dynamic> _extractPayload(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;

    final message = json['message'];
    if (message is Map<String, dynamic>) return message;

    return json;
  }

  static List<LeadRequiredFieldDefinition> _readDefinitions(dynamic value) {
    if (value is! List) return const [];

    return value.map((item) {
      if (item is String) {
        return LeadRequiredFieldDefinition(
          fieldname: item,
          label: _labelFromKey(item),
          fieldType: _mapFieldType(null, null),
        );
      }

      if (item is Map<String, dynamic>) {
        final fieldname = item['fieldname']?.toString() ??
            item['field_name']?.toString() ??
            item['name']?.toString() ??
            '';
        final label = item['label']?.toString() ?? _labelFromKey(fieldname);
        final rawOptions = item['options'];
        final fieldTypeText = item['fieldtype']?.toString();
        final fieldType = _mapFieldType(fieldTypeText, rawOptions);

        return LeadRequiredFieldDefinition(
          fieldname: fieldname,
          label: label,
          fieldType: fieldType,
          options: _readOptions(rawOptions, fieldType),
          linkDoctype: fieldType == LeadFieldType.link
              ? rawOptions?.toString()
              : null,
        );
      }

      final text = item?.toString() ?? '';
      return LeadRequiredFieldDefinition(
        fieldname: text,
        label: _labelFromKey(text),
        fieldType: _mapFieldType(null, null),
      );
    }).where((item) => item.fieldname.isNotEmpty).toList();
  }

  static LeadFieldType _mapFieldType(String? fieldType, dynamic rawOptions) {
    final normalized = (fieldType ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'select':
        return LeadFieldType.select;
      case 'link':
        return LeadFieldType.link;
      case 'small text':
      case 'text':
      case 'long text':
      case 'text editor':
        return LeadFieldType.multiline;
      case 'data':
        return LeadFieldType.text;
      case 'date':
        return LeadFieldType.date;
      case 'int':
      case 'float':
      case 'currency':
        return LeadFieldType.number;
      case 'phone':
        return LeadFieldType.phone;
      case 'email':
        return LeadFieldType.email;
      default:
        if (rawOptions is String && rawOptions.contains('\n')) {
          return LeadFieldType.select;
        }
        return LeadFieldType.text;
    }
  }

  static List<String> _readOptions(dynamic rawOptions, LeadFieldType fieldType) {
    if (fieldType != LeadFieldType.select) return const [];

    final text = rawOptions?.toString() ?? '';
    if (text.isEmpty) return const [];

    return text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value
          .map(_normalizeFieldName)
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
    }
    return const [];
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

  static String _labelFromKey(String key) {
    return key
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
