class CustomerDetailModel {
  // AZIENDA
  final String? businessName;
  final String? businessVatNumber;
  final String? businessFiscalCode;
  final String? businessAddress;
  final String? businessCity;
  final String? businessZipCode;
  final String? businessPhone;
  final String? businessEmail;

  // PRIVATO
  final String? personalFirstName;
  final String? personalLastName;
  final String? personalFiscalCode;
  final String? personalAddress;
  final String? personalCity;
  final String? personalZipCode;
  final String? personalPhone;
  final String? personalEmail;

  CustomerDetailModel({
    this.businessName,
    this.businessVatNumber,
    this.businessFiscalCode,
    this.businessAddress,
    this.businessCity,
    this.businessZipCode,
    this.businessPhone,
    this.businessEmail,
    this.personalFirstName,
    this.personalLastName,
    this.personalFiscalCode,
    this.personalAddress,
    this.personalCity,
    this.personalZipCode,
    this.personalPhone,
    this.personalEmail,
  });

  factory CustomerDetailModel.fromJson(Map<String, dynamic> json) {
    return CustomerDetailModel(
      businessName: json["businessName"],
      businessVatNumber: json["businessVatNumber"],
      businessFiscalCode: json["businessFiscalCode"],
      businessAddress: json["businessAddress"],
      businessCity: json["businessCity"],
      businessZipCode: json["businessZipCode"],
      businessPhone: json["businessPhone"],
      businessEmail: json["businessEmail"],

      personalFirstName: json["personalFirstName"],
      personalLastName: json["personalLastName"],
      personalFiscalCode: json["personalFiscalCode"],
      personalAddress: json["personalAddress"],
      personalCity: json["personalCity"],
      personalZipCode: json["personalZipCode"],
      personalPhone: json["personalPhone"],
      personalEmail: json["personalEmail"],
    );
  }
}
