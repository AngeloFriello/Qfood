import 'package:flutter/material.dart';

class QwertyKeyboard extends StatelessWidget {
  final TextEditingController controller;

  const QwertyKeyboard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final keys = [
      ["Q","W","E","R","T","Y","U","I","O","P"],
      ["A","S","D","F","G","H","J","K","L"],
      ["Z","X","C","V","B","N","M"],
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...keys.map((row) => _buildRow(row)),
          const SizedBox(height: 8),

          /// SPAZIO + BACKSPACE
          Row(
            children: [
              _key("␣", flex: 3, onTap: () {
                controller.text += " ";
              }),
              _key("⌫", flex: 1, onTap: () {
                if (controller.text.isNotEmpty) {
                  controller.text =
                      controller.text.substring(0, controller.text.length - 1);
                }
              }),
            ],
          ),

          const SizedBox(height: 8),

          /// CHIUDI
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8BC540),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Conferma",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> letters) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: letters.map<Widget>((l) {
        return _key(
          l,
          onTap: () {
            controller.text += l;
            controller.selection = TextSelection.collapsed(
              offset: controller.text.length,
            );
          },
        );
      }).toList(),
    );
  }

  Widget _key(String label,
      {int flex = 1, required VoidCallback onTap}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade800,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
