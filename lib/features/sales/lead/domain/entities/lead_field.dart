enum LeadFieldType {
  text,
  multiline,
  email,
  phone,
  number,
  date,
  select,
  link,
}

class LeadField {
  final String key;
  final String label;
  final LeadFieldType type;
  final bool required;
  final String value;
  final List<String> options;
  final String? linkDoctype;

  const LeadField({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
    required this.value,
    this.options = const [],
    this.linkDoctype,
  });

  bool get isSelectable => type == LeadFieldType.select || type == LeadFieldType.link;

  LeadField copyWith({
    String? key,
    String? label,
    LeadFieldType? type,
    bool? required,
    String? value,
    List<String>? options,
    String? linkDoctype,
  }) {
    return LeadField(
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
