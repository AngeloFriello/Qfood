enum OrdineStato {
  nuovo,
  inPreparazione,
  pronto,
  partito,
  completato,
  annullato,
}

OrdineStato typeStateOrderFromString (String typeString ){
  switch (typeString) {
    case 'Nuovo':
      return OrdineStato.nuovo;
    case 'In preparazione':
      return OrdineStato.inPreparazione;
    case 'Pronto':
      return OrdineStato.pronto;
    case 'Partito':
      return OrdineStato.partito;
    case 'Completato':
      return OrdineStato.completato;
    case 'Annullato':
      return OrdineStato.annullato;
    default:
      return OrdineStato.annullato;
  }
}

extension OrdineStatoX on OrdineStato {
  String get label {
    switch (this) {
      case OrdineStato.nuovo:
        return 'Nuovo';
      case OrdineStato.inPreparazione:
        return 'In preparazione';
      case OrdineStato.pronto:
        return 'Pronto';
      case OrdineStato.partito:
        return 'Partito';
      case OrdineStato.completato:
        return 'Completato';
      case OrdineStato.annullato:
        return 'Annullato';
    }
  }

  bool get isFinale {
    switch (this) {
      case OrdineStato.completato:
      case OrdineStato.annullato:
        return true;
      default:
        return false;
    }
  }
}
