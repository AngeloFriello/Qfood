import 'package:flutter/material.dart';
import 'prenotazione_channel.dart';
import 'prenotazione_stato.dart';

// MODELLO USATO OVUNQUE (UI + DB)
class Prenotazione {
  final int id;

  /// Data (yyyy-mm-dd)
  final DateTime data;

  /// Orario (hh:mm)
  final TimeOfDay orario;

  /// Durata
  final Duration durata;

  /// Coperti
  final int pax;

  /// Cliente (DB)
  final int clienteId;
  final String clienteNome;
  final String? telefono;
  final String? email;
  final String? note;


  /// Stato / canale
  final PrenotazioneStato stato;
  final PrenotazioneChannel channel;

  /// Tavoli
  final List<int> tavoli;

  /// Filtri
  final String sala;
  final String turno;


  // DURATA E TEMPI USATI DALLA UI
  String timeRangeLabel(BuildContext context) {
    final start = TimeOfDay.fromDateTime(startDateTime).format(context);
    final end = TimeOfDay.fromDateTime(endDateTime).format(context);
    return '$start – $end';
  }

  String durataLabel() {
    final h = durata.inHours;
    final m = durata.inMinutes % 60;

    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }


  const Prenotazione({
    required this.id,
    required this.data,
    required this.orario,
    required this.durata,
    required this.pax,
    required this.clienteId,
    required this.clienteNome,
    this.telefono,
    this.email,
    this.note,
    required this.stato,
    required this.channel,
    this.tavoli = const [],
    this.sala = 'TAVOLI',
    this.turno = 'TUTTI',
  });

  // ==========================
  // TIME
  // ==========================
  DateTime get startDateTime => DateTime(
    data.year,
    data.month,
    data.day,
    orario.hour,
    orario.minute,
  );

  DateTime get endDateTime => startDateTime.add(durata);
  DateTime get end => endDateTime;

  bool get isScaduta => DateTime.now().isAfter(endDateTime);

  // ==========================
  // COPY
  // ==========================
  Prenotazione copyWith({
    DateTime? data,
    TimeOfDay? orario,
    Duration? durata,
    int? pax,
    int? clienteId,
    String? clienteNome,
    String? telefono,
    String? email,
    PrenotazioneStato? stato,
    PrenotazioneChannel? channel,
    List<int>? tavoli,
    String? sala,
    String? turno,
  }) {
    return Prenotazione(
      id: id,
      data: data ?? this.data,
      orario: orario ?? this.orario,
      durata: durata ?? this.durata,
      pax: pax ?? this.pax,
      clienteId: clienteId ?? this.clienteId,
      clienteNome: clienteNome ?? this.clienteNome,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      stato: stato ?? this.stato,
      channel: channel ?? this.channel,
      tavoli: tavoli ?? this.tavoli,
      sala: sala ?? this.sala,
      turno: turno ?? this.turno,
    );
  }
}
