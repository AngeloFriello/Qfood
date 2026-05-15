# Regole di Coerenza — Progetto Qfood POS (dashboard)

Questo file definisce le convenzioni e i pattern architetturali del progetto. Deve essere rispettato in ogni aggiunta o modifica.

---

## 1. Identità del package

- **Nome package:** `dashboard`  
- **Tutti gli import** usano il prefisso `package:dashboard/…`  
- **SDK minimo:** Dart `^3.7.2`, Flutter stabile corrispondente  

---

## 2. Struttura delle cartelle `lib/`

```
lib/
├── main.dart                        # Entry point, bootstrap Provider tree
├── Global.dart                      # Variabili globali, GlobalKey, helpers SnackBar
├── api/                             # HTTP client (ApiClient, customer_api, helper_api)
├── app/
│   ├── router/                      # auto_route — AppRouter
│   ├── service/
│   │   ├── Service_Socket/          # WebSocket client/server, self-order polling
│   │   ├── service_locator.dart     # GetIt — registrazione singleton
│   │   ├── service_connection.dart
│   │   ├── service_log_pos.dart
│   │   ├── service_new_update.dart
│   │   ├── service_report.dart
│   │   ├── service_scheduler_document.dart
│   │   ├── service_transaction.dart
│   │   ├── theme_service*.dart
│   │   └── toast_service.dart
│   ├── theme/
│   │   ├── constants/               # AppConst, AppColor, store
│   │   ├── controllers/             # ThemeController
│   │   ├── models/                  # AdaptiveResponse, enums tema
│   │   ├── flex_theme_*.dart
│   │   ├── theme_data_*.dart
│   │   └── theme_values.dart
│   ├── utils/
│   │   ├── app_data_dir/
│   │   ├── app_scroll_behavior.dart
│   │   └── same_types.dart
│   └── view/
│       └── dashboard_app.dart       # MaterialApp root (StatefulWidget + WidgetsBindingObserver)
├── casse_automatiche/               # Integrazioni hardware (BS, Cashmatic, CPI, VNE)
│   ├── bs/ cashmatic/ CPI/ vne/
│   └── settings_menu_automatic_checkout.dart
├── config/
│   ├── costanti.dart                # URL base, API key, GUID costanti
│   ├── responsive.dart              # Classe Responsive (breakpoint: mobile<800, tablet<1200, desktop>=1200)
│   └── tema_app.dart                # TemaApp — colori brand statici
├── impostazioni/
│   ├── home_vista.dart
│   ├── reso_merce_vista.dart
│   ├── report_avanzato_vista.dart
│   └── impostazioni/                # Sotto-pagine: debug, distinta, download, logs, tools…
├── modelli/                         # Modelli dati puri (ChangeNotifier NON usato qui)
│   ├── article.dart  articleInCart.dart  articleWithPriceList.dart
│   ├── category.dart  customer.dart  department.dart  device.dart
│   ├── document.dart  enums.dart  listPrice.dart  movimentiCassa.dart
│   ├── operator.dart  payment.dart  pos.dart  PosProt_17.dart
│   ├── printer.dart  room.dart  settingPos.dart  table.dart  vatRate.dart
│   └── …
├── pagamenti_elettronici/
│   └── pagamenti.dart
├── printers/
│   ├── events/ fiscal/ not_fiscal/
│   └── utilis.dart
├── report_chiusura/
│   ├── PrintReport.dart  ReportChiusura.dart  ReportList.dart
├── state/                           # Controller Provider globali (ChangeNotifier)
│   ├── app_session_controller.dart
│   ├── banco_state.dart
│   ├── controller_carrello.dart
│   ├── controller_impostazioni.dart
│   └── product_search_controller.dart
├── ui/
│   ├── screen/                      # Una cartella per feature/schermata
│   │   ├── checkout/
│   │   ├── documents/
│   │   ├── login/
│   │   ├── login_opertore/
│   │   ├── ordini/
│   │   │   ├── models/              # modelli locali alla feature
│   │   │   ├── state/               # controller locali alla feature
│   │   │   └── ux/                  # pages/, widgets/, dialog/
│   │   ├── prenotazioni/
│   │   ├── scontrino/
│   │   ├── sincronizzazioni/
│   │   │   ├── articoli/
│   │   │   ├── databasesql_lite/    # LocalDB (singleton sqflite)
│   │   │   └── operatori/
│   │   ├── store_e_dispositivi/
│   │   └── tavoli/
│   │       ├── filtri/ header_footer/ widgets/
│   │       └── operativita/
│   │           ├── widgets/ widgets_tavolo/
│   └── widget/                      # Widget riutilizzabili cross-feature
│       ├── carrello/
│       ├── categorie_e_prodotti/
│       ├── header_footer/
│       ├── selector/
│       ├── tastiera_qwerty/
│       ├── tastierino/
│       └── scheda_tavolo.dart
├── utility/
│   ├── network.dart
│   └── PosFetch.dart
└── varianti/
    ├── models/                      # nota_predefinita.dart, variante_tipo.dart
    ├── state/                       # variants_controller.dart
    └── ui/                          # varianti_dialog.dart, varianti_libere_section.dart
```

