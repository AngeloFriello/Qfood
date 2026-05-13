import 'package:intl/intl.dart';
import '../../../model/model_prenotazione.dart';
import '../../../model/prenotazione_channel.dart';
/*
Lista & CRUD prenotazioni
Model JSON API
costruisce payload corretto
formato date
idTable / idCustomer (gesrtisce api backend)
 */

class PrenotazioneApiMapper {
  static Map<String, dynamic> toApi(Prenotazione p) {
    final DateFormat fmt = DateFormat('yyyy-MM-dd HH:mm:ss');

    return {
      "title": p.clienteNome,
      "reservationStart": fmt.format(p.startDateTime),
      "reservationEnd": fmt.format(p.endDateTime),
      "reservationCovers": p.pax,
      "channel": "manual",
      "note": p.note ?? "",
      "idTable": p.tavoli.first,
      "idCustomer": p.clienteId,
      "metadata": "{}",
    };
  }
}


extension PrenotazioneChannelApi on PrenotazioneChannel {
  String get apiValue {
    switch (this) {
      case PrenotazioneChannel.manuale:
      case PrenotazioneChannel.flood:
        return 'manual';
      case PrenotazioneChannel.google:
        return 'google';
    }
  }
}
