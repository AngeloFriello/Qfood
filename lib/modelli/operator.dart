
import 'package:dashboard/Global.dart';
import 'package:dashboard/modelli/articleInCart.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:dashboard/ui/widget/tastierino/tastierino_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class OperatoreModel {
  final int id;
  final String title;
  final String role;
  final String? accessCode;
  final String? firstname;
  final String? lastname;
  final String? email;
  final String? phoneNumber;
  final int? rider;
  final String? riderPercentage;
  final int? fiscalClosure;
  final int? discountReason;
  final String? maximumDiscount;
  final int? enableDiscount;
  final int? manageGeneric;
  final int? displayDailyReport;
  final int? increasePrice;
  final int? printAdvanceAccount;
  final int? printBill;
  final int? trashRoundDetails;
  final int? trashSendedArticle;
  final int? reasonTrashedSendedArticle;
  final int? cleanTable;
  final int? manageTableInAdvanceAccount;
  final int? requestAdvanceAccountFromWaiter;
  final int? trashNotSendedArticle;
  final int? displayAmountRoom;
  final int? displayTablePrice;
  final int? displayAmountTable;
  final int? coverDistinguishCategory;
  final int? cutCover;
  final int? changeWeightOnSendedArticle;
  final int? manageWeight;
  final int? manageManualExit;
  final int? engageTable;
  final int? joinTable;
  final int? closeTableNoPrint;
  final int? subdivideBill;
  final int? separateBill;
  final int? unlockTable;
  final int? resendCommand;
  final int? enableServicePercentage;
  final int? automaticCopyReceiptPosPayment;
  final int? cancelReceipt;
  final int? reasonCancelTable;
  final int? reasonCancelArticleNotSended;
  final int? displayCoverRoom;
  final int? manualDistinguishCover;
  final int? statusArticleNotSended;
  final int? splitTable;
  final int? moveArticleTable;
  final int? copyReceipt;
  final int? acWithdrawal;
  final int? acDeposit;
  final int? acChange;
  final int? acRefill;
  final int? acArchivingExceptCashFund;
  final int? acTotalArchiving;
  final int? smallProductName;
  final String? productNameSize; // S M L
  final String? productSmallNameSize; // S M L
  final String? rapidDiscountButtonPercentage;
  final String? uiSide; // R L
  final int? discountBenchTable;
  final int? extendedCart;
  final int? rapidButtonCash;
  final int? displayAmountLastSale;
  final int? rapidPriceListChangeButton;
  final int? displayProductReduced;
  final int? reducePrice;
  final int? useDarkMode;
  final int? printDefaultCommandFromBench;
  final int? displayBigCategory;
  final int? tableOpeningInCommand;
  final int? sendOrderNoExitTable;
  final int? valueWithoutSeparator;
  final int? paginatedArticle;
  final int? displayTableReduced;
  final int? displayUserTable;
  final int? paymentCheck;
  final int? paymentWireTransfer;
  final int? idPosGroup;
  final int? enabled;
  final int? trashed;
  final String? lastSync;
  final String? trainingPin;
  final String? magneticKeyCode;
  final int?    manageBill;
  final int?    reworksSale;
  final int?    searchArticles;

  const OperatoreModel({
    required this.id,
    required this.title,
    required this.role,
    this.accessCode,
    this.firstname,
    this.lastname,
    this.email,
    this.phoneNumber,
    this.rider,
    this.riderPercentage,
    this.fiscalClosure,
    this.discountReason,
    this.maximumDiscount,
    this.enableDiscount,
    this.manageGeneric,
    this.displayDailyReport,
    this.increasePrice,
    this.printAdvanceAccount,
    this.printBill,
    this.trashRoundDetails,
    this.trashSendedArticle,
    this.reasonTrashedSendedArticle,
    this.cleanTable,
    this.manageTableInAdvanceAccount,
    this.requestAdvanceAccountFromWaiter,
    this.trashNotSendedArticle,
    this.displayAmountRoom,
    this.displayTablePrice,
    this.displayAmountTable,
    this.coverDistinguishCategory,
    this.cutCover,
    this.changeWeightOnSendedArticle,
    this.manageWeight,
    this.manageManualExit,
    this.engageTable,
    this.joinTable,
    this.closeTableNoPrint,
    this.subdivideBill,
    this.separateBill,
    this.unlockTable,
    this.resendCommand,
    this.enableServicePercentage,
    this.automaticCopyReceiptPosPayment,
    this.cancelReceipt,
    this.reasonCancelTable,
    this.reasonCancelArticleNotSended,
    this.displayCoverRoom,
    this.manualDistinguishCover,
    this.statusArticleNotSended,
    this.splitTable,
    this.moveArticleTable,
    this.copyReceipt,
    this.acWithdrawal,
    this.acDeposit,
    this.acChange,
    this.acRefill,
    this.acArchivingExceptCashFund,
    this.acTotalArchiving,
    this.smallProductName,
    this.productNameSize,
    this.productSmallNameSize,
    this.rapidDiscountButtonPercentage,
    this.uiSide,
    this.discountBenchTable,
    this.extendedCart,
    this.rapidButtonCash,
    this.displayAmountLastSale,
    this.rapidPriceListChangeButton,
    this.displayProductReduced,
    this.reducePrice,
    this.useDarkMode,
    this.printDefaultCommandFromBench,
    this.displayBigCategory,
    this.tableOpeningInCommand,
    this.sendOrderNoExitTable,
    this.valueWithoutSeparator,
    this.paginatedArticle,
    this.displayTableReduced,
    this.displayUserTable,
    this.paymentCheck,
    this.paymentWireTransfer,
    this.idPosGroup,
    this.enabled,
    this.trashed,
    this.lastSync,
    this.trainingPin,
    this.magneticKeyCode,
    this.manageBill,
    this.reworksSale,
    this.searchArticles
  });

