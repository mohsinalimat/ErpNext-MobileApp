enum OpportunityFieldType {
  text,
  multiline,
  email,
  phone,
  number,
  date,
  select,
  link,
  dynamicLink,
}

class OpportunityField {
  final String key;
  final String label;
  final OpportunityFieldType type;
  final bool required;
  final bool readOnly;
  final bool hidden;
  final String value;
  final List<String> options;
  final String? linkDoctype;
  final String? linkDoctypeField;

  const OpportunityField({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
    this.readOnly = false,
    this.hidden = false,
    required this.value,
    this.options = const [],
    this.linkDoctype,
    this.linkDoctypeField,
  });

  bool get isSelectable =>
      type == OpportunityFieldType.select ||
      type == OpportunityFieldType.link ||
      type == OpportunityFieldType.dynamicLink;

  OpportunityField copyWith({
    String? key,
    String? label,
    OpportunityFieldType? type,
    bool? required,
    bool? readOnly,
    bool? hidden,
    String? value,
    List<String>? options,
    String? linkDoctype,
    String? linkDoctypeField,
  }) {
    return OpportunityField(
      key: key ?? this.key,
      label: label ?? this.label,
      type: type ?? this.type,
      required: required ?? this.required,
      readOnly: readOnly ?? this.readOnly,
      hidden: hidden ?? this.hidden,
      value: value ?? this.value,
      options: options ?? this.options,
      linkDoctype: linkDoctype ?? this.linkDoctype,
      linkDoctypeField: linkDoctypeField ?? this.linkDoctypeField,
    );
  }
}
