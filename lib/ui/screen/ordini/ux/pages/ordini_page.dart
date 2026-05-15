import 'package:dashboard/Global.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/ordini_list_controller.dart';
import '../widgets/ordine_header.dart';
import '../widgets/ordini_filters_bar.dart';
import '../widgets/ordini_footer.dart';
import '../widgets/ordini_table.dart';

class OrdiniPage extends StatefulWidget {
  const OrdiniPage({super.key});

  @override
  State<OrdiniPage> createState() => _OrdiniPageState();
}


class _OrdiniPageState extends State<OrdiniPage> with RouteAware {


  @override
  void initState() {
    super.initState();
  }

 @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdiniListController>().getOrders();
    });
  }

  @override
  void didPopNext() {
    context.read<OrdiniListController>().getOrders();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrdineHeader(),
      body: Column(
        children: [
          OrdiniFiltersBar(),
          OrdiniListHeaderM3(),
          Expanded(
            child:/*  Padding(
              padding: EdgeInsets.all(16),
              child: */   OrdiniListM3(key: Key( '${DateTime.now().microsecondsSinceEpoch}') ),
            /* ), */
          ),
        ],
      ),
      bottomNavigationBar: const OrdiniFooter(),
    );
  }
}
