enum VarianteTipo {
  plusMinus,
  plus,
  minus,
  info,
  libera,
}

class VarianteTipoMapper {
  static VarianteTipo fromApi(dynamic value) {
    final type = value?.toString().toLowerCase();

    switch (type) {
      case 'plus':
        return VarianteTipo.plus;
      case 'minus':
        return VarianteTipo.minus;
      case 'plus_minus':
      case 'plusminus':
      case '+-':
        return VarianteTipo.plusMinus;
      case 'info':
        return VarianteTipo.info;
      default:
        return VarianteTipo.plus;
    }
  }
}
