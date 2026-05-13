enum OrdineTipo {
  ritiro,
  consegna,
  mangiaQui,
}

OrdineTipo typeOrderFromString (String typeString ){
  switch (typeString) {
    case 'takeAway':
      return OrdineTipo.ritiro;
    case 'delivery':
      return OrdineTipo.consegna;
    case 'eatHere':
      return OrdineTipo.mangiaQui;
    default:
      return OrdineTipo.consegna;
  }
}

String labelTipoOrdine (OrdineTipo t ){
  switch (t) {
    case OrdineTipo.consegna:
      return 'delivery';
    case OrdineTipo.mangiaQui:
      return 'eatHere';
    case OrdineTipo.ritiro:
      return 'takeAway';
    
  }
}

extension OrdineTipoX on OrdineTipo {
  String get label {
    switch (this) {
      case OrdineTipo.ritiro:
        return 'Ritiro';
      case OrdineTipo.consegna:
        return 'Consegna';
      case OrdineTipo.mangiaQui:
        return 'Mangia qui';
    }
  }
}
