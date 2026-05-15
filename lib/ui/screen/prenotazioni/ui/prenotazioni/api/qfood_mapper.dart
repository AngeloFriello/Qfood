import '../../../model/prenotazione_channel.dart';

class QfoodMapper {

  static String channel(PrenotazioneChannel c) {
    switch (c) {
      case PrenotazioneChannel.manuale:
        return 'manual';
      case PrenotazioneChannel.flood:
        return 'flood';
      case PrenotazioneChannel.google:
        return 'google';
    }
  }

}
