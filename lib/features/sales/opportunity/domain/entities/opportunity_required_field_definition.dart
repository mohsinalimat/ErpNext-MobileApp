import 'opportunity_field.dart';

class OpportunityRequiredFieldDefinition {
  final String fieldname;
  final String label;
  final OpportunityFieldType fieldType;
  final bool required;
  final bool readOnly;
  final bool hidden;
  final String value;
  final List<String> options;
  final String? linkDoctype;
  final String? linkDoctypeField;

  const OpportunityRequiredFieldDefinition({
    required this.fieldname,
    required this.label,
    required this.fieldType,
    this.required = false,
    this.readOnly = false,
    this.hidden = false,
    this.value = '',
    this.options = const [],
    this.linkDoctype,
    this.linkDoctypeField,
  });
}
