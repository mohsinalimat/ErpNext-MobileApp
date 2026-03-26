import 'opportunity_field.dart';

class OpportunityRequiredFieldDefinition {
  final String fieldname;
  final String label;
  final OpportunityFieldType fieldType;
  final List<String> options;
  final String? linkDoctype;

  const OpportunityRequiredFieldDefinition({
    required this.fieldname,
    required this.label,
    required this.fieldType,
    this.options = const [],
    this.linkDoctype,
  });
}
