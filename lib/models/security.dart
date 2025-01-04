class Security {
  final int securityId;
  final String isinCode;
  final String secName;
  final String securityType;
  final String securitySubtype;
  final String basisCode;
  final String tickerSymbol;
  final int minQty;
  final double price;
  final double cpRate;
  final DateTime issueDate;
  final DateTime maturityDate;
  final int countryId;
  final int ratingId;
  final String createdBy;
  final String modifiedBy;
  final DateTime createdDate;
  final DateTime modifiedDate;

  Security({
    required this.securityId,
    required this.isinCode,
    required this.secName,
    required this.securityType,
    required this.securitySubtype,
    required this.basisCode,
    required this.tickerSymbol,
    required this.minQty,
    required this.price,
    required this.cpRate,
    required this.issueDate,
    required this.maturityDate,
    required this.countryId,
    required this.ratingId,
    required this.createdBy,
    required this.modifiedBy,
    required this.createdDate,
    required this.modifiedDate,
  });

  factory Security.fromJson(Map<String, dynamic> json) {
    return Security(
      securityId: json['security_id'],
      isinCode: json['isin_code'],
      secName: json['sec_name'],
      securityType: json['security_type'],
      securitySubtype: json['security_subtype'],
      basisCode: json['basis_code'],
      tickerSymbol: json['ticker_symbol'],
      minQty: json['min_qty'],
      price: json['price'],
      cpRate: json['cp_rate'],
      issueDate: DateTime.parse(json['issue_date']),
      maturityDate: DateTime.parse(json['maturity_date']),
      countryId: json['country_id'],
      ratingId: json['rating_id'],
      createdBy: json['created_by'],
      modifiedBy: json['modified_by'],
      createdDate: DateTime.parse(json['created_date']),
      modifiedDate: DateTime.parse(json['modified_date']),
    );
  }
}