factory OperatoreModel.fromJson(Map<String, dynamic> json) {
  return OperatoreModel(
    id: json['id'] as int,
    title: json['title'] as String,
    role: json['role'] as String,
    accessCode: json['accessCode'] as String?,
    firstname: json['firstname'] as String?,
    lastname: json['lastname'] as String?,
    email: json['email'] as String?,
    phoneNumber: json['phoneNumber'] as String?,
    rider: json['rider'] as int?,
    riderPercentage: json['riderPercentage'] as String?,
    fiscalClosure: json['fiscalClosure'] as int?,
    discountReason: json['discountReason'] as int?,
    maximumDiscount: json['maximumDiscount'] as String?,
    enableDiscount: json['enableDiscount'] as int?,
    manageGeneric: json['manageGeneric'] as int?,
    displayDailyReport: json['displayDailyReport'] as int?,
    increasePrice: json['increasePrice'] as int?,
    printAdvanceAccount: json['printAdvanceAccount'] as int?,
    printBill: json['printBill'] as int?,
    trashRoundDetails: json['trashRoundDetails'] as int?,
    trashSendedArticle: json['trashSendedArticle'] as int?,
    reasonTrashedSendedArticle: json['reasonTrashedSendedArticle'] as int?,
    cleanTable: json['cleanTable'] as int?,
    manageTableInAdvanceAccount: json['manageTableInAdvanceAccount'] as int?,
    requestAdvanceAccountFromWaiter:json['requestAdvanceAccountFromWaiter'] as int?,
    trashNotSendedArticle: json['trashNotSendedArticle'] as int?,
    displayAmountRoom: json['displayAmountRoom'] as int?,
    displayTablePrice: json['displayTablePrice'] as int?,
    displayAmountTable: json['displayAmountTable'] as int?,
    coverDistinguishCategory: json['coverDistinguishCategory'] as int?,
    cutCover: json['cutCover'] as int?,
    changeWeightOnSendedArticle: json['changeWeightOnSendedArticle'] as int?,
    manageWeight: json['manageWeight'] as int?,
    manageManualExit: json['manageManualExit'] as int?,
    engageTable: json['engageTable'] as int?,
    joinTable: json['joinTable'] as int?,
    closeTableNoPrint: json['closeTableNoPrint'] as int?,
    subdivideBill: json['subdivideBill'] as int?,
    separateBill: json['separateBill'] as int?,
    unlockTable: json['unlockTable'] as int?,
    resendCommand: json['resendCommand'] as int?,
    enableServicePercentage: json['enableServicePercentage'] as int?,
    automaticCopyReceiptPosPayment:json['automaticCopyReceiptPosPayment'] as int?,
    cancelReceipt: json['cancelReceipt'] as int?,
    reasonCancelTable: json['reasonCancelTable'] as int?,
    reasonCancelArticleNotSended:json['reasonCancelArticleNotSended'] as int?,
    displayCoverRoom: json['displayCoverRoom'] as int?,
    manualDistinguishCover: json['manualDistinguishCover'] as int?,
    statusArticleNotSended: json['statusArticleNotSended'] as int?,
    splitTable: json['splitTable'] as int?,
    moveArticleTable: json['moveArticleTable'] as int?,
    copyReceipt: json['copyReceipt'] as int?,
    acWithdrawal: json['acWithdrawal'] as int?,
    acDeposit: json['acDeposit'] as int?,
    acChange: json['acChange'] as int?,
    acRefill: json['acRefill'] as int?,
    acArchivingExceptCashFund:json['acArchivingExceptCashFund'] as int?,
    acTotalArchiving: json['acTotalArchiving'] as int?,
    smallProductName: json['smallProductName'] as int?,
    productNameSize: json['productNameSize'] as String?,
    productSmallNameSize: json['productSmallNameSize'] as String?,
    rapidDiscountButtonPercentage:json['rapidDiscountButtonPercentage'] as String?,
    uiSide: json['uiSide'] as String?,
    discountBenchTable: json['discountBenchTable'] as int?,
    extendedCart: json['extendedCart'] as int?,
    rapidButtonCash: json['rapidButtonCash'] as int?,
    displayAmountLastSale: json['displayAmountLastSale'] as int?,
    rapidPriceListChangeButton:json['rapidPriceListChangeButton'] as int?,
    displayProductReduced: json['displayProductReduced'] as int?,
    reducePrice: json['reducePrice'] as int?,
    useDarkMode: json['useDarkMode'] as int?,
    printDefaultCommandFromBench:json['printDefaultCommandFromBench'] as int?,
    displayBigCategory: json['displayBigCategory'] as int?,
    tableOpeningInCommand: json['tableOpeningInCommand'] as int?,
    sendOrderNoExitTable: json['sendOrderNoExitTable'] as int?,
    valueWithoutSeparator: json['valueWithoutSeparator'] as int?,
    paginatedArticle: json['paginatedArticle'] as int?,
    displayTableReduced: json['displayTableReduced'] as int?,
    displayUserTable: json['displayUserTable'] as int?,
    paymentCheck: json['paymentCheck'] as int?,
    paymentWireTransfer: json['paymentWireTransfer'] as int?,
    idPosGroup: json['idPosGroup'] as int?,
    enabled: json['enabled'] as int?,
    trashed: json['trashed'] as int?,
    lastSync: json['lastSync'] as String?,
    trainingPin: json['trainingPin'] as String?,
    magneticKeyCode : json['magneticKeyCode'] as String?,
    reworksSale: json['reworksSale'] as int?,
    manageBill:  json['manageBill'] as int?,
    searchArticles: json['searchArticles'] as int?
  );
}

  Map<String, Object?> toMap() {
  return <String, Object?>{
    'id': id,
    'title': title,
    'role': role,
    'accessCode': accessCode,
    'firstname': firstname,
    'lastname': lastname,
    'email': email,
    'phoneNumber': phoneNumber,
    'rider': rider,
    'riderPercentage': riderPercentage,
    'fiscalClosure': fiscalClosure,
    'discountReason': discountReason,
    'maximumDiscount': maximumDiscount,
    'enableDiscount': enableDiscount,
    'manageGeneric': manageGeneric,
    'displayDailyReport': displayDailyReport,
    'increasePrice': increasePrice,
    'printAdvanceAccount': printAdvanceAccount,
    'printBill': printBill,
    'trashRoundDetails': trashRoundDetails,
    'trashSendedArticle': trashSendedArticle,
    'reasonTrashedSendedArticle': reasonTrashedSendedArticle,
    'cleanTable': cleanTable,
    'manageTableInAdvanceAccount': manageTableInAdvanceAccount,
    'requestAdvanceAccountFromWaiter': requestAdvanceAccountFromWaiter,
    'trashNotSendedArticle': trashNotSendedArticle,
    'displayAmountRoom': displayAmountRoom,
    'displayTablePrice': displayTablePrice,
    'displayAmountTable': displayAmountTable,
    'coverDistinguishCategory': coverDistinguishCategory,
    'cutCover': cutCover,
    'changeWeightOnSendedArticle': changeWeightOnSendedArticle,
    'manageWeight': manageWeight,
    'manageManualExit': manageManualExit,
    'engageTable': engageTable,
    'joinTable': joinTable,
    'closeTableNoPrint': closeTableNoPrint,
    'subdivideBill': subdivideBill,
    'separateBill': separateBill,
    'unlockTable': unlockTable,
    'resendCommand': resendCommand,
    'enableServicePercentage': enableServicePercentage,
    'automaticCopyReceiptPosPayment': automaticCopyReceiptPosPayment,
    'cancelReceipt': cancelReceipt,
    'reasonCancelTable': reasonCancelTable,
    'reasonCancelArticleNotSended': reasonCancelArticleNotSended,
    'displayCoverRoom': displayCoverRoom,
    'manualDistinguishCover': manualDistinguishCover,
    'statusArticleNotSended': statusArticleNotSended,
    'splitTable': splitTable,
    'moveArticleTable': moveArticleTable,
    'copyReceipt': copyReceipt,
    'acWithdrawal': acWithdrawal,
    'acDeposit': acDeposit,
    'acChange': acChange,
    'acRefill': acRefill,
    'acArchivingExceptCashFund': acArchivingExceptCashFund,
    'acTotalArchiving': acTotalArchiving,
    'smallProductName': smallProductName,
    'productNameSize': productNameSize,
    'productSmallNameSize': productSmallNameSize,
    'rapidDiscountButtonPercentage': rapidDiscountButtonPercentage,
    'uiSide': uiSide,
    'discountBenchTable': discountBenchTable,
    'extendedCart': extendedCart,
    'rapidButtonCash': rapidButtonCash ?? 1,
    'displayAmountLastSale': displayAmountLastSale,
    'rapidPriceListChangeButton': rapidPriceListChangeButton,
    'displayProductReduced': displayProductReduced,
    'reducePrice': reducePrice,
    'useDarkMode': useDarkMode,
    'printDefaultCommandFromBench': printDefaultCommandFromBench,
    'displayBigCategory': displayBigCategory,
    'tableOpeningInCommand': tableOpeningInCommand,
    'sendOrderNoExitTable': sendOrderNoExitTable,
    'valueWithoutSeparator': valueWithoutSeparator,
    'paginatedArticle': paginatedArticle,
    'displayTableReduced': displayTableReduced,
    'displayUserTable': displayUserTable,
    'paymentCheck': paymentCheck,
    'paymentWireTransfer': paymentWireTransfer,
    'idPosGroup': idPosGroup,
    'enabled': enabled,
    'trashed': trashed,
    'lastSync': lastSync,
    'trainingPin': trainingPin,
    'magneticKeyCode': magneticKeyCode,
    'reworksSale' :reworksSale,
    'manageBill' :manageBill,
    'searchArticles':searchArticles,
  };
}



