enum OpportunityFieldType {
  text,
  multiline,
  email,
  phone,
  number,
  date,
  select,
  link,
}

class OpportunityField {
  final String key;
  final String label;
  final OpportunityFieldType type;
  final bool required;
  final String value;
  final List<String> options;
  final String? linkDoctype;

  const OpportunityField({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
    required this.value,
    this.options = const [],
    this.linkDoctype,
  });

  bool get isSelectable => type == OpportunityFieldType.select || type == OpportunityFieldType.link;

  OpportunityField copyWith({
    String? key,
    String? label,
    OpportunityFieldType? type,
    bool? required,
    String? value,
    List<String>? options,
    String? linkDoctype,
  }) {
    return OpportunityField(
      key: key ?? this.key,
      label: label ?? this.label,
      type: type ?? this.type,
      required: required ?? this.required,
      value: value ?? this.value,
      options: options ?? this.options,
      linkDoctype: linkDoctype ?? this.linkDoctype,
    );
  }
}
