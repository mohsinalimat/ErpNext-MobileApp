import 'opportunity_required_field_definition.dart';

class OpportunityRequiredFieldsResult {
  final List<String> requiredFields;
  final List<String> missingFields;
  final List<OpportunityRequiredFieldDefinition> definitions;
  final Map<String, String> defaultValues;

  const OpportunityRequiredFieldsResult({
    required this.requiredFields,
    required this.missingFields,
    this.definitions = const [],
    this.defaultValues = const {},
  });
}
