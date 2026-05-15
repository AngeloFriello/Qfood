
import 'dart:convert';

class Printer {
  final int     port;
  final String  ipAddress;
  final int     buzzNumberTransfer;
  final int     buzzNumber;

  Printer({
    required this.port,
    required this.ipAddress,
    required this.buzzNumberTransfer,
    required this.buzzNumber
  });

  factory Printer.fromMap(dynamic map){
    return Printer(
      port:                  map['port'], 
      ipAddress:             map['ipAddress'],
      buzzNumberTransfer:    map['buzzNumberTransfer'],
      buzzNumber:            map['buzzNumber'],
    );
  }

  dynamic toMap () {
    return 
      {
        "port"                 :port,
        "ipAddress"            :ipAddress,
        "buzzNumberTransfer"   :buzzNumberTransfer,
        "buzzNumber"           :buzzNumber,
      };
    
  }

}


class PrinterForArticle {
  final int idArticle;
  final List<Printer> printersBench;
  final List<Printer> printersRoom;
  final List<Printer> printersSummary;

  PrinterForArticle({
    required this.idArticle,
    required this.printersBench,
    required this.printersRoom,
    required this.printersSummary
  });

  Map<String, dynamic> toMap() {
    return (
      {
        'idArticle'       : idArticle,
        'printersBench'   : jsonEncode(printersBench.map((p) => p.toMap()).toList()) ,
        'printersRoom'    : jsonEncode(printersRoom.map((p) => p.toMap()).toList()),
        'printersSummary' : jsonEncode(printersSummary.map((p) => p.toMap()).toList())
      }
    );
  }

  factory PrinterForArticle.fromMap(dynamic map){
    return PrinterForArticle(
      idArticle: map['idArticle'], 
      printersBench:   (map['printersBench']   as List<dynamic>).map((p)   => Printer.fromMap(p) ).toList(),
      printersRoom:    (map['printersRoom']    as List<dynamic>).map((p)    => Printer.fromMap(p) ).toList(),
      printersSummary: (map['printersSummary'] as List<dynamic>).map((p) => Printer.fromMap(p) ).toList(),
    );
  }

  factory PrinterForArticle.fromLocalDb(dynamic map){
    List<Printer> printersBench   = (jsonDecode( (map['printersBench'] as String  ) )    as List<dynamic> ).map((p)   => Printer.fromMap(p as dynamic) ).toList() as List<Printer>;
    List<Printer> printersRoom    = (jsonDecode( (map['printersRoom']   as String   ) )  as List<dynamic> ).map((p)  => Printer.fromMap(p as dynamic) ).toList() as List<Printer>;
    List<Printer> printersSummary = (jsonDecode( (map['printersSummary'] as String ) )   as List<dynamic> ).map((p)  => Printer.fromMap(p as dynamic) ).toList() as List<Printer>;

    return PrinterForArticle(
      idArticle: map['idArticle'], 
      printersBench:   printersBench,
      printersRoom:    printersRoom,
      printersSummary: printersSummary,
    );
  }

/*   static Future<List<Printer>> printers() async {
    List<Printer> list = [];
    try{
      final respDbLocal = await LocalDB.query('SELECT * FROM devices');
      list = respDbLocal.map((d) => Printer.fromMap(d)).toList();
    }catch( err ){

    }finally{
      return list;
    }
  } */
}