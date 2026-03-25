import 'lead_required_field_definition.dart';

class LeadRequiredFieldsResult {
  final List<String> requiredFields;
  final List<String> missingFields;
  final List<LeadRequiredFieldDefinition> definitions;

  const LeadRequiredFieldsResult({
    required this.requiredFields,
    required this.missingFields,
    this.definitions = const [],
  });
}
