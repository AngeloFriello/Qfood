class Room {
  final int id;
  final String title;
  final String? service;       //PERCENTUALE DEL SERVIZIO
  final int? visibleForWaiter;
  final int? indicateCovers;    // RICHIEDI COPERTO APERTURA TAVOLO
  final int? mandatoryCover;   //COPERTO OBBLIGATORIO
  final int? automaticService; //servizio automatico
  final int? indicatePriceList; //SCELTA DEL LISTINO ALL'APERTURA DEL TAVOLO
  final int? idPriceList;      //ID LISTINO ABBINATO ALLA SALA
  final int? idVatRate; // IVA DEL SERVIZIO
  final int? idDevice; //È possibile configurare nella sala un dispositivo associato che permette di legare quella specifica sala all'uso della stampante fiscale e secondaria definita nel dispositivo scelto.
  final int enabled;

  Room({
    required this.id,
    required this.title,
    this.service,
    this.visibleForWaiter,
    this.indicateCovers,
    this.indicatePriceList,
    this.automaticService,
    required this.enabled,
    this.idDevice,
    this.idVatRate,
    this.idPriceList,
    this.mandatoryCover,
    
  });

  factory Room.fromMap(Map<String, dynamic> map) => Room(
      id: map['id'] as int,
      title: map['title'] as String,
      service: map['service'] as String?,
      visibleForWaiter: map['visibleForWaiter'] as int?,
      indicateCovers: map['indicateCovers'] as int?,
      mandatoryCover: map['mandatoryCover'] as int?,
      automaticService: map['automaticService'] as int?,
      indicatePriceList: map['indicatePriceList'] as int?,
      idPriceList: map['idPriceList'] as int?,
      idVatRate: map['idVatRate'] as int?,
      idDevice: map['idDevice'] as int?,
      enabled: map['enabled'] as int,
    );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'service': service,
    'visibleForWaiter': visibleForWaiter,
    'indicateCovers': indicateCovers,
    'mandatoryCover': mandatoryCover,
    'automaticService': automaticService,
    'indicatePriceList': indicatePriceList,
    'idPriceList': idPriceList,
    'idVatRate': idVatRate,
    'idDevice': idDevice,
    'enabled': enabled,
  };
}
