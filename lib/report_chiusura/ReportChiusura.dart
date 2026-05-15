/* import 'package:dashboard/app/service/service_report.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:dashboard/modelli/category.dart';
import 'package:dashboard/modelli/document.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';

class ReportChiusura {

  //DOCUMENTI EMESSI
  int n_scontrini_incassati      = 0; //
  int n_scontrini_sospesi        = 0; 
  int n_scontrini_non_incassati  = 0; 
  int n_scontrini_annullati      = 0; //
  int n_fatture_incassate        = 0; //
  int n_fatture_non_incassate    = 0;
  int n_note_credito             = 0; //
  //int n_addebiti               = 0;
  int n_totale_documenti         = 0; //

  double scontrini_incassati     = 0; //
  double scontrini_sospesi       = 0;
  double scontrini_non_incassati = 0;
  double scontrini_annullati     = 0; //
  double fatture_incassate       = 0; //
  double fatture_non_incassate   = 0;
  double note_credito            = 0; //
  //double addebiti                = 0;
  double totale_documenti        = 0; //


  //vendite esenti
  double tabacchi                        = 0; //
  double valori_bollati                  = 0; //
  double giochi                          = 0; //
  double gratta_e_vinci                  = 0; //
  double biglietti                       = 0; //
  double totale_prodotti_esenti          = 0; //

  int n_tabacchi                   = 0; //
  int n_valori_bollati             = 0; //
  int n_giochi                     = 0; //
  int n_gratta_e_vinci             = 0; //
  int n_biglietti                  = 0; //
  int n_totale_prodotti_esenti     = 0; //


  //DETTAGLI INCASSI
  /* int n_contanti                     = 0;
  int n_carta                        = 0;
  int n_bonifici_da_ricevere         = 0;
  int n_assegni                      = 0;
  int n_ticket                       = 0;
  int n_sospesi_da_incassare         = 0; */
  int n_glovo                        = 0; //
  int n_just_eat                     = 0; //
  int n_alfonsino                    = 0; //
  int n_deliveroo                    = 0; //

  /* double carta                        = 0;
  double bonifici_da_ricevere         = 0;
  double assegni                      = 0;
  double ticket                       = 0;
  double sospesi_da_incassare         = 0; */
  Map<String, double>?  paymentsAmountAndQta; //

  double glovo                        = 0; //
  double just_eat                     = 0; //
  double alfonsino                    = 0; //
  double deliveroo                    = 0; //


  //MOVIMENTI DISTINTA CASSA
  double fondo_cassa_iniziale           = 0; //
  double entrate_di_cassa               = 0;
  double uscite_di_cassa                = 0;
  //double aperture_cassetto_manuale    = 0; //??????
  double prelievi_cassetto_automatico   = 0;
  double fondo_cassa_finale             = 0;
  double totale_movimenti_cassa         = 0; 

  //DETTAGLI STATISTICI
  int n_vedite_banco                    = 0; //
  int n_vendite_consegne                = 0; //
  int n_vendite_ritiri                  = 0; //

  double vedite_banco                   = 0; //
  double vendite_consegne               = 0; //
  double vendite_ritiri                 = 0; //

  double mance                          = 0; //

  int n_scontrini                       = 0; // n documenti
  double media_scontrini                = 0; // media di tutte le vendite positive ( escludo note e annulli)

  //SALE
  int    n_coperti                      = 0;
  double media_coperti                  = 0;
  
  /* double food                           = 0;
  double beverage                       = 0;
  double others                         = 0; */

  List<Map<String,dynamic>>? tipiCategoria = []; //

  List<Map<String,dynamic>>? products       = [];   // titolo articolo  e qta venduta
  List<Map<String,dynamic>>? categories     = [];   // titolo categpria e qta venduta
  List<Map<String,dynamic>>? castellettoIva = []; //id, valore iva, totale per iva

  ReportChiusura({
    // DOCUMENTI EMESSI
    this.n_scontrini_incassati      = 0,
    this.n_scontrini_sospesi        = 0,
    this.n_scontrini_non_incassati  = 0,
    this.n_scontrini_annullati      = 0,
    this.n_fatture_incassate        = 0,
    this.n_fatture_non_incassate    = 0,
    this.n_note_credito             = 0,
    //this.n_addebiti                 = 0,
    this.n_totale_documenti         = 0,

    this.scontrini_incassati        = 0,
    this.scontrini_sospesi          = 0,
    this.scontrini_non_incassati    = 0,
    this.scontrini_annullati        = 0,
    this.fatture_incassate          = 0,
    this.fatture_non_incassate      = 0,
    this.note_credito               = 0,
    //this.addebiti                   = 0,
    this.totale_documenti           = 0,

    // VENDITE ESENTI
    this.tabacchi                   = 0,
    this.valori_bollati             = 0,
    this.giochi                     = 0,
    this.gratta_e_vinci             = 0,
    this.biglietti                  = 0,
    this.totale_prodotti_esenti    = 0,

    this.n_tabacchi                 = 0,
    this.n_valori_bollati           = 0,
    this.n_giochi                   = 0,
    this.n_gratta_e_vinci           = 0,
    this.n_biglietti                = 0,
    this.n_totale_prodotti_esenti   = 0,

    // DETTAGLI INCASSI
    this.paymentsAmountAndQta       , //MAPPA CON TOTALI PER TIPO DI PAGAMENTO E QTA

    /* this.n_contanti                 = 0,
    this.n_carta                    = 0,
    this.n_bonifici_da_ricevere     = 0,
    this.n_assegni                  = 0,
    this.n_ticket                   = 0,
    this.n_sospesi_da_incassare     = 0, */
    this.n_glovo                    = 0, //
    this.n_just_eat                 = 0,//
    this.n_alfonsino                = 0,//
    this.n_deliveroo                = 0,//

    /* this.contanti                   = 0,
    this.carta                      = 0,
    this.bonifici_da_ricevere       = 0,
    this.assegni                    = 0,
    this.ticket                     = 0,
    this.sospesi_da_incassare       = 0, */
    this.glovo                      = 0,//
    this.just_eat                   = 0,//
    this.alfonsino                  = 0,//
    this.deliveroo                  = 0,//

    // MOVIMENTI DISTINTA CASSA
    this.fondo_cassa_iniziale           = 0,
    this.entrate_di_cassa               = 0,
    this.uscite_di_cassa                = 0,
    //this.aperture_cassetto_manuale      = 0,
    this.prelievi_cassetto_automatico   = 0,
    this.fondo_cassa_finale             = 0,
    this.totale_movimenti_cassa         = 0,

    // DETTAGLI STATISTICI
    this.n_vedite_banco             = 0,
    this.n_vendite_consegne         = 0,
    this.n_vendite_ritiri           = 0,

    this.vedite_banco               = 0,
    this.vendite_consegne           = 0,
    this.vendite_ritiri             = 0,

    this.mance                      = 0,
    //this.n_scontrini              = 0,
    this.media_scontrini            = 0,

    // SALE
    this.n_coperti                  = 0,
    this.media_coperti              = 0,

    /* this.food                       = 0,
    this.beverage                   = 0,
    this.others                     = 0, */
    this.tipiCategoria,                // food, beverage etc
    this.products                   , //  title, id, qta 
    this.castellettoIva,
  });


  static Future<ReportChiusura> report ( DateTime from, DateTime to ) async {
    ReportChiusura rep = ReportChiusura();
    try{
      List<Documento>           allDoc   = await getDocuments(from: from, to: to);
      Map?                      shift    = await isOpened();
      if( shift  != null){
        rep.fondo_cassa_iniziale = shift['fondoIniziale'];
      }
      rep.products       = [];
      rep.categories     = [];
      rep.tipiCategoria  = [];
      rep.castellettoIva = [];
      rep.paymentsAmountAndQta = {};
      
      //PER PEGAMENTI
      allDoc.forEach((d){
        d.payments.forEach((p){
          if( rep.paymentsAmountAndQta!.keys.contains(p.title) ){
            rep.paymentsAmountAndQta![p.title] = rep.paymentsAmountAndQta![p.title]! + p.amount;
            rep.paymentsAmountAndQta![p.title+'_qta'] = rep.paymentsAmountAndQta![p.title+'_qta']! + 1;
          }else{
            rep.paymentsAmountAndQta![p.title] =  p.amount;
            rep.paymentsAmountAndQta![p.title+'_qta'] = 1;
          }
        });
      });

      //PER articoli title, qta
      for (final d in allDoc) {
        for (final a in d.copyCart) {
    
          //QUANTITà vendute per categoria
          CategoryModel? categoryProduct = await getCategoryByArticle(idArticle: a.article.id);
          if ( categoryProduct != null ){
            int indexCategory = rep.categories!.indexWhere((cc) => cc['id'] == categoryProduct.id );
            if( indexCategory == -1 ){
              rep.categories!.add({'id': categoryProduct.id, 'title': categoryProduct.title, 'qta': a.quantity} );
            }else{
              rep.categories![indexCategory]['qta'] = rep.categories![indexCategory]['qta'] + a.quantity;
            }
          }

          //totali per tipo di categoria
          if ( categoryProduct != null ){
            int indexCategory = rep.tipiCategoria!.indexWhere((cc) => cc['tipology'] == categoryProduct.tipology );
            if( categoryProduct.tipology != null && categoryProduct.tipology!.isNotEmpty ){
              if( indexCategory == -1  ){
                rep.tipiCategoria!.add({'tipology': categoryProduct.tipology, 'amount': a.priceRowCart} );
              }else{
                rep.tipiCategoria![indexCategory]['amount'] = rep.tipiCategoria![indexCategory]['amount'] + a.priceRowCart;
              }
            };
          }
          
          //CASTELLETTO IVA
          int indexIva = rep.castellettoIva!.indexWhere((i) => i['id'] == a.article.idVatRate );
          if( indexIva == -1 ){
            rep.castellettoIva!.add({'id': a.article.idVatRate, 'value': a.article.rateValue , 'amount': a.priceRowCart - a.priceNetRow});
          }else{
            rep.castellettoIva![indexIva]['amount'] = rep.castellettoIva![indexIva]['amount'] +a.priceRowCart - a.priceNetRow;
          }

          // prodotti esenti
          double vat = double.parse(a.article.rateValue ?? '0');
          if (vat == 0) rep.n_totale_prodotti_esenti = rep.n_totale_prodotti_esenti + a.quantity.toInt();
          if (vat == 0) rep.totale_prodotti_esenti   = rep.totale_prodotti_esenti   + a.priceRowCart;

          switch (a.article.articleType) {
            case ArticleType.gambling:
              rep.n_giochi = rep.n_giochi + a.quantity.toInt();
              rep.giochi   = rep.giochi   + a.priceRowCart;
              break;
            case ArticleType.tobaccos:
              rep.n_tabacchi = rep.n_tabacchi + a.quantity.toInt();
              rep.tabacchi   = rep.tabacchi   + a.priceRowCart;
              break;
            case ArticleType.revenueStamps:
              rep.n_valori_bollati = rep.n_valori_bollati + a.quantity.toInt();
              rep.valori_bollati   = rep.valori_bollati   + a.priceRowCart;
              break;
            case ArticleType.ticket:
              rep.n_biglietti = rep.n_biglietti + a.quantity.toInt();
              rep.biglietti   = rep.biglietti   + a.priceRowCart;
              break;
            case ArticleType.scratchAndWin:
              rep.n_gratta_e_vinci = rep.n_gratta_e_vinci + a.quantity.toInt();
              rep.gratta_e_vinci   = rep.gratta_e_vinci   + a.priceRowCart;
              break;
            default:
              break;
          }

          final exist = rep.products!.indexWhere((aa) => aa['id'] == a.article.id);
          if (exist == -1) {
            rep.products!.add({
              'id'   : a.article.id,
              'title': a.article.title,
              'qta'  : a.quantity,
            });
          } else {
            rep.products![exist]['qta'] = rep.products![exist]['qta'] + a.quantity;
          }
        }
      }


      rep.n_scontrini_incassati           = await countDocumentsRt(from: from, to: to);

      rep.n_scontrini           = await countDocumentsRt(from: from, to: to);
      rep.n_fatture_incassate   = await countDocumentsInvoice(from: from, to: to);
      rep.n_scontrini_annullati = await countDocumentsRtDeleted(from: from, to: to);
      rep.n_note_credito        = await countDocumentsCreditNote(from: from, to: to);
      rep.n_totale_documenti    = await countDocuments(from: from, to: to) - rep.n_note_credito - rep.n_scontrini_annullati;

      rep.scontrini_incassati   = await sumDocumentsRtAmount(from: from, to: to);
      rep.fatture_incassate     = await sumDocumentsInvoiceAmount(from: from, to: to);
      rep.note_credito          = await sumDocumentsNoteCreditAmount(from: from, to: to);
      rep.scontrini_annullati   = await sumDocumentsRtDeletedAmount(from: from, to: to);
      rep.totale_documenti      = await sumDocuments(from: from, to: to);
      rep.media_scontrini       = double.parse(( (rep.totale_documenti - rep.note_credito - rep.scontrini_annullati) / rep.n_totale_documenti).toStringAsFixed(2)) ;
      if( rep.media_scontrini.isNaN ) rep.media_scontrini = 0; 

      rep.mance                 = await sumDocumentsTips(from: from, to: to);

      rep.n_glovo               = await countDocumentsByDeliveryService(from: from, to: to,deliveryService: 'glovo');
      rep.n_just_eat            = await countDocumentsByDeliveryService(from: from, to: to,deliveryService: 'justEat');
      rep.n_deliveroo           = await countDocumentsByDeliveryService(from: from, to: to,deliveryService: 'deliveroo');
      rep.n_alfonsino           = await countDocumentsByDeliveryService(from: from, to: to,deliveryService: 'alfonsino');
      rep.n_vendite_ritiri      = await countDocumentsByDeliveryService(from: from, to: to,deliveryService: 'takeAway');

      rep.n_vendite_consegne    = rep.n_glovo + rep.n_just_eat + rep.n_deliveroo +rep.n_alfonsino;
      rep.n_vedite_banco        = await countDocumentsBanco(from: from, to: to);

      rep.glovo                 = await sumDocumentsByDeliveryServiceAmount(from: from, to: to,deliveryService: 'glovo');
      rep.just_eat              = await sumDocumentsByDeliveryServiceAmount(from: from, to: to,deliveryService: 'justEat');
      rep.deliveroo             = await sumDocumentsByDeliveryServiceAmount(from: from, to: to,deliveryService: 'deliveroo');
      rep.alfonsino             = await sumDocumentsByDeliveryServiceAmount(from: from, to: to,deliveryService: 'alfonsino');
      rep.vendite_ritiri        = await sumDocumentsByDeliveryServiceAmount(from: from, to: to,deliveryService: 'takeAway');

      rep.vendite_consegne   = rep.glovo + rep.just_eat + rep.deliveroo +rep.alfonsino;
      rep.vedite_banco       = await sumDocumentsBancoAmount(from: from, to: to);
    }catch( err ){
      debugPrint(err.toString());
    }finally{
      return rep;
    }
  }
  //Dettagli IVA
  //CASTELLETTO IVA: ALIQUOTA IMPONIBILE IVA
  //TOTALI IVA
  //Categorie vendute
  //Prodotti venduti


}

