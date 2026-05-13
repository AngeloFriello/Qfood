import 'package:dashboard/ui/screen/ordini/models/ordine.dart';

//Stato comune, semplice, riutilizzabile
class OrdineState {
  final Ordine? ordine;
  final bool isLoading;
  final bool isDirty;

  const OrdineState({
    this.ordine,
    this.isLoading = false,
    this.isDirty = false,
  });

  bool get hasOrdine => ordine != null;

  OrdineState copyWith({
    Ordine? ordine,
    bool? isLoading,
    bool? isDirty,
  }) {
    return OrdineState(
      ordine: ordine ?? this.ordine,
      isLoading: isLoading ?? this.isLoading,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}
