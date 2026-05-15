import 'package:auto_route_generator/utils.dart';
import 'package:dashboard/modelli/document.dart';
import 'package:dashboard/modelli/payment.dart';
import 'package:dashboard/state/controller_carrello.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ControllerModuloPagamenti extends ChangeNotifier{
  List<Map<String, dynamic>> controllerTabPayment = [];
  List<PaymentModel> listPayments = [];
  List<int> paymentsSelected = [];
  String _tipoDocumento = 'Scontrino';
  String get tipoDocumento => _tipoDocumento;
  bool nessunaStampa = false;

  void setTipoDocumento ( String t ){
    _tipoDocumento = t;
    notifyListeners();
  } 

  void setNessunaStampa ( bool v) {
    nessunaStampa = v;
    notifyListeners();
  }

 
  void resetPaymentSelectedInCheckout () {
    paymentsSelected = [];
    controllerTabPayment.forEach((p) => p['controller'].clear());
  }

  Future<void> setFirstTotalForCaschAndResetOthersPayments (BuildContext context) async {
    try{
      resetPaymentSelectedInCheckout();
      CarrelloController carrello = context.read<CarrelloController>();
      carrello.setPayments([]);
      //RECUPERO IL PRIMO CONTANTI MP01 cash e di Default gli applico il totale carrello
      final cashPayment = await PaymentModel.getCashPayment();
      if( cashPayment != null ){
          paymentsSelected.add( cashPayment.id );
         final test = controllerTabPayment.firstWhereOrNull((pp) => pp['id'] == cashPayment.id );
         if( test != null ){
          (test['controller'] as TextEditingController).text = (carrello.totalWithTipsAndDiscount).toStringAsFixed(2);
          carrello.addPayment(Payment(title: cashPayment.title, tend: cashPayment.tend ?? 1, idPayment: cashPayment.id, amount: (carrello.totalWithTipsAndDiscount)));
         }
      }
    }catch( err ){
      debugPrint(err.toString());
    }
  }
  
  Future<void> getPaymentsDB ( BuildContext context ) async {
    try{
      if( listPayments.isNotEmpty ) return;
      listPayments = await PaymentModel.getPayments();
      List<Map<String, dynamic>> temp = listPayments.map((p) => {'controller' : TextEditingController(), 'id': p.id}).toList();
      controllerTabPayment = temp;
      debugPrint(listPayments.toString());
    }catch(err){
      
    }
  }

}