Future<List<Documento>> getDocuments({
  required DateTime from,
  required DateTime to,
}) async {
  final db = await LocalDB.instance();

  final String fromStr = from.toIso8601String();
  final String toStr = to.toIso8601String();

  final result = await db.rawQuery(
    '''
    SELECT *
    FROM documents
    WHERE realDate >= ?
      AND realDate <= ?
    ORDER BY realDate ASC
    ''',
    [fromStr, toStr],
  );

  return result.map((row) => Documento.fromMap(row)).toList();
}

Future<CategoryModel?> getCategoryByArticle({
  required int idArticle,
}) async {
  final db = await LocalDB.instance();

  final result = await db.rawQuery(
    '''
    SELECT c.*
    FROM categories c
    INNER JOIN articlesCategories ac ON ac.idCategory = c.id
    WHERE ac.idArticle = ?
    LIMIT 1
    ''',
    [idArticle],
  );

  if (result.isEmpty) return null;
  return CategoryModel.fromJson(result.first);//  result.first;
}

Future<int> countDocumentsRt({
  required DateTime from,
  required DateTime to,
}) async {
  final db = await LocalDB.instance();

  // Converti in stringa ISO 8601 compatibile con il TEXT del DB
  final String fromStr = from.toIso8601String();
  final String toStr = to.toIso8601String();

  final result = await db.rawQuery(
    '''
    SELECT COUNT(*) as count
    FROM documents
    WHERE overrideMovementType IS NULL
      AND realDate >= ?
      AND realDate <= ?
    ''',
    [fromStr, toStr],
  );

  return Sqflite.firstIntValue(result) ?? 0;
}

