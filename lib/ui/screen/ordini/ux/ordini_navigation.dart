import 'package:flutter/material.dart';
import 'package:dashboard/ui/screen/ordini/state/ordine_attivo_controller.dart';


//Governa navigazione + dirty state
/*
Qui gestiamo blocco back
sicurezza dati
UX professionale POS
 */
class OrdiniNavigation {
  static Future<bool> canPop(
      BuildContext context,
      OrdineAttivoController controller,
      ) async {
    if (!controller.isDirty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifiche non salvate'),
        content: const Text(
          'Hai modifiche non salvate. Vuoi uscire comunque?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Esci'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  static void detachOrdine(
      OrdineAttivoController controller,
      ) {
    controller.clearOrdine();
  }
}