static bool checkDiscountMaximim( double totaleCarrello, ScontoTipo type,  String valueDiscount, String? maximumDiscount_ ){
  bool ok = true;
  double discount = 0;
  try{
    
    switch (type) {
      case ScontoTipo.percentuale:
          double percentage_ = double.parse(valueDiscount.replaceAll(',', '.'));
          double totalCart   = totaleCarrello;
          if( percentage_ > 100 || percentage_ ==  0 ){
            discount = 0;
            break;
          }
          double disc =  ((totalCart / 100) * percentage_);
          discount = disc;
      break;
      case  ScontoTipo.importo:
            double total = double.parse(valueDiscount.replaceAll(',', '.'));
            if( total > totaleCarrello ){
              discount = totaleCarrello;
              break;
            }
            discount = total;
      break;
      case  ScontoTipo.totale:
            final total = double.parse(valueDiscount.replaceAll(',', '.'));
            final currentTotal = totaleCarrello;
            discount = currentTotal - total;
      break;
    }


    if( maximumDiscount_ != null && maximumDiscount_ != '' && maximumDiscount_ != '0' ){
      double maximumDiscount = double.parse( maximumDiscount_ );
      double percentageCalculate = ( discount / totaleCarrello ) * 100;
      if( percentageCalculate > maximumDiscount ){
        ok = false;
        SnackBarForcedClosure("Sconto massimo per l'operatore loggato è $maximumDiscount %", Colors.red);
      }
    }
  }catch(err){
    debugPrint( err.toString() );
  }finally{
    return ok;
  }
}

