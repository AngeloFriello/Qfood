import 'package:flutter/material.dart';
import 'package:dashboard/ui/screen/ordini/ux/widgets/ordine_card.dart';
import '../../models/ordine.dart';


//Lista ordini (desktop + mobile)
class OrdineList extends StatelessWidget {
  final void Function(Ordine ordine) onOrdineTap;
  final List<Ordine> orders;
  const OrdineList({
    super.key,
    required this.orders,
    required this.onOrdineTap,
  });

  @override
  Widget build(BuildContext context) {


    if (orders.isEmpty) {
      return const Center(
        child: Text('Nessun ordine'),
      );
    }
  

    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        return OrdineCard(
          ordine: orders[index],
          onTap: () => onOrdineTap(orders[index]),
        );
      },
    );
  }
}
