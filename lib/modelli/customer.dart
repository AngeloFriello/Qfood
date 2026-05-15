import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/cupertino.dart';

class CustomerModel {
  final int id;
  final String? code;
  final String? title;
  final String? denominationType;
  final String? businessType;
  final int? idCustomerGroup;
  final String? discountPercentage;
  final String? mandatorySdiPec;
  final int? generic;
  final int? promotional;
  final int? autocosume;
  final String? personalFirstname;
  final String? personalLastname;
  final String? personalFiscalCode;
  final String? personalAddress;
  final String? personalCity;
  final String? personalZipCode;
  final String? personalProvince;
  final String? personalCountry;
  final String? personalPhone;
  final String? personalFax;
  final String? personalEmail;
  final String? businessName;
  final String? businessVatNumber;
  final String? businessFiscalCode;
  final String? businessAddress;
  final String? businessZipCode;
  final String? businessCity;
  final String? businessProvince;
  final String? businessCountry;
  final String? businessPhone;
  final String? businessFax;
  final String? businessEmail;
  final String? businessPaymentMethod;
  final String? businessPaymentCondition;
  final String? businessSdiCode;
  final String? businessPec;
  final String? businessAdministrativeReference;
  final int? businessGetPurchaseOrderData;
  final int? enabled;
  final int? trashed;
  final String? lastSync;

  CustomerModel({
    required this.id,
    this.code,
    this.title,
    this.denominationType,
    this.businessType,
    this.idCustomerGroup,
    this.discountPercentage,
    this.mandatorySdiPec,
    this.generic,
    this.promotional,
    this.autocosume,
    this.personalFirstname,
    this.personalLastname,
    this.personalFiscalCode,
    this.personalAddress,
    this.personalCity,
    this.personalZipCode,
    this.personalProvince,
    this.personalCountry,
    this.personalPhone,
    this.personalFax,
    this.personalEmail,
    this.businessName,
    this.businessVatNumber,
    this.businessFiscalCode,
    this.businessAddress,
    this.businessZipCode,
    this.businessCity,
    this.businessProvince,
    this.businessCountry,
    this.businessPhone,
    this.businessFax,
    this.businessEmail,
    this.businessPaymentMethod,
    this.businessPaymentCondition,
    this.businessSdiCode,
    this.businessPec,
    this.businessAdministrativeReference,
    this.businessGetPurchaseOrderData,
    this.enabled,
    this.trashed,
    this.lastSync,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'code': code,
      'title': title,
      'denominationType': denominationType,
      'businessType': businessType,
      'idCustomerGroup': idCustomerGroup,
      'discountPercentage': discountPercentage,
      'mandatorySdiPec': mandatorySdiPec,
      'generic': generic,
      'promotional': promotional,
      'autocosume': autocosume,
      'personalFirstname': personalFirstname,
      'personalLastname': personalLastname,
      'personalFiscalCode': personalFiscalCode,
      'personalAddress': personalAddress,
      'personalCity'   : personalCity,
      'personalZipCode': personalZipCode,
      'personalProvince': personalProvince,
      'personalCountry': personalCountry,
      'personalPhone': personalPhone,
      'personalFax': personalFax,
      'personalEmail': personalEmail,
      'businessName': businessName,
      'businessVatNumber': businessVatNumber,
      'businessFiscalCode': businessFiscalCode,
      'businessAddress': businessAddress,
      'businessZipCode': businessZipCode,
      'businessCity': businessCity,
      'businessProvince': businessProvince,
      'businessCountry': businessCountry,
      'businessPhone': businessPhone,
      'businessFax': businessFax,
      'businessEmail': businessEmail,
      'businessPaymentMethod': businessPaymentMethod,
      'businessPaymentCondition': businessPaymentCondition,
      'businessSdiCode': businessSdiCode,
      'businessPec': businessPec,
      'businessAdministrativeReference': businessAdministrativeReference,
      'businessGetPurchaseOrderData': businessGetPurchaseOrderData,
      'enabled': enabled,
      'trashed': trashed,
      'lastSync': lastSync,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as int,
      code: map['code'] as String?,
      title: map['title'] as String?,
      denominationType: map['denominationType'] as String?,
      businessType: map['businessType'] as String?,
      idCustomerGroup: map['idCustomerGroup'] as int?,
      discountPercentage: map['discountPercentage'] as String?,
      mandatorySdiPec: map['mandatorySdiPec'] as String?,
      generic: map['generic'] as int?,
      promotional: map['promotional'] as int?,
      autocosume: map['autocosume'] as int?,
      personalFirstname: map['personalFirstname'] as String?,
      personalLastname: map['personalLastname'] as String?,
      personalFiscalCode: map['personalFiscalCode'] as String?,
      personalAddress: map['personalAddress'] as String?,
      personalCity: map['personalCity'] as String?,
      personalZipCode: map['personalZipCode'] as String?,
      personalProvince: map['personalProvince'] as String?,
      personalCountry: map['personalCountry'] as String?,
      personalPhone: map['personalPhone'] as String?,
      personalFax: map['personalFax'] as String?,
      personalEmail: map['personalEmail'] as String?,
      businessName: map['businessName'] as String?,
      businessVatNumber: map['businessVatNumber'] as String?,
      businessFiscalCode: map['businessFiscalCode'] as String?,
      businessAddress: map['businessAddress'] as String?,
      businessZipCode: map['businessZipCode'] as String?,
      businessCity: map['businessCity'] as String?,
      businessProvince: map['businessProvince'] as String?,
      businessCountry: map['businessCountry'] as String?,
      businessPhone: map['businessPhone'] as String?,
      businessFax: map['businessFax'] as String?,
      businessEmail: map['businessEmail'] as String?,
      businessPaymentMethod: map['businessPaymentMethod'] as String?,
      businessPaymentCondition: map['businessPaymentCondition'] as String?,
      businessSdiCode: map['businessSdiCode'] as String?,
      businessPec: map['businessPec'] as String?,
      businessAdministrativeReference: map['businessAdministrativeReference'] as String?,
      businessGetPurchaseOrderData: map['businessGetPurchaseOrderData'] as int?,
      enabled: map['enabled'] as int?,
      trashed: map['trashed'] as int?,
      lastSync: map['lastSync'] as String?,
    );
  }