Future<double> sumDocumentsRtAmount({
  required DateTime from,
  required DateTime to,
}) async {
  final db = await LocalDB.instance();

  final String fromStr = from.toIso8601String();
  final String toStr = to.toIso8601String();

  final result = await db.rawQuery(
    '''
    SELECT SUM(amount) as total
    FROM documents
    WHERE overrideMovementType IS NULL
      AND realDate >= ?
      AND realDate <= ?
    ''',
    [fromStr, toStr],
  );

  final value = result.first['total'];
  return (value as num?)?.toDouble() ?? 0.0;
}


Future<int> countDocumentsCreditNote({
  required DateTime from,
  required DateTime to,
}) async {
  final db = await LocalDB.instance();

  // Converti in stringa ISO 8601 compatibile con il TEXT del DB
  final String fromStr = from.toIso8601String();
  final String toStr = to.toIso8601String();

  final result = await db.rawQuery(
    '''
    SELECT COUNT(*) as count
    FROM documents
    WHERE overrideMovementType IS 'credit_note'
      AND realDate >= ?
      AND realDate <= ?
    ''',
    [fromStr, toStr],
  );

  return Sqflite.firstIntValue(result) ?? 0;
}

Future<double> sumDocumentsNoteCreditAmount({
  required DateTime from,
  required DateTime to,
}) async {
  final db = await LocalDB.instance();

  final String fromStr = from.toIso8601String();
  final String toStr = to.toIso8601String();

  final result = await db.rawQuery(
    '''
    SELECT SUM(amount) as total
    FROM documents
    WHERE overrideMovementType IS 'credit_note'
      AND realDate >= ?
      AND realDate <= ?
    ''',
    [fromStr, toStr],
  );

  final value = result.first['total'];
  return (value as num?)?.toDouble() ?? 0.0;
}
Future<int> countDocumentsSimulation({
  required DateTime from,
  required DateTime to,
}) async {
  final db = await LocalDB.instance();

  final String fromStr = from.toIso8601String();
  final String toStr = to.toIso8601String();

  final result = await db.rawQuery(
    '''
    SELECT COUNT(*) as count
    FROM documents
    WHERE overrideMovementType IS 'simulation'
      AND realDate >= ?
      AND realDate <= ?
    ''',
    [fromStr, toStr],
  );

  return Sqflite.firstIntValue(result) ?? 0;
}

