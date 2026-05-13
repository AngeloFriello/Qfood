import 'package:dashboard/Global.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDB {
  static Database? _db;

  static Future<Database> instance() async {
    writeLogOnFile("entro instanza LocalDb login",'....', trace: StackTrace.current);
    if (_db != null) return _db!;
      _db = await _initDB().catchError((err) =>  writeLogOnFile("catchError initDB login", err.toString(), trace: StackTrace.current));
      return _db!;
    }

  static bool get hasInstance => _db != null;

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  static Future<Database> _initDB() async {
    
    final path = join(await getDatabasesPath(), "qfood_pos.db");
    writeLogOnFile("Database path", path);

    if (kDebugMode) {
      debugPrint('DB Path: ${await getDatabasesPath()}');
      debugPrint('DB File: ${join(await getDatabasesPath(), 'tuo_database.db')}');
    }
    return await openDatabase(
      path,
      version: 1, // VERSIONE MIGLIORATA (nuova)
      onCreate: (db, _) async {
        writeLogOnFile("Database creation", path);
        debugPrint("📌 Creo DB locale...");


        await db.execute("""
          CREATE TABLE IF NOT EXISTS movimenti_cassa (
            id                        INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid_movimento            TEXT    NOT NULL,
            uuid_turno                TEXT    NOT NULL,
            id_operatore              INTEGER NOT NULL,
            data_ora_creazione        TEXT    NOT NULL,

            tipo_movimento            TEXT    NOT NULL,   -- 'entrata' | 'uscita'
            categoria                 TEXT    NOT NULL,   -- es. 'pagamento_fornitore', 'versamento_banca', ...

            descrizione               TEXT,
            importo                   REAL    NOT NULL,   -- importo > 0, direzione data da tipo_movimento
            metodo_pagamento          TEXT    NOT NULL,   -- 'contanti', 'elettronico', 'assegno', 'tickets', ...

            contropartita_nome        TEXT,
            contropartita_riferimento TEXT,
            provenienza               TEXT,
            note                      TEXT,

            device_id                 TEXT,
            sincronizzato_server      INTEGER NOT NULL DEFAULT 0,
            deleted                   INTEGER NOT NULL DEFAULT 0
          );
          """).catchError((err) => {
            writeLogOnFile("Database turno_movimenti_cassa table create", path, trace: StackTrace.current),
            debugPrint(err.toString())
          });

        // =============================================
        //  REPORT TURNO LOCALE
        // =============================================

        await db.execute('''
          CREATE TABLE IF NOT EXISTS electronic_payments (
            id                          INTEGER PRIMARY KEY AUTOINCREMENT,
            idDocument                  INTEGER NOT NULL,
            posType                     TEXT    NOT NULL,
            amount                      REAL    NOT NULL,
            payment_identifier          TEXT,
            data_device                 TEXT,
            created_date                TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
            refund                      INTEGER DEFAULT 0
          );
        ''');



// =============================================
        //  REPORT TURNO LOCALE
        // =============================================

        await db.execute('''
          CREATE TABLE IF NOT EXISTS turno_lavoro (
            id                          INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid_turno                  TEXT NOT NULL,
            nome_turno                  TEXT NOT NULL,
            id_operatore_apertura       INTEGER NOT NULL,
            id_operatore_loggato        INTEGER NOT NULL,
            fondo_cassa_iniziale        REAL,
            fondo_cassa_finale          REAL,
            fondo_cassa_trovato         REAL,
            data_ora_creazione          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
            tipo_documento              TEXT,
            totale_documento            REAL,
            chiusura_cassa              TEXT,
            turno_chiuso                INTEGER NOT NULL DEFAULT 0,
            sconto                      REAL,
            provenienza                 TEXT,
            amount_food                 REAL,
            amount_beverage             REAL,
            amount_altro                REAL,
            contanti                    REAL NOT NULL DEFAULT 0,
            elettronico                 REAL NOT NULL DEFAULT 0,
            tickets                     REAL NOT NULL DEFAULT 0,
            assegno                     REAL NOT NULL DEFAULT 0
          );
        ''');

        // =============================================
        //  REPORT LOCALE
        // =============================================

        await db.execute('''
          CREATE TABLE IF NOT EXISTS riepilogo_registro_sale (
              id          INTEGER PRIMARY KEY AUTOINCREMENT,
              data        TEXT NOT NULL,
              provenienza TEXT NOT NULL,
              tipo        TEXT NOT NULL,
              quantita    INTEGER NOT NULL DEFAULT 0,
              valore      REAL NOT NULL DEFAULT 0.0
            )
        ''');

        // =============================================
        //  POS
        // =============================================

        await db.execute('''
          CREATE TABLE pos (
              id              TEXT PRIMARY KEY,
              title           TEXT NOT NULL,
              idTerminalDojo  TEXT,
              type            TEXT,
              ipAddress       TEXT,
              port            INTEGER,
              idTerminal      TEXT,
              ecrTerminal     TEXT,
              terminalBytes   TEXT,
              useLegacy       INTEGER
            ); 
        ''');

         // =============================================
        //  Logs
        // =============================================

        await db.execute('''
          CREATE TABLE logs (
              id               INTEGER PRIMARY KEY AUTOINCREMENT,
              sendToBackOffice INTEGER,
              element          TEXT,
              action           TEXT,
              info             TEXT,
              device           TEXT,
              store            TEXT,
              operator         TEXT
            ); 
        ''');


        
        
        // =============================================
        //  STAMPANTI RIFERIMENTO PER ARTICOLI
        // =============================================

        await db.execute('''
          CREATE TABLE articlePrinter (
              idArticle       INTEGER PRIMARY KEY,
              printersBench   TEXT NOT NULL,
              printersRoom    TEXT NOT NULL,
              printersSummary TEXT NOT NULL
            );
        ''');

        // =============================================
        //  dispositivi
        // =============================================
        await db.execute('''
          CREATE TABLE devices (
              id INTEGER PRIMARY KEY,
              title TEXT NOT NULL,
              server TEXT
            );
        ''');
        
        // =============================================
        //  CARRELLI SOSPESI
        // =============================================
        await db.execute('''
          CREATE TABLE cartsSuspended (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              products TEXT,
              note TEXT,
              customer TEXT,
              createAt TEXT,
              total   TEXT
            );
        ''');


        // =============================================
        //  TAVOLI
        // =============================================
        await db.execute('''
          CREATE TABLE tables (
              id INTEGER PRIMARY KEY,
              title TEXT NOT NULL,
              positionX INTEGER NOT NULL,
              positionY INTEGER NOT NULL,
              idRoom INTEGER NOT NULL,
              cover INTEGER NOT NULL,
              enabled INTEGER NOT NULL,
              status TEXT,
              dateStartTable TEXT,
              idOperatorOpenTable INTEGER,
              products     TEXT,
              idCustomer   INTEGER,
              joinedTables TEXT,
              note         TEXT,
              blocked      INTEGER,
              lastExit INTEGER NOT NULL,
              idListPrice INTEGER,
              coversInTable INTEGER,
              idJoinedParent INTEGER
            );
        ''');

        
        // =============================================
        //  SALE
        // =============================================
        await db.execute('''
          CREATE TABLE rooms (
            id INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            service TEXT,
            visibleForWaiter INTEGER,
            indicateCovers INTEGER,
            mandatoryCover INTEGER,
            automaticService INTEGER,
            indicatePriceList INTEGER,
            idPriceList INTEGER,
            idVatRate INTEGER,
            idDevice INTEGER,
            enabled INTEGER
          )
        ''');


        // =============================================
        //  ordini
        // =============================================
        await db.execute('''CREATE TABLE orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nomeCliente TEXT,
          paid INTEGER DEFAULT 0,
          cliente TEXT,
          tipo TEXT NOT NULL,
          stato TEXT NOT NULL,
          data INTEGER NOT NULL,
          articles TEXT NOT NULL,
          indirizzo TEXT,
          telefono TEXT,
          note TEXT,
          callerPager Text,
          idRaider INTEGER,
          change   REAL,
          receiptPrinted INTEGER DEFAULT 0,
          createAt   INTEGER NOT NULL,
          lastUpdate INTEGER NOT NULL
        )''');

        // =============================================
        //  Documenti
        // =============================================

        await db.execute('''
          CREATE TABLE IF NOT EXISTS documents (
            id   INTEGER PRIMARY KEY AUTOINCREMENT,
            idReal INTEGER,
            assignedDocumentNumber INTEGER,
            title TEXT NOT NULL,
            realDate TEXT NOT NULL,
            jobDate TEXT NOT NULL,
            documentRtNumber TEXT,
            documentRtCloseNumber TEXT,
            amount REAL NOT NULL,
            amountTaxable REAL NOT NULL,
            amountTax REAL NOT NULL,
            amountRt REAL NOT NULL,
            receiptRounding REAL NOT NULL,
            tips REAL,
            remainder REAL NOT NULL,
            platform TEXT NOT NULL,
            printed INTEGER NOT NULL,
            printedAt TEXT,
            idDevice INTEGER NOT NULL,
            idOperator INTEGER NOT NULL,
            idCustomer INTEGER,
            lines TEXT NOT NULL,     -- JSON delle Line[]
            payments TEXT NOT NULL,  -- JSON dei Payment[]
            footDiscount REAL,
            idRateFootDiscount INTEGER,
            overrideMovementType TEXT,
            idDocumentReference INTEGER,
            copyCart        TEXT,
            idTable         INTEGER,
            deletedBy       TEXT,
            deleteNumber    TEXT,
            discountReason  TEXT,
            deliveryService TEXT,
            uuid_riga_turno TEXT,
            invoice_paid    INTEGER DEFAULT 0,
            credit_note_exclude_total_report INTEGER DEFAULT 0
          )
        ''').catchError((err)=> {
            writeLogOnFile("Database documents table create", path, trace: StackTrace.current),
            debugPrint(err.toString())
          });


        // =============================================
        //  CATEGORIES
        // =============================================

        await db.execute("""
            CREATE TABLE IF NOT EXISTS categories (
              id INTEGER PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT,
              color TEXT,
              position INTEGER,
              productionValue TEXT,
              idProductionCenter INTEGER,
              availableInPos INTEGER,
              endMeal INTEGER,
              alwaysFirstCourse INTEGER,
              promotional INTEGER,
              promotionalDiscount TEXT,
              printGroup TEXT,
              fiscalGroup TEXT,
              tipology TEXT,
              idManagementUnit INTEGER,
              idParentCategory INTEGER,
              enabled INTEGER DEFAULT 1,
              trashed INTEGER DEFAULT 0,
              lastSync TEXT
            );
        """).catchError((err)=> {
            writeLogOnFile("Database category table create", path, trace: StackTrace.current),
            debugPrint(err.toString())
          });

        // =============================================
        // VARIANTI ABBINATE ALLE CATEGORIE ok
        // =============================================

        await db.execute("""
            CREATE TABLE IF NOT EXISTS categoriesVariations (
              idCategory INTEGER,
              idVariation INTEGER
            );
        """).catchError((err)=> {
            writeLogOnFile("Database categoriesVariations table create", path, trace: StackTrace.current),
            debugPrint(err.toString())
          });

        // =============================================
        // STAMPANTI ABBINATE ALLE CATEGORIE ok
        // =============================================

        await db.execute("""
            CREATE TABLE IF NOT EXISTS categoriesStoreDepartmentProduction (
              idCategory INTEGER,
              idDepartmentProduction INTEGER,
              printFor TEXT
            );
        """).catchError((err)=> {
            writeLogOnFile("Database categoriesStoreDepartmentProduction table create", path, trace: StackTrace.current),
            debugPrint(err.toString())
          });

        // =============================================
        // REPARTI IVA ok vatDepartments
        // =============================================

        await db.execute("""
            CREATE TABLE IF NOT EXISTS vatDepartments (
              id INTEGER PRIMARY KEY,
              title TEXT,
              valueRate TEXT,
              idRate INTEGER,
              departmentNumber INTEGER,
              titleRate TEXT,
              nature TEXT
            );
        """).catchError((err)=> {
            writeLogOnFile("Database vatDepartments table create", path, trace: StackTrace.current),
            debugPrint(err.toString())
          });
          
        // =============================================
        // CLIENTI
        // =============================================

        await db.execute("""
            CREATE TABLE IF NOT EXISTS customers (
              id INTEGER PRIMARY KEY,
              code TEXT,
              title TEXT,
              denominationType TEXT,
              businessType TEXT,
              idCustomerGroup INTEGER,
              discountPercentage TEXT,
              mandatorySdiPec TEXT,
              generic INTEGER,
              promotional INTEGER,
              autocosume INTEGER,
              personalFirstname TEXT,
              personalLastname TEXT,
              personalFiscalCode TEXT,
              personalAddress TEXT,
              personalCity TEXT,
              personalZipCode TEXT,
              personalProvince TEXT,
              personalCountry TEXT,
              personalPhone TEXT,
              personalFax TEXT,
              personalEmail TEXT,
              businessName TEXT,
              businessVatNumber TEXT,
              businessFiscalCode TEXT,
              businessAddress TEXT,
              businessZipCode TEXT,
              businessCity TEXT,
              businessProvince TEXT,
              businessCountry TEXT,
              businessPhone TEXT,
              businessFax TEXT,
              businessEmail TEXT,
              businessPaymentMethod TEXT,
              businessPaymentCondition TEXT,
              businessSdiCode TEXT,
              businessPec TEXT,
              businessAdministrativeReference TEXT,
              businessGetPurchaseOrderData INTEGER,
              enabled INTEGER,
              trashed INTEGER,
              lastSync TEXT
            );
        """).catchError((err)=> {
            writeLogOnFile("Database CLIENTI table create", path, trace: StackTrace.current),
            debugPrint(err.toString())
          });

        // =============================================
        //  ARTICLES ok
        // =============================================
        await db.execute("""
          CREATE TABLE IF NOT EXISTS articles (
            id INTEGER PRIMARY KEY,
            articleType TEXT NOT NULL,
            code TEXT NOT NULL,
            title TEXT NOT NULL,
            posTitle TEXT,
            shortDescription TEXT,
            longDescription TEXT,
            preferred INTEGER DEFAULT 0,
            position INTEGER,
            availableForScale INTEGER DEFAULT 0,
            scalePlus TEXT DEFAULT "0.0",
            scaleType TEXT,
            variationType TEXT,
            variationPricePercentagePlus  TEXT DEFAULT "0.0",
            variationPricePercentageMinus TEXT DEFAULT "0.0",
            trashed INTEGER DEFAULT 0,
            enabled INTEGER DEFAULT 1,
            availableForPos INTEGER DEFAULT 0,
            lastSync TEXT,
            generic INTEGER,
            tipologies TEXT
          );
        """).catchError((err)=> {
            writeLogOnFile("Database articles table create", path, trace: StackTrace.current),
            debugPrint(err.toString())
          });

        // =============================================
        //  CATEGORIE/ARTICOLI articlesCategories ok
        // =============================================
        await db.execute("""
          CREATE TABLE IF NOT EXISTS articlesCategories (
            idCategory INTEGER,
            idArticle INTEGER
          );
        """).catchError((err)=> {
            debugPrint(err.toString())
          });

        // =============================================
        //  ARTICOLI VERSO LE VARIANTI DELLE CATEGORIE articlesVariationsCategories
        // =============================================
        await db.execute("""
            CREATE TABLE IF NOT EXISTS articlesVariationsCategories (
              idCategory INTEGER,
              idArticle INTEGER
            );
          """).catchError((err)=> {
            writeLogOnFile("Database articlesVariationsCategories table create", path, trace: StackTrace.current),
            debugPrint(err.toString())
          });

        // =============================================
        //  ARTICOLI VERSO LE VARIANTI "joinType" = 'default' | 'mandatory' | 'excluded' 
        // =============================================
        await db.execute("""
          CREATE TABLE IF NOT EXISTS articlesVariations (
            idVariation INTEGER,
            idArticle   INTEGER,
            joinType    TEXT          
          );
        """).catchError((err)=> {
            writeLogOnFile("Database articlesVariations table create", path, trace: StackTrace.current),
            debugPrint(err.toString())
          });

        // =============================================
        //  LISTINI DISPONIBILI
        // =============================================
        await db.execute("""
          CREATE TABLE IF NOT EXISTS listPrice (
            id INTEGER PRIMARY KEY,
            title         TEXT,
            counterpart   TEXT,
            enabled       INTEGER,
            trashed       INTEGER,
            lastSync      TEXT          
          );
        """).catchError((err)=> {
            writeLogOnFile("Database listPrice table create", path, trace: StackTrace.current),
            debugPrint(err.toString())
          });

        // =============================================
        //  LISTINI PREZZI articlesPrices ok
        // =============================================
        await db.execute("""
            CREATE TABLE IF NOT EXISTS articlesPrices (
              idArticle INTEGER NOT NULL,
              idPriceList INTEGER NOT NULL,
              price TEXT,
              discountPercentage TEXT,
              rateValue TEXT,
              idVatRate INTEGER,
              validFromDate TEXT,
              validToDate TEXT,
              validHourDayStart TEXT,
              validHourDayEnd TEXT,
              weekDay TEXT,
              validityPriceForQuantity TEXT,
              maximumSellableQuantity TEXT,
              preferred INTEGER DEFAULT 0
            );
          """).catchError((err)=> {
            writeLogOnFile("Database articlesPrices table create", path, trace: StackTrace.current),
            debugPrint(err.toString()) 
          });


        // =============================================
        //  PAYMENTS (aggiunto 'type', compatibile col tuo insert)
        // =============================================
        await db.execute("""
          CREATE TABLE IF NOT EXISTS payments (
            id INTEGER PRIMARY KEY,
            title TEXT,
            cashPayment INTEGER,
            revenueAgencyType TEXT,
            usedForPos INTEGER,
            tend INTEGER,
            subtend INTEGER,
            trashed INTEGER,
            enabled INTEGER,
            lastSync  TEXT
          );
        """).catchError((err)=> {
            writeLogOnFile("Database payments table create", path, trace: StackTrace.current),
            debugPrint(err.toString())
          });

        // =============================================
        //  ATICOLO ALLERGENI    //IN MODELLI/ENUMS trovi l'enum dei vari allergeni
        // =============================================
        await db.execute("""
          CREATE TABLE IF NOT EXISTS articlesAllergens (
            idArticle INTEGER,
            allergen TEXT
          );
        """).catchError((err)=> {
            writeLogOnFile("Database articlesAllergens table create", path, trace: StackTrace.current),
            debugPrint(err.toString())
          });

        // =============================================
        //  VAT RATES
        // =============================================
        await db.execute("""
          CREATE TABLE IF NOT EXISTS vatRates (
            id INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            value TEXT,
            nature TEXT,
            departmentNumber INTEGER,
            trashed INTEGER,
            enabled INTEGER,
            lastSync TEXT
          );
          """).catchError((err)=> {
            writeLogOnFile("Database vatRates table create", path, trace: StackTrace.current),
            debugPrint(err.toString())
          });
        

        // =============================================
        //  OPERATORS
        // =============================================
        await db.execute("""
        CREATE TABLE IF NOT EXISTS operators (   
          id INTEGER PRIMARY KEY,
          title TEXT NOT NULL,
          role TEXT NOT NULL,
          accessCode TEXT,
          firstname TEXT,
          lastname TEXT,
          email TEXT,
          phoneNumber TEXT,
          rider INTEGER,
          riderPercentage TEXT,
          fiscalClosure INTEGER,
          discountReason INTEGER,
          maximumDiscount TEXT,
          enableDiscount INTEGER,
          manageGeneric INTEGER,
          displayDailyReport INTEGER,
          increasePrice INTEGER,
          printAdvanceAccount INTEGER,
          printBill INTEGER,
          trashRoundDetails INTEGER,
          trashSendedArticle INTEGER,
          reasonTrashedSendedArticle INTEGER,
          cleanTable INTEGER,
          manageTableInAdvanceAccount INTEGER,
          requestAdvanceAccountFromWaiter INTEGER,
          trashNotSendedArticle INTEGER,
          displayAmountRoom INTEGER,
          displayTablePrice INTEGER,
          displayAmountTable INTEGER,
          coverDistinguishCategory INTEGER,
          cutCover INTEGER,
          changeWeightOnSendedArticle INTEGER,
          manageWeight INTEGER,
          manageManualExit INTEGER,
          engageTable INTEGER,
          joinTable INTEGER,
          closeTableNoPrint INTEGER,
          subdivideBill INTEGER,
          separateBill INTEGER,
          unlockTable INTEGER,
          resendCommand INTEGER,
          enableServicePercentage INTEGER,
          automaticCopyReceiptPosPayment INTEGER,
          cancelReceipt INTEGER,
          reasonCancelTable INTEGER,
          reasonCancelArticleNotSended INTEGER,
          displayCoverRoom INTEGER,
          manualDistinguishCover INTEGER,
          statusArticleNotSended INTEGER,
          splitTable INTEGER,
          moveArticleTable INTEGER,
          copyReceipt INTEGER,
          acWithdrawal INTEGER,
          acDeposit INTEGER,
          acChange INTEGER,
          acRefill INTEGER,
          acArchivingExceptCashFund INTEGER,
          acTotalArchiving INTEGER,
          smallProductName INTEGER,
          productNameSize TEXT,
          productSmallNameSize TEXT,
          rapidDiscountButtonPercentage TEXT,
          uiSide INTEGER,
          discountBenchTable INTEGER,
          extendedCart INTEGER,
          rapidButtonCash INTEGER,
          displayAmountLastSale INTEGER,
          rapidPriceListChangeButton INTEGER,
          displayProductReduced INTEGER,
          reducePrice INTEGER,
          useDarkMode INTEGER,
          printDefaultCommandFromBench INTEGER,
          displayBigCategory INTEGER,
          tableOpeningInCommand INTEGER,
          sendOrderNoExitTable INTEGER,
          valueWithoutSeparator INTEGER,
          paginatedArticle INTEGER,
          displayTableReduced INTEGER,
          displayUserTable INTEGER,
          paymentCheck INTEGER,
          paymentWireTransfer INTEGER,
          idPosGroup INTEGER,
          enabled INTEGER,
          trashed INTEGER,
          lastSync TEXT,
          trainingPin TEXT,
          magneticKeyCode TEXT,
          manageBill INTEGER,
          reworksSale  INTEGER,
          searchArticles  INTEGER
        );
        """).catchError((err)=> {
            writeLogOnFile("Database  operators create", path, trace: StackTrace.current),
            debugPrint(err.toString())
          });

          debugPrint("🎉 DB locale creato!");
      },

      // ==========================================================
      //  MIGRAZIONI SICURE — NON DISTRUGGONO DATI ESISTENTI
      // ==========================================================
      onUpgrade: (db, oldV, newV) async {
        debugPrint("🔄 MIGRAZIONE DATABASE oldV=$oldV → newV=$newV");
        if (oldV < 5) {
          

        }
      },
    );
  }

  // ============================================
  // GENERIC TABLE REPLACER (LOGICA INVARIATA)
  // ============================================
  static Future<void> replaceTable(
    String table,
    List<Map<String, Object?>> rows,
  ) async {
    final db = await instance();

    await db.transaction((txn) async {
      await txn.delete(table);
      for (final row in rows) {
        await txn.insert(
          table,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    debugPrint("💾 Tabella '$table' aggiornata: ${rows.length} records");
  }

  static Future<List<Map<String, dynamic>>> getAll(String table) async {
    final  db = await instance();
    return db.query(table);
  }

  static Future<List<Map<String, dynamic>>> query(String query) async {
    try{
      Database   db = await instance();
      return  db.rawQuery(query);
    }catch(err){
      writeLogOnFile("catchError query login", err.toString(), trace: StackTrace.current);
      return [];
    }
  }

    static Future<int> queryUpdate(String query) async {
      try{
        Database   db = await instance();
        return  db.rawUpdate(query);
      }catch(err){
        writeLogOnFile("catchError query login", err.toString(), trace: StackTrace.current);
        return 0;
      }
    }

}