---

## 3. State Management

| Scope | Tool | Dove |
|---|---|---|
| **Globale app** | `Provider` (ChangeNotifier) | `lib/state/` |
| **Feature locale** | `Provider` (ChangeNotifier) | `lib/ui/screen/<feature>/state/` oppure `lib/<modulo>/state/` |
| **Servizi singleton** | `GetIt` (serviceLocator) | registrati in `app/service/service_locator.dart` |
| **Tema** | `ThemeController` via GetIt | `app/theme/controllers/` |
| **Persistenza leggera** | `shared_preferences` | accesso diretto nelle classi che ne hanno bisogno |
| **DB locale** | `sqflite` / `sqflite_common_ffi` | `LocalDB` singleton in `ui/screen/sincronizzazioni/databasesql_lite/` |
| **Persistenza tema** | `hive_ce` | `ThemeServiceHive` |

**Regole:**
- I controller estendono sempre `ChangeNotifier`.
- I modelli in `lib/modelli/` sono POJO puri (no `ChangeNotifier`); contengono `fromJson`, `toJson`/`toMap` e metodi di persistenza DB se necessari.
- Non usare `Riverpod`, `Bloc` o altri package di state management.
- Non aggiungere singleton in `GetIt` se il controller è già fornito tramite `Provider`.

---

## 4. Navigazione

- Il router principale usa **`auto_route`** (`AppRouter` in `app/router/app_router.dart`).
- Il `navigatorKey` globale è definito in `Global.dart`.
- Le schermate registrate in `AppRouter` terminano con `Screen` o `Page` (vengono rinominate in `Route` automaticamente).
- La navigazione intra-feature usa `Navigator` standard oppure push diretto tramite `appRouter`.

---

## 5. Convenzioni di naming

| Elemento | Convenzione | Esempio |
|---|---|---|
| File Dart | `snake_case` | `ordini_list_controller.dart` |
| File eccezioni (eredità) | PascalCase se già esistenti | `ControllerModuloPagamenti.dart` (non rinominare) |
| Classi | `PascalCase` | `OrdiniListController` |
| Variabili / metodi | `camelCase` | `filtroTipo`, `setGiorno()` |
| Costanti | `camelCase` o `UPPER_SNAKE_CASE` | `apiBaseUrl`, `APIKEYRESELLER` |
| Cartelle feature | `snake_case` italiano | `login_opertore/`, `store_e_dispositivi/` |
| Controller | suffisso `Controller` | `VariantsController`, `CarrelloController` |
| Vista/pagina | suffisso `_vista`, `_page` o `_screen` | `tavoli_vista.dart`, `login_screen.dart` |
| Widget riutilizzabile | suffisso `_widget` o nome descrittivo | `footer_navbar.dart` |

---

## 6. Lingua

- **Codice sorgente:** commenti, nomi variabili e nomi metodi in **italiano** (es. `carrello`, `ordini`, `tavoli`).  
- **Stringhe visibili all'utente:** sempre tramite `easy_localization` — file JSON in `assets/translations/` (lingue: `it-IT`, `en`, `es`, `ar`, `bn`, `hi`, `zh`).  
- Non inserire stringhe hardcoded visibili all'utente nel codice.

---

## 7. HTTP e API

