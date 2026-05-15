
import 'package:dashboard/ui/screen/documents/documents_list.dart';
import 'package:flutter/material.dart';

class DocumentsPage extends StatefulWidget {
  final VoidCallback onClose;
  final GlobalKey<DocumentsListState> keyList;
  const DocumentsPage({
    super.key,
    required this.onClose,
    required this.keyList
  });

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: DocumentsList(
              key: widget.keyList,
              onClose: widget.onClose,
            ),
          ),
        ],
      ),
    );
  }
}
