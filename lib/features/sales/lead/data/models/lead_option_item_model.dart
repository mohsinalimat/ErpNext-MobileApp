import '../../domain/entities/lead_option_item.dart';

class LeadOptionItemModel extends LeadOptionItem {
  const LeadOptionItemModel({
    required super.value,
    required super.label,
    super.description,
  });

  factory LeadOptionItemModel.fromDynamic(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final value = raw['value']?.toString() ??
          raw['name']?.toString() ??
          raw['label']?.toString() ??
          '';
      return LeadOptionItemModel(
        value: value,
        label: raw['label']?.toString() ?? value,
        description: raw['description']?.toString() ?? '',
      );
    }

    if (raw is List && raw.isNotEmpty) {
      final value = raw.first?.toString() ?? '';
      final description = raw.length > 1 ? raw[1]?.toString() ?? '' : '';
      return LeadOptionItemModel(
        value: value,
        label: value,
        description: description,
      );
    }

    final text = raw?.toString() ?? '';
    return LeadOptionItemModel(value: text, label: text);
  }
}
