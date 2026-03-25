import 'lead_field.dart';

class LeadRequiredFieldDefinition {
  final String fieldname;
  final String label;
  final LeadFieldType fieldType;
  final List<String> options;
  final String? linkDoctype;

  const LeadRequiredFieldDefinition({
    required this.fieldname,
    required this.label,
    required this.fieldType,
    this.options = const [],
    this.linkDoctype,
  });
}
