import 'package:dashboard/Global.dart';
import 'package:dashboard/modelli/articleWithPriceList.dart';
import 'package:dashboard/modelli/department.dart';
import 'package:dashboard/state/controller_carrello.dart';
import 'package:dashboard/ui/widget/tastierino/tastierino_popup.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RepartiList extends StatefulWidget {
  final ValueChanged<int> onRepartoSelezionato;
  final GlobalKey tastierinoKey;
  const RepartiList({
    super.key,
    required this.onRepartoSelezionato,
    required this.tastierinoKey
  });

  @override
  State<RepartiList> createState() => _RepartiListState();
}


class _RepartiListState extends State<RepartiList> {
  bool loading = true;
  List<DepartmentModel> reparti = [];
  int? selezionato;
  int? selezionatoAliquota; // 4, 10, 22


  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("posToken") ??
                  prefs.getString("token") ??
                  prefs.getString("jwt");

    if (token == null) {
      setState(() => loading = false);
      return;
    }

    try{
      final departments = await DepartmentModel.getByDb();
      setState(() {
        reparti = departments;
        loading = false;
      });
    }catch( err ){
      debugPrint(err.toString());
      setState(() {
        loading = false;
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: reparti.length,
      itemBuilder: (context, index) {
        final r = reparti[index];
        final aliquota = int.tryParse(
          r.titleRate!.replaceAll('%', ''),
        );

        final bool attivo = aliquota != null && selezionatoAliquota == aliquota;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: GestureDetector(
            onTap: () async {
              final carrello        = context.read<CarrelloController>();
              final articleGeneric_ = await getGenericProduct();

              if( articleGeneric_ == null ) return;
              ArticleWhitPriceListModel artDeperment = ArticleWhitPriceListModel(
                                                                                  articleType: ArticleType.product,code: articleGeneric_['code'],
                                                                                  id: articleGeneric_['id'],
                                                                                  title: reparti[index].title,
                                                                                  idVatRate: reparti[index].idRate,
                                                                                  rateValue: reparti[index].valueRate
                                                                                );
              ( widget.tastierinoKey.currentWidget as TastierinoCompattoFisso).applicaProdotto(  artDeperment, carrello, true );
              debugPrint(reparti[index].toString());
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: attivo
                    ? const Color(0xFF97D700)
                    : const Color(0xFF6A6A6A),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(attivo ? 0.3 : 0.1),
                    blurRadius: attivo ? 10 : 4,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    r.title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: attivo ? Colors.black : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${r.titleRate} • Reparto ${r.departmentNumber}",
                    style: TextStyle(
                      color: attivo
                          ? Colors.black87
                          : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
