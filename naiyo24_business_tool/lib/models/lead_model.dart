class LeadModel {
  const LeadModel({
    required this.id,
    required this.name,
    required this.status,
    this.email,
    this.phone,
    this.company,
    this.notes,
    this.source,
    this.convertedToCustomerId,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? company;
  final LeadStatus status;
  final String? notes;
  final String? source;
  final int? convertedToCustomerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LeadModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    LeadStatus? status,
    String? notes,
    String? source,
    int? convertedToCustomerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeadModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      convertedToCustomerId: convertedToCustomerId ?? this.convertedToCustomerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'company': company,
        'status': status.name,
        'notes': notes,
        'source': source,
        'converted_to_customer_id': convertedToCustomerId,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      company: json['company'] as String?,
      status: LeadStatus.fromString(json['status'] as String? ?? 'new'),
      notes: json['notes'] as String?,
      source: json['source'] as String?,
      convertedToCustomerId: json['converted_to_customer_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LeadModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'LeadModel($name, $status)';
}

enum LeadStatus {
  newLead('new', 'New'),
  contacted('contacted', 'Contacted'),
  qualified('qualified', 'Qualified'),
  converted('converted', 'Converted'),
  lost('lost', 'Lost');

  const LeadStatus(this.value, this.label);
  final String value;
  final String label;

  static LeadStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'contacted':
        return LeadStatus.contacted;
      case 'qualified':
        return LeadStatus.qualified;
      case 'converted':
        return LeadStatus.converted;
      case 'lost':
        return LeadStatus.lost;
      default:
        return LeadStatus.newLead;
    }
  }
}
