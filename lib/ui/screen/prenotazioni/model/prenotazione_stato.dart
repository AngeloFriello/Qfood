enum PrenotazioneStato {
  confermato,
  daConfermare,
  rifiutato,
  arrivato,
  nonArrivato,
  cancellato,
  terminato,
  attesaCarta,
  tavoloPronto,
  inCoda,
}

extension PrenotazioneStatoLabel on PrenotazioneStato {
  String get label {
    switch (this) {
      case PrenotazioneStato.confermato:
        return 'Confermato';
      case PrenotazioneStato.daConfermare:
        return 'Da confermare';
      case PrenotazioneStato.rifiutato:
        return 'Rifiutato';
      case PrenotazioneStato.arrivato:
        return 'Arrivato';
      case PrenotazioneStato.nonArrivato:
        return 'Non arrivato';
      case PrenotazioneStato.cancellato:
        return 'Cancellato';
      case PrenotazioneStato.terminato:
        return 'Terminato';
      case PrenotazioneStato.attesaCarta:
        return 'Attesa carta';
      case PrenotazioneStato.tavoloPronto:
        return 'Tavolo pronto';
      case PrenotazioneStato.inCoda:
        return 'In coda';
    }
  }
}