Future<int> countDocumentsInvoice({
  required DateTime from,
  required DateTime to,
}) async {
  final db = await LocalDB.instance();

  final String fromStr = from.toIso8601String();
  final String toStr = to.toIso8601String();

  final result = await db.rawQuery(
    '''
    SELECT COUNT(*) as count
    FROM documents
    WHERE overrideMovementType IS 'invoice'
      AND realDate >= ?
      AND realDate <= ?
    ''',
    [fromStr, toStr],
  );

  return Sqflite.firstIntValue(result) ?? 0;
}
Future<double> sumDocumentsInvoiceAmount({
  required DateTime from,
  required DateTime to,
}) async {
  final db = await LocalDB.instance();

  final String fromStr = from.toIso8601String();
  final String toStr = to.toIso8601String();

  final result = await db.rawQuery(
    '''
    SELECT SUM(amount) as total
    FROM documents
    WHERE overrideMovementType IS 'invoice'
      AND realDate >= ?
      AND realDate <= ?
    ''',
    [fromStr, toStr],
  );

  final value = result.first['total'];
  return (value as num?)?.toDouble() ?? 0.0;
}

Future<int> countDocumentsRtDeleted({
  required DateTime from,
  required DateTime to,
}) async {
  final db = await LocalDB.instance();

  final String fromStr = from.toIso8601String();
  final String toStr = to.toIso8601String();

  final result = await db.rawQuery(
    '''
    SELECT COUNT(*) as count
    FROM documents
    WHERE overrideMovementType IS NULL
      AND deletedBy IS NOT NULL
      AND realDate >= ?
      AND realDate <= ?
    ''',
    [fromStr, toStr],
  );

  return Sqflite.firstIntValue(result) ?? 0;
}
Future<double> sumDocumentsRtDeletedAmount({
  required DateTime from,
  required DateTime to,
}) async {
  final db = await LocalDB.instance();

  final String fromStr = from.toIso8601String();
  final String toStr = to.toIso8601String();

  final result = await db.rawQuery(
    '''
    SELECT SUM(amount) as total
    FROM documents
    WHERE overrideMovementType IS NULL
      AND deletedBy IS NOT NULL
      AND realDate >= ?
      AND realDate <= ?
    ''',
    [fromStr, toStr],
  );

  final value = result.first['total'];
  return (value as num?)?.toDouble() ?? 0.0;
}

Future<int> countDocuments({
  required DateTime from,
  required DateTime to,
}) async {
  final db = await LocalDB.instance();

  final String fromStr = from.toIso8601String();
  final String toStr = to.toIso8601String();

  final result = await db.rawQuery(
    '''
    SELECT COUNT(*) as count
    FROM documents
    WHERE realDate >= ?
      AND realDate <= ?
    ''',
    [fromStr, toStr],
  );

  return Sqflite.firstIntValue(result) ?? 0;
}

Future<double> sumDocuments({
  required DateTime from,
  required DateTime to,
}) async {
  final db = await LocalDB.instance();

  final String fromStr = from.toIso8601String();
  final String toStr = to.toIso8601String();

  final result = await db.rawQuery(
    '''
    SELECT SUM(amount) as total
    FROM documents
    WHERE realDate >= ?
      AND realDate <= ?
    ''',
    [fromStr, toStr],
  );

  final value = result.first['total'];
  return (value as num?)?.toDouble() ?? 0.0;
}

Future<double> sumDocumentsTips({
  required DateTime from,
  required DateTime to,
}) async {
  final db = await LocalDB.instance();

  final String fromStr = from.toIso8601String();
  final String toStr = to.toIso8601String();

  final result = await db.rawQuery(
    '''
    SELECT SUM(tips) as total
    FROM documents
    WHERE realDate >= ?
      AND realDate <= ?
    ''',
    [fromStr, toStr],
  );

  final value = result.first['total'];
  return (value as num?)?.toDouble() ?? 0.0;
}

Future<int> countDocumentsByDeliveryService({
  required DateTime from,
  required DateTime to,
  required String deliveryService,
}) async {
  final db = await LocalDB.instance();

  final String fromStr = from.toIso8601String();
  final String toStr = to.toIso8601String();

  final result = await db.rawQuery(
    '''
    SELECT COUNT(*) as count
    FROM documents
    WHERE deliveryService = ?
      AND realDate >= ?
      AND realDate <= ?
    ''',
    [deliveryService, fromStr, toStr],
  );

  return Sqflite.firstIntValue(result) ?? 0;
}

Future<double> sumDocumentsByDeliveryServiceAmount({

  required DateTime from,
  required DateTime to,
  required String deliveryService,
}) async {
  final db = await LocalDB.instance();

  final String fromStr = from.toIso8601String();
  final String toStr = to.toIso8601String();

  final result = await db.rawQuery(
    '''
    SELECT SUM(amount) as total
    FROM documents
    WHERE deliveryService = ?
      AND realDate >= ?
      AND realDate <= ?
    ''',
    [deliveryService, fromStr, toStr],
  );

  final value = result.first['total'];
  return (value as num?)?.toDouble() ?? 0.0;
}


Future<int> countDocumentsBanco({
  required DateTime from,
  required DateTime to,
}) async {
  final db = await LocalDB.instance();

  final String fromStr = from.toIso8601String();
  final String toStr = to.toIso8601String();

  final result = await db.rawQuery(
    '''
    SELECT COUNT(*) as count
    FROM documents
    WHERE deliveryService IS NULL
      AND idTable IS NULL
      AND realDate >= ?
      AND realDate <= ?
    ''',
    [fromStr, toStr],
  );

  return Sqflite.firstIntValue(result) ?? 0;
}

Future<double> sumDocumentsBancoAmount({
  required DateTime from,
  required DateTime to,
}) async {
  final db = await LocalDB.instance();

  final String fromStr = from.toIso8601String();
  final String toStr = to.toIso8601String();

  final result = await db.rawQuery(
    '''
    SELECT SUM(amount) as total
    FROM documents
    WHERE deliveryService IS NULL
      AND idTable IS NULL
      AND realDate >= ?
      AND realDate <= ?
    ''',
    [fromStr, toStr],
  );

  final value = result.first['total'];
  return (value as num?)?.toDouble() ?? 0.0;
}

Future<Map?> isOpened() async {
    final resp  = await TurnoLavoro.getCurrentCashStatus();
    return resp;
} */

import 'package:dashboard/app/service/service_report.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:dashboard/modelli/category.dart';
import 'package:dashboard/modelli/document.dart';
import 'package:dashboard/state/banco_state.dart';
import 'package:dashboard/ui/screen/sincronizzazioni/databasesql_lite/local_db.dart';
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';



class ReportChiusura {