static bool incrementPrice ( ProdottoCarrello prod, double newPriceRow ){
  bool ok = true;
  try{
    if( operatorLogged != null && operatorLogged!.increasePrice == 0 ){
      double originPrice = double.parse(prod.article.price ?? '0'); 
      double newPrice    = newPriceRow / prod.quantity;
      if( newPrice > originPrice && prod.article.generic == 0 ){
        SnackBarForcedClosure('Operatore non abilitato ad aumentare il prezzo', Colors.red);
         ok = false;
      }
    }
  }catch(err){

  }finally{
    return ok;
  }
}

static bool decrementPrice ( ProdottoCarrello prod, double newPriceRow ){
  bool ok = true;
  try{
    if( operatorLogged != null && operatorLogged!.reducePrice == 0 ){
      double originPrice = double.parse(prod.article.price ?? '0'); 
      double newPrice    = newPriceRow / prod.quantity;
      if( newPrice < originPrice && prod.article.generic == 0 ){
        SnackBarForcedClosure('Operatore non abilitato a ridurre il prezzo', Colors.red);
        ok = false;
      }
    }
  }catch(err){

  }finally{
    return ok;
  }
}



static Future<List<OperatoreModel>> getOperators ( ) async {
  List<OperatoreModel> operators = [];
  try{
    final resp = await LocalDB.query('SELECT * FROM operators');
    operators = resp.map((o) => OperatoreModel.fromJson(o)).toList();

  }catch(err){
    debugPrint( err.toString() );
  }finally{
    return operators;
  }
}


}