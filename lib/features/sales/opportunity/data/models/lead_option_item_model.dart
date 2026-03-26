import '../../domain/entities/opportunity_option_item.dart';

class OpportunityOptionItemModel extends OpportunityOptionItem {
  const OpportunityOptionItemModel({
    required super.value,
    required super.label,
    super.description,
  });

  factory OpportunityOptionItemModel.fromDynamic(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final value = raw['value']?.toString() ??
          raw['name']?.toString() ??
          raw['label']?.toString() ??
          '';
      return OpportunityOptionItemModel(
        value: value,
        label: raw['label']?.toString() ?? value,
        description: raw['description']?.toString() ?? '',
      );
    }

    if (raw is List && raw.isNotEmpty) {
      final value = raw.first?.toString() ?? '';
      final description = raw.length > 1 ? raw[1]?.toString() ?? '' : '';
      return OpportunityOptionItemModel(
        value: value,
        label: value,
        description: description,
      );
    }

    final text = raw?.toString() ?? '';
    return OpportunityOptionItemModel(value: text, label: text);
  }
}