  //DOCUMENTI EMESSI
  int n_scontrini_incassati      = 0;
  int n_scontrini_sospesi        = 0;
  int n_scontrini_non_incassati  = 0;
  int n_scontrini_annullati      = 0;
  int n_fatture_incassate        = 0;
  int n_fatture_non_incassate    = 0;
  int n_note_credito             = 0;
  int n_totale_documenti         = 0;

  double scontrini_incassati     = 0;
  double scontrini_sospesi       = 0;
  double scontrini_non_incassati = 0;
  double scontrini_annullati     = 0;
  double fatture_incassate       = 0;
  double fatture_non_incassate   = 0;
  double note_credito            = 0;
  double totale_documenti        = 0;

  //vendite esenti
  double tabacchi                        = 0;
  double valori_bollati                  = 0;
  double giochi                          = 0;
  double gratta_e_vinci                  = 0;
  double biglietti                       = 0;
  double totale_prodotti_esenti          = 0;

  double mancia          = 0;
  int n_mancia           = 0;

  int n_tabacchi                   = 0;
  int n_valori_bollati             = 0;
  int n_giochi                     = 0;
  int n_gratta_e_vinci             = 0;
  int n_biglietti                  = 0;
  int n_totale_prodotti_esenti     = 0;

  Map<String, double>?  paymentsAmountAndQta;


  //MOVIMENTI DISTINTA CASSA
  double fondo_cassa_iniziale           = 0;
  double entrate_di_cassa               = 0;
  double uscite_di_cassa                = 0;
  double prelievi_cassetto_automatico   = 0;
  double fondo_cassa_finale             = 0;
  double totale_movimenti_cassa         = 0;

  //DETTAGLI STATISTICI
  int n_vedite_banco                    = 0;
  int n_vendite_consegne                = 0;
  int n_vendite_ritiri                  = 0;

  double vedite_banco                   = 0;
  double vendite_consegne               = 0;
  double vendite_ritiri                 = 0;

  double mance                          = 0;

  int n_scontrini                       = 0;
  double media_scontrini                = 0;

  //SALE
  int    n_coperti                      = 0;
  double media_coperti                  = 0;


  List<Map<String,dynamic>>? tipiCategoria  = [];
  List<Map<String,dynamic>>? products       = [];
  List<Map<String,dynamic>>? categories     = [];
  List<Map<String,dynamic>>? castellettoIva = [];

  int n_simulation                       = 0;
  double simulation                         = 0;

  int    n_sconti                        = 0;
  double sconti                          = 0;

  int    n_maggiorazioni                     = 0;
  double maggiorazioni                       = 0;

  ReportChiusura({
    this.n_scontrini_incassati      = 0,
    this.n_scontrini_sospesi        = 0,
    this.n_scontrini_non_incassati  = 0,
    this.n_scontrini_annullati      = 0,
    this.n_fatture_incassate        = 0,
    this.n_fatture_non_incassate    = 0,
    this.n_note_credito             = 0,
    this.n_totale_documenti         = 0,

    this.scontrini_incassati        = 0,
    this.scontrini_sospesi          = 0,
    this.scontrini_non_incassati    = 0,
    this.scontrini_annullati        = 0,
    this.fatture_incassate          = 0,
    this.fatture_non_incassate      = 0,
    this.note_credito               = 0,
    this.totale_documenti           = 0,

    this.tabacchi                   = 0,
    this.valori_bollati             = 0,
    this.giochi                     = 0,
    this.gratta_e_vinci             = 0,
    this.biglietti                  = 0,
    this.totale_prodotti_esenti     = 0,

    this.n_tabacchi                 = 0,
    this.n_valori_bollati           = 0,
    this.n_giochi                   = 0,
    this.n_gratta_e_vinci           = 0,
    this.n_biglietti                = 0,
    this.n_totale_prodotti_esenti   = 0,

    this.n_mancia                   = 0,
    this.mancia                     = 0,

    this.paymentsAmountAndQta,

    this.fondo_cassa_iniziale           = 0,
    this.entrate_di_cassa               = 0,
    this.uscite_di_cassa                = 0,
    this.prelievi_cassetto_automatico   = 0,
    this.fondo_cassa_finale             = 0,
    this.totale_movimenti_cassa         = 0,

    this.n_vedite_banco             = 0,
    this.n_vendite_consegne         = 0,
    this.n_vendite_ritiri           = 0,

    this.vedite_banco               = 0,
    this.vendite_consegne           = 0,
    this.vendite_ritiri             = 0,

    this.mance                      = 0,
    this.media_scontrini            = 0,

    this.n_coperti                  = 0,
    this.media_coperti              = 0,

    this.tipiCategoria,
    this.products,

    this.castellettoIva,
    this.n_simulation                = 0,
    this.simulation                  = 0,

    this.n_sconti                    = 0,
    this.sconti                      = 0,
    this.n_maggiorazioni             = 0,
    this.maggiorazioni               = 0,
  });


