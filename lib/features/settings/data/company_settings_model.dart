class CompanySettings {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final String ticketFooter;
  final String ticketFormat;

  const CompanySettings({
    required this.id,
    this.name = 'ShoeTrak',
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.ticketFooter = 'Merci pour votre achat!',
    this.ticketFormat = '80mm',
  });

  factory CompanySettings.fromMap(Map<String, dynamic> map) {
    return CompanySettings(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'ShoeTrak',
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      logoUrl: map['logo_url'] as String?,
      ticketFooter: map['ticket_footer'] as String? ?? 'Merci pour votre achat!',
      ticketFormat: map['ticket_format'] as String? ?? '80mm',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'logo_url': logoUrl,
      'ticket_footer': ticketFooter,
      'ticket_format': ticketFormat,
    };
  }

  CompanySettings copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? logoUrl,
    String? ticketFooter,
    String? ticketFormat,
  }) {
    return CompanySettings(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      ticketFooter: ticketFooter ?? this.ticketFooter,
      ticketFormat: ticketFormat ?? this.ticketFormat,
    );
  }
}
