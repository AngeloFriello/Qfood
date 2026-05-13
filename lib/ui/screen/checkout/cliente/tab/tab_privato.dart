import 'package:flutter/material.dart';

import '../../../../widget/selector/provincia_selector.dart';
import '../../../../widget/selector/stato_selector.dart';

class TabPrivato extends StatelessWidget {
  final TextEditingController nomeController;
  final TextEditingController cognomeController;
  final TextEditingController codiceFiscaleController;
  final TextEditingController indirizzoController;
  final TextEditingController capController;
  final TextEditingController cittaController;
  final TextEditingController telefonoController;
  final TextEditingController emailController;
  final TextEditingController dataNascitaController;
  final TextEditingController provinciaController;
  final TextEditingController statoController;



  const TabPrivato({
    super.key,
    required this.nomeController,
    required this.cognomeController,
    required this.codiceFiscaleController,
    required this.indirizzoController,
    required this.capController,
    required this.cittaController,
    required this.telefonoController,
    required this.emailController,
    required this.dataNascitaController,
    required this.provinciaController,
    required this.statoController,


  });


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardAnagraficaPrivato(
            nomeController: nomeController,
            cognomeController: cognomeController,
            codiceFiscaleController: codiceFiscaleController,
            dataNascitaController: dataNascitaController,
          ),
          _CardIndirizzoPrivato(
            indirizzoController: indirizzoController,
            capController: capController,
            cittaController: cittaController,
            provinciaController: provinciaController,
            statoController: statoController,
          ),
          _CardContattiPrivato(
            telefonoController: telefonoController,
            emailController: emailController,
          ),

        ],
      ),
    );
  }



}


// =======================================================
// ANAGRAFICA
// =======================================================
class _CardAnagraficaPrivato extends StatelessWidget {
  final TextEditingController nomeController;
  final TextEditingController cognomeController;
  final TextEditingController codiceFiscaleController;
  final TextEditingController dataNascitaController;



  const _CardAnagraficaPrivato({
    required this.nomeController,
    required this.cognomeController,
    required this.codiceFiscaleController,
    required this.dataNascitaController,

  });


  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: "Anagrafica privato",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _input(
                  "Nome",
                  controller: nomeController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _input(
                  "Cognome",
                  controller: cognomeController,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _input(
                  "Data di nascita",
                  controller: dataNascitaController,
                  icon: Icons.calendar_today,
                  readOnly: false,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      locale: const Locale('it', 'IT'), //QUESTO È FONDAMENTALE
                      initialDate: DateTime(1990),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      helpText: "Seleziona data di nascita",
                      cancelText: "Annulla",
                      confirmText: "OK",
                    );

                    if (picked != null) {
                      dataNascitaController.text =
                      "${picked.day.toString().padLeft(2, '0')}/"
                          "${picked.month.toString().padLeft(2, '0')}/"
                          "${picked.year}";
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _input(
            "Codice fiscale",
            controller: codiceFiscaleController,
          ),
        ],
      ),
    );

  }
}

// =======================================================
// INDIRIZZO (NOME UNIVOCO)
// =======================================================
class _CardIndirizzoPrivato extends StatelessWidget {
  final TextEditingController indirizzoController;
  final TextEditingController capController;
  final TextEditingController cittaController;
  final TextEditingController provinciaController;
  final TextEditingController statoController;

  const _CardIndirizzoPrivato({
    required this.indirizzoController,
    required this.capController,
    required this.cittaController,
    required this.provinciaController,
    required this.statoController,
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: "Indirizzo",
      child: Column(
        children: [
          _input("Indirizzo", controller: indirizzoController),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _input(
                  "CAP",
                  controller: capController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _input(
                  "Città",
                  controller: cittaController,
                  readOnly: false,
                ),
              ),
            ],
          ),


          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _input(
                  "Provincia",
                  controller: provinciaController,
                  readOnly: true,
                  onTap: () => mostraSelettoreProvincia(context, provinciaController),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _input(
                  "Stato",
                  controller: statoController,
                  readOnly: true,
                  onTap: () => mostraSelettoreStato(context, statoController),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// =======================================================
// CONTATTI
// =======================================================
class _CardContattiPrivato extends StatelessWidget {
  final TextEditingController telefonoController;
  final TextEditingController emailController;

  const _CardContattiPrivato({
    required this.telefonoController,
    required this.emailController,
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: "Contatti",
      child: Row(
        children: [
          Expanded(child: _input("Telefono", controller: telefonoController)),
          const SizedBox(width: 12),
          Expanded(child: _input("E-mail", controller: emailController)),
        ],
      ),
    );
  }
}

// =======================================================
// CAMPI
// =======================================================
Widget _input(
    String label, {
      TextEditingController? controller,
      IconData? icon,
      bool readOnly = false,
      VoidCallback? onTap,
    }) {
  return Builder(
    builder: (context) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      return TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          filled: true,
          fillColor: isDark
              ? Colors.black.withOpacity(0.25)
              : theme.colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      );
    },
  );
}






// =======================================================
// CARD BASE
// =======================================================
class _FormCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _FormCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.6)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.06))
            : null,
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}





class _ListaSelezione extends StatefulWidget {
  final String titolo;
  final List<String> elementi;
  final String? selezionata;

  const _ListaSelezione({
    required this.titolo,
    required this.elementi, this.selezionata,
  });

  @override
  State<_ListaSelezione> createState() => _ListaSelezioneState();
}

class _ListaSelezioneState extends State<_ListaSelezione> {
  String? value;

  @override
  void initState() {
    super.initState();
    value = widget.selezionata;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            widget.titolo,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            children: widget.elementi.map((e) {
              return RadioListTile<String>(
                title: Text(e),
                value: e,
                groupValue: value,
                onChanged: (v) => setState(() => value = v),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ANNULLA"),
              ),
              const Spacer(),
              FilledButton(
                onPressed: value == null
                    ? null
                    : () => Navigator.pop(context, value),
                child: const Text("OK"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}