  static Future<ReportChiusura> report(
    bool simulazione,
    DateTime from,
    DateTime to, {
    String? uuidRigaTurno,
    bool? reportGenerale,
  }) async {
    ReportChiusura rep = ReportChiusura();
    try {
      List<Documento> allDoc = await getDocuments(
        from: from,
        to: to,
        uuidRigaTurno: uuidRigaTurno,
      );

      

      rep.products             = [];
      rep.categories           = [];
      rep.tipiCategoria        = [];
      rep.castellettoIva       = [];
      rep.paymentsAmountAndQta = {};

      // PER PAGAMENTI
      allDoc.forEach((d) {

        //SCONTi
        if( ((d.footDiscount ?? 0) *-1) > 0 ){
          rep.n_sconti ++;
          rep.sconti = rep.sconti + ((d.footDiscount ?? 0) *-1);
        }

        d.payments.forEach((p) {

          if( d.overrideMovementType == 'simulation' ){
            rep.n_simulation ++;
            rep.simulation += d.amount + (d.tips ?? 0); 
          }

          //if( d.overrideMovementType == 'simulation' ) return;
          if (rep.paymentsAmountAndQta!.keys.contains(p.title)) {
            rep.paymentsAmountAndQta![p.title] = rep.paymentsAmountAndQta![p.title]! + p.amount;
            rep.paymentsAmountAndQta![p.title + '_qta'] = rep.paymentsAmountAndQta![p.title + '_qta']! + 1;
          } else {
            rep.paymentsAmountAndQta![p.title] = p.amount;
            rep.paymentsAmountAndQta![p.title + '_qta'] = 1;
          }
        });
      });

      // PER ARTICOLI
      for (final d in allDoc) {
        if(d.overrideMovementType == 'simulation' && !simulazione){
          
        }else{
            for (final a in d.copyCart) {
            
            //SCONTI/maggiorazioni
            try{
              double originalPrice = double.parse(a.article.price ?? '0');
              double finalPrice    = a.priceRowCart / a.quantity;
              double differenza    = originalPrice - finalPrice; 
              if( differenza > 0 ){
                rep.n_sconti =  rep.n_sconti + 1;
                rep.sconti = rep.sconti + (differenza);
              }

              if( a.article.title.contains('Maggiorazione') ){
                rep.n_maggiorazioni = rep.n_maggiorazioni + 1;
                rep.maggiorazioni   = rep.maggiorazioni + a.priceRowCart;
              } 
            }catch( err ){
              debugPrint( err.toString() );
            }

            CategoryModel? categoryProduct = await getCategoryByArticle(idArticle: a.article.id);
            if (categoryProduct != null) {
              int indexCategory = rep.categories!.indexWhere((cc) => cc['id'] == categoryProduct.id);
              if (indexCategory == -1) {
                rep.categories!.add({'id': categoryProduct.id, 'title': categoryProduct.title, 'qta': a.quantity, 'amount': a.priceRowCart});
              } else {
                rep.categories![indexCategory]['amount'] = rep.categories![indexCategory]['amount'] + a.priceRowCart;
                rep.categories![indexCategory]['qta']    = rep.categories![indexCategory]['qta'] + a.quantity;
              }
            }

            if (categoryProduct != null) {
              int indexCategory = rep.tipiCategoria!.indexWhere((cc) => cc['tipology'] == categoryProduct.tipology);
              if (categoryProduct.tipology != null && categoryProduct.tipology!.isNotEmpty) {
                if (indexCategory == -1) {
                  rep.tipiCategoria!.add({'tipology': categoryProduct.tipology, 'amount': a.priceRowCart});
                } else {
                  rep.tipiCategoria![indexCategory]['amount'] = rep.tipiCategoria![indexCategory]['amount'] + a.priceRowCart;
                }
              }
            }

            // CASTELLETTO IVA
            if( d.overrideMovementType != 'simulation '){
              int indexIva = rep.castellettoIva!.indexWhere((i) => i['id'] == a.article.idVatRate);
              if (indexIva == -1) {
                rep.castellettoIva!.add({'id': a.article.idVatRate, 'value': a.article.rateValue, 'amount': a.priceRowCart - a.priceNetRow, 'net': a.priceNetRow});
              } else {
                rep.castellettoIva![indexIva]['amount'] = rep.castellettoIva![indexIva]['amount'] + a.priceRowCart - a.priceNetRow;
                rep.castellettoIva![indexIva]['net']    = rep.castellettoIva![indexIva]['net'] + a.priceNetRow;
              }
            }
            

            // prodotti esenti
            double vat = double.parse(a.article.rateValue ?? '0');
            if (vat == 0) rep.n_totale_prodotti_esenti = rep.n_totale_prodotti_esenti + a.quantity.toInt();
            if (vat == 0) rep.totale_prodotti_esenti   = rep.totale_prodotti_esenti   + a.priceRowCart;

            switch (a.article.articleType) {
              case ArticleType.gambling:
                rep.n_giochi = rep.n_giochi + a.quantity.toInt();
                rep.giochi   = rep.giochi   + a.priceRowCart;
                break;
              case ArticleType.tobaccos:
                rep.n_tabacchi = rep.n_tabacchi + a.quantity.toInt();
                rep.tabacchi   = rep.tabacchi   + a.priceRowCart;
                break;
              case ArticleType.revenueStamps:
                rep.n_valori_bollati = rep.n_valori_bollati + a.quantity.toInt();
                rep.valori_bollati   = rep.valori_bollati   + a.priceRowCart;
                break;
              case ArticleType.ticket:
                rep.n_biglietti = rep.n_biglietti + a.quantity.toInt();
                rep.biglietti   = rep.biglietti   + a.priceRowCart;
                break;
              case ArticleType.scratchAndWin:
                rep.n_gratta_e_vinci = rep.n_gratta_e_vinci + a.quantity.toInt();
                rep.gratta_e_vinci   = rep.gratta_e_vinci   + a.priceRowCart;
                break;
              default:
                break;
            }

            if( a.article.title == 'Mancia' ){
              rep.n_mancia ++;
              rep.mancia   += a.priceRowCart;
            }

            final exist = rep.products!.indexWhere((aa) => aa['id'] == a.article.id);
            if (exist == -1) {
              rep.products!.add({'id': a.article.id, 'title': a.article.title, 'qta': a.quantity, 'amount': a.priceRowCart});
            } else {
              rep.products![exist]['qta']    = rep.products![exist]['qta'] + a.quantity;
              rep.products![exist]['amount'] = rep.products![exist]['amount'] + a.priceRowCart;
            }
          }
        }
        
      }

      rep.n_scontrini_incassati = await countDocumentsRt(from: from, to: to, uuidRigaTurno: uuidRigaTurno);
      rep.n_scontrini           = await countDocumentsRt(from: from, to: to, uuidRigaTurno: uuidRigaTurno);
      rep.n_fatture_incassate   = await countDocumentsInvoice(from: from, to: to, uuidRigaTurno: uuidRigaTurno);
      rep.n_scontrini_annullati = await countDocumentsRtDeleted(from: from, to: to, uuidRigaTurno: uuidRigaTurno);
      rep.n_note_credito        = await countDocumentsCreditNote(from: from, to: to, uuidRigaTurno: uuidRigaTurno);
      rep.n_totale_documenti    = await countDocuments(from: from, to: to, uuidRigaTurno: uuidRigaTurno) - rep.n_note_credito - rep.n_scontrini_annullati;

      rep.scontrini_incassati   = await sumDocumentsRtAmountAndTips(from: from, to: to, uuidRigaTurno: uuidRigaTurno);
      rep.fatture_incassate     = await sumDocumentsInvoiceAmount(from: from, to: to, uuidRigaTurno: uuidRigaTurno);
      rep.note_credito          = await sumDocumentsNoteCreditAmount(from: from, to: to, uuidRigaTurno: uuidRigaTurno);
      rep.scontrini_annullati   = await sumDocumentsRtDeletedAmount(from: from, to: to, uuidRigaTurno: uuidRigaTurno);
      rep.totale_documenti      = await sumDocuments(from: from, to: to, uuidRigaTurno: uuidRigaTurno) - rep.note_credito - rep.scontrini_annullati;

      if( !bancoAbilitato.value ) rep.totale_documenti = rep.totale_documenti - rep.simulation;

      if( !bancoAbilitato.value ){
        rep.media_scontrini       =  double.parse(((rep.totale_documenti - rep.note_credito - rep.scontrini_annullati) / (rep.n_totale_documenti - rep.n_simulation)).toStringAsFixed(2));

      }else{
        rep.media_scontrini       =  double.parse(((rep.totale_documenti - rep.note_credito - rep.scontrini_annullati) / rep.n_totale_documenti).toStringAsFixed(2));
      }

      if ( rep.media_scontrini.isNaN ) rep.media_scontrini = 0;

      rep.mance                 = await sumDocumentsTips(from: from, to: to, uuidRigaTurno: uuidRigaTurno);

      rep.n_vendite_ritiri      = await countDocumentsByDeliveryService(from: from, to: to, deliveryService: 'takeAway',  uuidRigaTurno: uuidRigaTurno);
      rep.n_vendite_consegne    = await countDocumentsByDeliveryService(from: from, to: to, deliveryService: 'delivery',  uuidRigaTurno: uuidRigaTurno);

      rep.n_vedite_banco        = await countDocumentsBanco(from: from, to: to, uuidRigaTurno: uuidRigaTurno);


      rep.vedite_banco          = await sumDocumentsBancoAmount(from: from, to: to,    uuidRigaTurno: uuidRigaTurno);
      rep.vendite_consegne      = await sumDocumentsDeliveryAmount(from: from, to: to, uuidRigaTurno: uuidRigaTurno); 
      rep.vendite_ritiri        = await sumDocumentsTakeAwayAmount(from: from, to: to, uuidRigaTurno: uuidRigaTurno);

      Map<String, double> respCassa           = await getTotaliMovimentiCassa(dataFine: to,dataInizio: from, uuidTurno: reportGenerale != null ? null : uuidRigaTurno);

      rep.fondo_cassa_iniziale = reportGenerale != null ? await TurnoLavoro.fondoInizialeOggiGenerale() : await TurnoLavoro.fondoIniziale(uuidRigaTurno);
      rep.fondo_cassa_finale   = reportGenerale == true ? await TurnoLavoro.fondoFinaleOggi() : await TurnoLavoro.fondoFinale(uuidRigaTurno);
      rep.entrate_di_cassa = respCassa['totale_entrate'] as double;
      rep.uscite_di_cassa  = respCassa['totale_uscite']  as double;
      rep.totale_movimenti_cassa = rep.entrate_di_cassa - rep.uscite_di_cassa + rep.fondo_cassa_iniziale;

    } catch (err) {
      debugPrint(err.toString());
    } finally {
      return rep;
    }
  }
}


