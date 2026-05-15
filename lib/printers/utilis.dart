import 'dart:math';

extension FiscalRound on double {

  double roundTo(double value, int places) {
    num mod = pow(10, places);
    return ((value * mod).round().toDouble() / mod);
  }

  double fixDecimal(){
    double fixed = roundTo(this, 2);
    return fixed;
  }

}