  factory CustomerModel.fromJson(Map<String, Object?> json) {
    return CustomerModel(
      id: json['id'] as int,
      code: json['code'] as String?,
      title: json['title'] as String?,
      denominationType: json['denominationType'] as String?,
      businessType: json['businessType'] as String?,
      idCustomerGroup: json['idCustomerGroup'] as int?,
      discountPercentage: json['discountPercentage'] as String?,
      mandatorySdiPec: json['mandatorySdiPec'] as String?,
      generic: json['generic'] as int?,
      promotional: json['promotional'] as int?,
      autocosume: json['autocosume'] as int?,
      personalFirstname: json['personalFirstname'] as String?,
      personalLastname: json['personalLastname'] as String?,
      personalFiscalCode: json['personalFiscalCode'] as String?,
      personalAddress: json['personalAddress'] as String?,
      personalCity  : json['personalCity'] as String?,
      personalZipCode: json['personalZipCode'] as String?,
      personalProvince: json['personalProvince'] as String?,
      personalCountry: json['personalCountry'] as String?,
      personalPhone: json['personalPhone'] as String?,
      personalFax: json['personalFax'] as String?,
      personalEmail: json['personalEmail'] as String?,
      businessName: json['businessName'] as String?,
      businessVatNumber: json['businessVatNumber'] as String?,
      businessFiscalCode: json['businessFiscalCode'] as String?,
      businessAddress: json['businessAddress'] as String?,
      businessZipCode: json['businessZipCode'] as String?,
      businessCity: json['businessCity'] as String?,
      businessProvince: json['businessProvince'] as String?,
      businessCountry: json['businessCountry'] as String?,
      businessPhone: json['businessPhone'] as String?,
      businessFax: json['businessFax'] as String?,
      businessEmail: json['businessEmail'] as String?,
      businessPaymentMethod: json['businessPaymentMethod'] as String?,
      businessPaymentCondition: json['businessPaymentCondition'] as String?,
      businessSdiCode: json['businessSdiCode'] as String?,
      businessPec: json['businessPec'] as String?,
      businessAdministrativeReference: json['businessAdministrativeReference'] as String?,
      businessGetPurchaseOrderData: json['businessGetPurchaseOrderData'] as int?,
      enabled: json['enabled'] as int?,
      trashed: json['trashed'] as int?,
      lastSync: json['lastSync'] as String?,
    );
  }

 String get titleCustomer {
  return( businessName ?? ( (personalFirstname ?? '') +' '+ (personalLastname ?? '') ));
 }

 static Future<List<CustomerModel>> getCustomers () async {
    try{
      final  raw = await LocalDB.query('SELECT * FROM customers');
      return raw.map<CustomerModel>((d) => CustomerModel.fromJson(d)).toList();
    }catch( err ){
      debugPrint(err.toString());
      return [];
    }
  }
}