// ─── HELPERS ────────────────────────────────────────────────────────────────

String _uuidFilter(String? uuid) => uuid != null ? 'AND uuid_riga_turno = ?' : '';

List<dynamic> _args(String fromStr, String toStr, String? uuid) {
  final args = <dynamic>[fromStr, toStr];
  if (uuid != null) args.add(uuid);
  return args;
}

Future<Map<String, double>> getTotaliMovimentiCassa({
  String? uuidTurno,             
  required DateTime dataInizio,
  required DateTime dataFine,
}) async {
  final db = await LocalDB.instance();

  // WHERE dinamica
  final whereConditions = <String>[
    'deleted = 0',
    'data_ora_creazione >= ?',
    'data_ora_creazione <= ?',
  ];
  final whereArgs = <dynamic>[
    dataInizio.toIso8601String(),
    dataFine.toIso8601String(),
  ];

  if (uuidTurno != null) {
    whereConditions.add('uuid_turno = ?');
    whereArgs.add(uuidTurno);
  }

  final result = await db.rawQuery('''
    SELECT
      COALESCE(SUM(CASE WHEN tipo_movimento = 'entrata' THEN importo ELSE 0 END), 0) AS totale_entrate,
      COALESCE(SUM(CASE WHEN tipo_movimento = 'uscita'  THEN importo ELSE 0 END), 0) AS totale_uscite
    FROM movimenti_cassa
    WHERE ${whereConditions.join(' AND ')}
  ''', whereArgs);

  if (result.isEmpty) {
    return {'totale_entrate': 0.0, 'totale_uscite': 0.0};
  }

  return {
    'totale_entrate': (result.first['totale_entrate'] as num).toDouble(),
    'totale_uscite':  (result.first['totale_uscite']  as num).toDouble(),
  };
}
// ─── QUERY FUNCTIONS ────────────────────────────────────────────────────────

Future<List<Documento>> getDocuments({
  required DateTime from,
  required DateTime to,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT *
    FROM documents
    WHERE realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ORDER BY realDate ASC
    ''',
    _args(from.toIso8601String(), to.toIso8601String(), uuidRigaTurno),
  );
  return result.map((row) => Documento.fromMap(row)).toList();
}


Future<CategoryModel?> getCategoryByArticle({
  required int idArticle,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT c.*
    FROM categories c
    INNER JOIN articlesCategories ac ON ac.idCategory = c.id
    WHERE ac.idArticle = ?
    LIMIT 1
    ''',
    [idArticle],
  );
  if (result.isEmpty) return null;
  return CategoryModel.fromJson(result.first);
}


Future<int> countDocumentsRt({
  required DateTime from,
  required DateTime to,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT COUNT(*) as count
    FROM documents
    WHERE overrideMovementType IS NULL
      AND realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    _args(from.toIso8601String(), to.toIso8601String(), uuidRigaTurno),
  );
  return Sqflite.firstIntValue(result) ?? 0;
}


Future<double> sumDocumentsRtAmount({
  required DateTime from,
  required DateTime to,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT SUM(amount) as total
    FROM documents
    WHERE overrideMovementType IS NULL
      AND realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    _args(from.toIso8601String(), to.toIso8601String(), uuidRigaTurno),
  );
  return (result.first['total'] as num?)?.toDouble() ?? 0.0;
}

Future<double> sumDocumentsRtAmountAndTips({
  required DateTime from,
  required DateTime to,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT SUM(amount + COALESCE(tips, 0)) as total
    FROM documents
    WHERE overrideMovementType IS NULL
      AND realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    _args(from.toIso8601String(), to.toIso8601String(), uuidRigaTurno),
  );
  return (result.first['total'] as num?)?.toDouble() ?? 0.0;
}


