/*
DDL del database
CREATE TABLE
CREATE INDEX
 */

class Migrations {

  // CLIENTI
  static const createClienti = '''
  CREATE TABLE IF NOT EXISTS clienti (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    telefono TEXT,
    email TEXT,
    blacklist INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER
  );
  ''';

  // PRENOTAZIONI
  static const createPrenotazioni = '''
  CREATE TABLE IF NOT EXISTS prenotazioni (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    -- DATE
    data INTEGER NOT NULL,
    durata INTEGER NOT NULL,
    scadenza INTEGER,

    -- INFO
    pax INTEGER NOT NULL,
    stato TEXT NOT NULL,
    canale TEXT NOT NULL,
    note TEXT,

    -- CLIENTE
    cliente_id INTEGER,
    cliente_nome TEXT NOT NULL,
    cliente_telefono TEXT,
    cliente_email TEXT,

    -- SYNC API
    remote_id INTEGER,
    synced INTEGER DEFAULT 0,
    metadata TEXT,

    -- AUDIT
    created_at INTEGER NOT NULL,
    updated_at INTEGER,

    FOREIGN KEY (cliente_id)
      REFERENCES clienti(id)
      ON DELETE SET NULL
  );
  ''';

  // TAVOLI
  static const createTavoli = '''
  CREATE TABLE IF NOT EXISTS tavoli (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    capienza INTEGER NOT NULL,
    stato TEXT,
    created_at INTEGER
  );
  ''';

  // PRENOTAZIONI ↔ TAVOLI
  static const createPrenotazioniTavoli = '''
  CREATE TABLE IF NOT EXISTS prenotazioni_tavoli (
    prenotazione_id INTEGER NOT NULL,
    tavolo_id INTEGER NOT NULL,

    PRIMARY KEY (prenotazione_id, tavolo_id),

    FOREIGN KEY (prenotazione_id)
      REFERENCES prenotazioni(id)
      ON DELETE CASCADE,

    FOREIGN KEY (tavolo_id)
      REFERENCES tavoli(id)
      ON DELETE CASCADE
  );
  ''';

  // INDICI
  static const createIndexes = '''
  CREATE INDEX IF NOT EXISTS idx_prenotazioni_data
    ON prenotazioni(data);

  CREATE INDEX IF NOT EXISTS idx_prenotazioni_cliente
    ON prenotazioni(cliente_id);

  CREATE INDEX IF NOT EXISTS idx_prenotazioni_synced
    ON prenotazioni(synced);
  ''';
}