- Tutti le chiamate REST passano da `ApiClient` (`lib/api/api_client.dart`).
- L'URL base è `apiBaseUrl` definita in `lib/config/costanti.dart`.
- Le API key vengono risolte tramite `apiKeyForInstance(istanza)` — non duplicare chiavi nel codice.
- Le chiamate sono `static` e ritornano `Future<http.Response>`.
- Il parsing avviene nel chiamante o in metodi statici del modello (`fromJson`).

---

## 8. Database locale (SQLite)

- Accesso tramite `LocalDB.instance()` (singleton lazy in `databasesql_lite/local_db.dart`).
- Tutte le tabelle vengono create in `_initDB()` con `CREATE TABLE IF NOT EXISTS`.
- Le migrazioni usano il parametro `version` e `onUpgrade`.
- I modelli espongono metodi statici per query: `getAll()`, `getById()`, `insert()`, `update()`, `delete()`.

---

## 9. Temi e stile

- I colori brand sono in `lib/config/tema_app.dart` (`TemaApp.verdeBrand`, `TemaApp.grigioBrand`, ecc.).
- Il sistema di tema usa **FlexColorScheme** — non creare `ThemeData` manuali.
- Dark/Light mode gestita da `ThemeController` (persisto con `ThemeServiceHive`).
- Font: `google_fonts` con `allowRuntimeFetching = false`; i font usati devono essere presenti in `assets/google_fonts/`.
- Icone: preferire `lucide_icons`; fallback su `Icons` di Material.
- SVG: caricare tramite `flutter_svg`.

---

## 10. Responsive

- Usare la classe `Responsive` in `lib/config/responsive.dart` per layout adattivi.
- Breakpoint: **mobile** < 800 px, **tablet** 800–1199 px, **desktop** ≥ 1200 px.
- L'app parte in **fullscreen** su Windows/Linux/macOS (impostato in `main.dart` tramite `window_manager`).

---

## 11. Pattern per nuove feature

Quando si aggiunge una feature significativa (es. nuova sezione del POS):

```
lib/ui/screen/<nome_feature>/
├── models/          # modelli dati locali alla feature (opzionale se usa modelli globali)
├── state/           # ChangeNotifier controller locali
└── ux/
    ├── pages/       # schermate principali (@RoutePage per auto_route)
    ├── widgets/     # widget interni alla feature
    └── dialog/      # dialog e bottom sheet
```

Per moduli autonomi (es. `varianti/`, `printers/`):
```
lib/<nome_modulo>/
├── models/
├── state/
└── ui/
```

---

## 12. Integrazione hardware (casse automatiche)

- Ogni marca di cassa ha la propria cartella in `lib/casse_automatiche/<marca>/`.
- Il protocollo di comunicazione è incapsulato all'interno della cartella della marca.
- La configurazione/UI di selezione è in `settings_menu_automatic_checkout.dart`.
- Non mescolare logica di casse diverse nella stessa classe.

---

## 13. WebSocket e real-time

- Il server WS è `service_ws_server.dart`; il client è `service_ws_client.dart`.
- Il self-order polling è `service_self_order_polling.dart`.
- Tutti nella cartella `app/service/Service_Socket/`.

---

## 14. Stampa fiscale

- Stampanti fiscali: `lib/printers/fiscal/`
- Stampanti non fiscali: `lib/printers/not_fiscal/`
- Utility di stampa: `lib/printers/utilis.dart`
- Report di chiusura: `lib/report_chiusura/`

---

## 15. Variabili globali (`Global.dart`)

`Global.dart` contiene variabili di stato condivise a livello applicativo che non sono gestibili con Provider (accesso fuori dall'albero widget):
- `posGlobal`, `posSelected`, `deviceCurrent`
- `operatorLogged`, `tableByServerForClient`, `listsPrice`, `allArticles`
- `navigatorKey`, `messengerKey`, `tastierinoKey`

Aggiungere qui **solo** variabili che richiedono accesso globale statico. Per tutto il resto usare Provider.

---

## 16. Backup e file temporanei

- I file `*_backup*.dart` presenti in `casse_automatiche/` sono storici — **non modificarli** e non crearne di nuovi.
- Non committare file `.dart` con suffisso di data nel nome.
