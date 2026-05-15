import 'package:dashboard/modelli/articleInCart.dart';
import 'package:flutter/material.dart';

//Riga prodotto (view + edit)
class OrdineItemRow extends StatelessWidget {
  final ProdottoCarrello item;
  final bool editable;

  const OrdineItemRow({
    super.key,
    required this.item,
    this.editable = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.article.title),
      subtitle: Text(
        '€${item.priceRowCart.toStringAsFixed(2)}',
      ),
      trailing: editable
          ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              // gestito dal controller padre
            },
          ),
          Text('${item.quantity}'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // gestito dal controller padre
            },
          ),
        ],
      )
          : Text('x${item.quantity}'),
    );
  }
}
