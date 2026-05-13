/* class CustomerModel {

  // =========================
  // BASE
  // =========================
  final String? id;
  final String? title;
  final String? code;
  final String? businessType; // "company" | "physical_person"

// =========================
// CAMPI FLAT (USATI DALLA UI)
// =========================
  final String? vatNumber;
  final String? address;
  final String? zipCode;
  final String? city;
  final String? phone;
  final String? email;


  // =========================
  // AZIENDA
  // =========================
  final String? businessName;
  final String? businessVatNumber;
  final String? businessFiscalCode;
  final String? businessAddress;
  final String? businessCity;
  final String? businessZipCode;
  final String? businessPhone;
  final String? businessEmail;

  // =========================
  // PRIVATO
  // =========================
  final String? personalFirstName;
  final String? personalLastName;
  final String? personalFiscalCode;
  final String? personalAddress;
  final String? personalCity;
  final String? personalZipCode;
  final String? personalPhone;
  final String? personalEmail;

  CustomerModel({
    this.id,
    this.title,
    this.code,
    this.businessType,

    // flat
    this.vatNumber,
    this.address,
    this.zipCode,
    this.city,
    this.phone,
    this.email,

    // azienda
    this.businessName,
    this.businessVatNumber,
    this.businessFiscalCode,
    this.businessAddress,
    this.businessCity,
    this.businessZipCode,
    this.businessPhone,
    this.businessEmail,

    // privato
    this.personalFirstName,
    this.personalLastName,
    this.personalFiscalCode,
    this.personalAddress,
    this.personalCity,
    this.personalZipCode,
    this.personalPhone,
    this.personalEmail,
  });

  // ============================================================
  // FROM JSON
  // - supporta:
  //   1) API → json.detail
  //   2) Checkout salvato → json flat
  // ============================================================
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    final detail = json["detail"] as Map<String, dynamic>?;

    // se arriva da API uso detail, altrimenti uso json flat
    final Map<String, dynamic> d = detail ?? json;

    final bool isCompany = json["businessType"] == "company";

    return CustomerModel(
      id: json["id"]?.toString(),
      title: json["title"],
      code: json["code"],
      businessType: json["businessType"],

      // =========================
      // FLAT (UI)
      // =========================
      vatNumber: isCompany
          ? d["businessVatNumber"]
          : d["personalFiscalCode"],

      address: isCompany
          ? d["businessAddress"]
          : d["personalAddress"],

      zipCode: isCompany
          ? d["businessZipCode"]
          : d["personalZipCode"],

      city: isCompany
          ? d["businessCity"]
          : d["personalCity"],

      phone: isCompany
          ? d["businessPhone"]
          : d["personalPhone"],

      email: isCompany
          ? d["businessEmail"]
          : d["personalEmail"],

      // =========================
      // AZIENDA
      // =========================
      businessName: d["businessName"],
      businessVatNumber: d["businessVatNumber"],
      businessFiscalCode: d["businessFiscalCode"],
      businessAddress: d["businessAddress"],
      businessCity: d["businessCity"],
      businessZipCode: d["businessZipCode"],
      businessPhone: d["businessPhone"],
      businessEmail: d["businessEmail"],

      // =========================
      // PRIVATO
      // =========================
      personalFirstName: d["personalFirstName"],
      personalLastName: d["personalLastName"],
      personalFiscalCode: d["personalFiscalCode"],
      personalAddress: d["personalAddress"],
      personalCity: d["personalCity"],
      personalZipCode: d["personalZipCode"],
      personalPhone: d["personalPhone"],
      personalEmail: d["personalEmail"],
    );
  }

  // ============================================================
  // TO JSON
  // - usato per salvare checkout / vendita sospesa
  // ============================================================
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "code": code,
      "businessType": businessType,

      // AZIENDA
      "businessName": businessName,
      "businessVatNumber": businessVatNumber,
      "businessFiscalCode": businessFiscalCode,
      "businessAddress": businessAddress,
      "businessCity": businessCity,
      "businessZipCode": businessZipCode,
      "businessPhone": businessPhone,
      "businessEmail": businessEmail,

      // PRIVATO
      "personalFirstName": personalFirstName,
      "personalLastName": personalLastName,
      "personalFiscalCode": personalFiscalCode,
      "personalAddress": personalAddress,
      "personalCity": personalCity,
      "personalZipCode": personalZipCode,
      "personalPhone": personalPhone,
      "personalEmail": personalEmail,
    };



  }



}

extension CustomerModelUI on CustomerModel {

  /// azienda o privato
  bool get isCompany => businessType == "company";

  /// Nome principale da mostrare
  String get displayName {
    if (isCompany) {
      if (businessName != null && businessName!.isNotEmpty) {
        return businessName!;
      }
    }

    final parts = [
      personalFirstName,
      personalLastName,
    ].where((e) => e != null && e.isNotEmpty).toList();

    if (parts.isNotEmpty) {
      return parts.join(' ');
    }

    return title ?? code ?? "Cliente";
  }

  /// Riga secondaria (P.IVA / CF / città)
  String get subtitle {
    if (isCompany) {
      final parts = [
        businessVatNumber,
        businessCity,
      ].where((e) => e != null && e.isNotEmpty).toList();

      return parts.join(" • ");
    }

    final parts = [
      personalFiscalCode,
      personalCity,
    ].where((e) => e != null && e.isNotEmpty).toList();

    return parts.join(" • ");
  }
}


extension CustomerModelContact on CustomerModel {

  ///  Telefono principale (azienda o privato)
  String get mainPhone {
    if (isCompany) {
      return businessPhone ?? '';
    }
    return personalPhone ?? '';
  }

  /// Indirizzo principale
  String get mainAddress {
    if (isCompany) {
      return businessAddress ?? '';
    }
    return personalAddress ?? '';
  }

  ///  Città
  String get mainCity {
    if (isCompany) {
      return businessCity ?? '';
    }
    return personalCity ?? '';
  }

  /// CAP
  String get mainZipCode {
    if (isCompany) {
      return businessZipCode ?? '';
    }
    return personalZipCode ?? '';
  }
}
 */