Future<int> countDocumentsCreditNote({
  required DateTime from,
  required DateTime to,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT COUNT(*) as count
    FROM documents
    WHERE overrideMovementType = 'credit_note'
      AND realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    _args(from.toIso8601String(), to.toIso8601String(), uuidRigaTurno),
  );
  return Sqflite.firstIntValue(result) ?? 0;
}


Future<double> sumDocumentsNoteCreditAmount({
  required DateTime from,
  required DateTime to,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT SUM(amount) as total
    FROM documents
    WHERE overrideMovementType = 'credit_note'
      AND realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    _args(from.toIso8601String(), to.toIso8601String(), uuidRigaTurno),
  );
  return (result.first['total'] as num?)?.toDouble() ?? 0.0;
}


Future<int> countDocumentsSimulation({
  required DateTime from,
  required DateTime to,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT COUNT(*) as count
    FROM documents
    WHERE overrideMovementType = 'simulation'
      AND realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    _args(from.toIso8601String(), to.toIso8601String(), uuidRigaTurno),
  );
  return Sqflite.firstIntValue(result) ?? 0;
}


Future<int> countDocumentsInvoice({
  required DateTime from,
  required DateTime to,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT COUNT(*) as count
    FROM documents
    WHERE overrideMovementType = 'invoice'
      AND realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    _args(from.toIso8601String(), to.toIso8601String(), uuidRigaTurno),
  );
  return Sqflite.firstIntValue(result) ?? 0;
}


Future<double> sumDocumentsInvoiceAmount({
  required DateTime from,
  required DateTime to,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT SUM(amount + COALESCE(tips, 0)) as total
    FROM documents
    WHERE overrideMovementType = 'invoice'
      AND realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    _args(from.toIso8601String(), to.toIso8601String(), uuidRigaTurno),
  );
  return (result.first['total'] as num?)?.toDouble() ?? 0.0;
}


Future<int> countDocumentsRtDeleted({
  required DateTime from,
  required DateTime to,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT COUNT(*) as count
    FROM documents
    WHERE overrideMovementType IS "cancel_rt"
      AND realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    _args(from.toIso8601String(), to.toIso8601String(), uuidRigaTurno),
  );
  return Sqflite.firstIntValue(result) ?? 0;
}


Future<double> sumDocumentsRtDeletedAmount({
  required DateTime from,
  required DateTime to,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT SUM(amount) as total
    FROM documents
    WHERE overrideMovementType IS "cancel_rt"
      AND realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    _args(from.toIso8601String(), to.toIso8601String(), uuidRigaTurno),
  );
  return (result.first['total'] as num?)?.toDouble() ?? 0.0;
}


Future<int> countDocuments({
  required DateTime from,
  required DateTime to,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT COUNT(*) as count
    FROM documents
    WHERE realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    _args(from.toIso8601String(), to.toIso8601String(), uuidRigaTurno),
  );
  return Sqflite.firstIntValue(result) ?? 0;
}


Future<double> sumDocuments({
  required DateTime from,
  required DateTime to,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT SUM(amount + COALESCE(tips, 0)) as total
    FROM documents
    WHERE realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    _args(from.toIso8601String(), to.toIso8601String(), uuidRigaTurno),
  );
  return (result.first['total'] as num?)?.toDouble() ?? 0.0;
}


Future<double> sumDocumentsTips({
  required DateTime from,
  required DateTime to,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT SUM(tips) as total
    FROM documents
    WHERE realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    _args(from.toIso8601String(), to.toIso8601String(), uuidRigaTurno),
  );
  return (result.first['total'] as num?)?.toDouble() ?? 0.0;
}


Future<int> countDocumentsByDeliveryService({
  required DateTime from,
  required DateTime to,
  required String deliveryService,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final args = <dynamic>[deliveryService, from.toIso8601String(), to.toIso8601String()];
  if (uuidRigaTurno != null) args.add(uuidRigaTurno);
  final result = await db.rawQuery(
    '''
    SELECT COUNT(*) as count
    FROM documents
    WHERE deliveryService = ?
      AND realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    args,
  );
  return Sqflite.firstIntValue(result) ?? 0;
}


Future<double> sumDocumentsByDeliveryServiceAmount({
  required DateTime from,
  required DateTime to,
  required String deliveryService,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final args = <dynamic>[deliveryService, from.toIso8601String(), to.toIso8601String()];
  if (uuidRigaTurno != null) args.add(uuidRigaTurno);
  final result = await db.rawQuery(
    '''
    SELECT SUM(amount) as total
    FROM documents
    WHERE deliveryService = ?
      AND realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    args,
  );
  return (result.first['total'] as num?)?.toDouble() ?? 0.0;
}


Future<int> countDocumentsBanco({
  required DateTime from,
  required DateTime to,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT COUNT(*) as count
    FROM documents
    WHERE deliveryService IS NULL
      AND idTable IS NULL
      AND realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    _args(from.toIso8601String(), to.toIso8601String(), uuidRigaTurno),
  );
  return Sqflite.firstIntValue(result) ?? 0;
}


Future<double> sumDocumentsBancoAmount({
  required DateTime from,
  required DateTime to,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT SUM(amount + COALESCE(tips, 0)) as total
    FROM documents
    WHERE deliveryService IS NULL
      AND idTable IS NULL
      AND realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    _args(from.toIso8601String(), to.toIso8601String(), uuidRigaTurno),
  );
  return (result.first['total'] as num?)?.toDouble() ?? 0.0;
}

Future<double> sumDocumentsDeliveryAmount({
  required DateTime from,
  required DateTime to,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT SUM(amount) as total
    FROM documents
    WHERE deliveryService = "delivery"
      AND idTable IS NULL
      AND realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    _args(from.toIso8601String(), to.toIso8601String(), uuidRigaTurno),
  );
  return (result.first['total'] as num?)?.toDouble() ?? 0.0;
}

Future<double> sumDocumentsTakeAwayAmount({
  required DateTime from,
  required DateTime to,
  String? uuidRigaTurno,
}) async {
  final db = await LocalDB.instance();
  final result = await db.rawQuery(
    '''
    SELECT SUM(amount) as total
    FROM documents
    WHERE deliveryService = "takeAway"
      AND idTable IS NULL
      AND realDate >= ?
      AND realDate <= ?
      ${_uuidFilter(uuidRigaTurno)}
    ''',
    _args(from.toIso8601String(), to.toIso8601String(), uuidRigaTurno),
  );
  return (result.first['total'] as num?)?.toDouble() ?? 0.0;
}


Future<Map?> isOpened() async {
  final resp = await TurnoLavoro.getCurrentCashStatus();
  return resp;
}


